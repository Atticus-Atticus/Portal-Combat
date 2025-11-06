extends CharacterBody2D

@onready var agent: NavigationAgent2D = $NavigationAgent2D

@export var player_path: NodePath # assign in the Inspector
@onready var player: Node2D = get_node_or_null(player_path)
@onready var projectile_scene: PackedScene = preload("res://NPCs/ProjectileShotgun.tscn")
@onready var sprite = $AnimatedSprite2D
@onready var gun = $Shutgun
@onready var barrel = $Shutgun/Node2D

@export var move_speed: float = 200.0
@export var wander_radius: float = 300.0
@export var wait_time: float = 1.0

@export var detection_range: float = 500.0
@export var los_mask: int = -1

@export var close_range: float = 140.0
@export var burst_projectiles: int = 7
@export var burst_spread_deg: float = 28.0
@export var pellet_speed: float = 700.0
@export var burst_cooldown: float = 1.4
@export var retreat_duration: float = 0.8
@export var retreat_speed_mult: float = 1.2

var waiting := false
var in_combat := false
var burst_cd_left: float = 0.0
var retreat_left: float = 0.0

func _ready() -> void:
	gun.visible = false
	randomize()
	pick_new_destination()

func _process(delta: float) -> void:
	if player and is_instance_valid(player):
		gun.look_at(player.global_position)
		gun.flip_h = rotation < -PI / 2 or rotation > PI / 2

	if in_combat == true:
		gun.visible = true
	else:
		gun.visible = false

func _physics_process(delta: float) -> void:
	_ensure_player()

	if in_combat:
		_handle_combat(delta)
	else:
		_handle_wandering(delta)

	_detect_player()

	if burst_cd_left > 0.0:
		burst_cd_left = max(0.0, burst_cd_left - delta)
	if retreat_left > 0.0:
		retreat_left = max(0.0, retreat_left - delta)

func _ensure_player() -> void:
	if player != null and is_instance_valid(player):
		return
	if player_path != NodePath("") and has_node(player_path):
		player = get_node(player_path) as Node2D
		return
	var g := get_tree().get_first_node_in_group("player")
	if g and g is Node2D:
		player = g as Node2D

func _detect_player() -> void:
	if player == null or !is_instance_valid(player):
		in_combat = false
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()
	var seen: bool = _has_line_of_sight_to_player()

	if seen and distance <= detection_range:
		in_combat = true
	elif distance > detection_range * 1.5:
		in_combat = false

func _has_line_of_sight_to_player() -> bool:
	if player == null or !is_instance_valid(player):
		return false

	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = player.global_position
	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = los_mask

	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	return hit.has("collider") and hit["collider"] == player

func _handle_wandering(_delta: float) -> void:
	if waiting:
		return
	var next_point: Vector2 = agent.get_next_path_position()
	var direction: Vector2 = (next_point - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	_update_directional_animation()
	if agent.is_navigation_finished():
		_start_wait_timer()

func pick_new_destination() -> void:
	var random_offset := Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	var new_target := global_position + random_offset
	agent.set_target_position(new_target)

func _start_wait_timer() -> void:
	waiting = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(wait_time).timeout
	waiting = false
	pick_new_destination()

func _handle_combat(_delta: float) -> void:
	if player == null or !is_instance_valid(player):
		in_combat = false
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()
	var facing: Vector2 = to_player.normalized()

	if retreat_left > 0.0:
		var strafe: Vector2 = facing.orthogonal().rotated(randf_range(-0.25, 0.25)).normalized()
		var move_vec: Vector2 = (-facing * move_speed * retreat_speed_mult) + (strafe * move_speed * 0.3)
		velocity = move_vec
		move_and_slide()
		_update_directional_animation()
		return

	if (distance > close_range) or !_has_line_of_sight_to_player():
		agent.set_target_position(player.global_position)
		var next_point: Vector2 = agent.get_next_path_position()
		var advance: Vector2 = (next_point - global_position).normalized()
		velocity = advance * move_speed
		move_and_slide()
		_update_directional_animation()
		return

	if burst_cd_left <= 0.0:
		_shotgun_burst(facing)
		burst_cd_left = burst_cooldown
		retreat_left = retreat_duration
	else:
		var strafe2: Vector2 = facing.orthogonal().rotated(randf_range(-0.4, 0.4)).normalized()
		velocity = strafe2 * (move_speed * 0.8)
		move_and_slide()
		_update_directional_animation()

func _shotgun_burst(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var half_spread: float = burst_spread_deg * 0.5
	for i in burst_projectiles:
		var offset_deg: float = randf_range(-half_spread, half_spread)
		var shoot_dir: Vector2 = dir.rotated(deg_to_rad(offset_deg)).normalized()
		_shoot_projectile(shoot_dir)

func _shoot_projectile(dir: Vector2):
	var p := projectile_scene.instantiate()
	get_parent().add_child(p)
	if p is Node2D:
		var n2d := p as Node2D
		n2d.global_position = barrel.global_position
		n2d.rotation = dir.angle()
	if p.has_method("set"):
		p.set("velocity", dir * 500.0)
	await get_tree().create_timer(0.15).timeout

func _update_directional_animation() -> void:
	if velocity.length() < 1.0:
		sprite.play("Idle")
		return

	var dir := velocity.normalized()

	if abs(dir.x) > abs(dir.y):
		sprite.play("Side")
		sprite.flip_h = dir.x > 0
	else:
		if dir.y > 0:
			sprite.play("Front")
		else:
			sprite.play("Back")

func _death():
	#agent.queue_free()
	#gun.queue_free()
	sprite.play("Death")
	await get_tree().create_timer(2).timeout
	queue_free()
