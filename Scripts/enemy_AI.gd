extends CharacterBody2D

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@export var player_path: NodePath # assign in the Inspector
@onready var player: Node2D = get_node_or_null(player_path)
@onready var projectile_scene: PackedScene = preload("res://NPCs/ProjectileGatlin.tscn")
@onready var sprite = $AnimatedSprite2D
@onready var gun = $GulilGun
@onready var barrel = $GulilGun/Node2D

@export var move_speed: float = 200.0
@export var wander_radius: float = 300.0
@export var wait_time: float = 1.0

@export var detection_range: float = 450.0
@export var desired_range: float = 300.0
@export var range_tolerance: float = 60.0

@export var shoot_interval: float = 0.20
@export var shoot_jitter: float = 0.08

var waiting := false
var in_combat := false
var time_since_shot := 0.0
var next_shot_at := 0.0

func _ready():
	gun.visible = false
	randomize()
	pick_new_destination()
	next_shot_at = shoot_interval + randf() * shoot_jitter

func _process(delta: float) -> void:
	if player and is_instance_valid(player):
		gun.look_at(player.global_position)
		gun.flip_h = rotation < -PI / 2 or rotation > PI / 2

	if in_combat == true:
		gun.visible = true
	else:
		gun.visible = false

func _physics_process(delta):
	if in_combat:
		_handle_combat(delta)
	else:
		_handle_wandering(delta)

	_detect_player()

func _detect_player():
	if player == null or !is_instance_valid(player):
		in_combat = false
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()
	var seen := _has_line_of_sight_to_player()

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

	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	return hit.has("collider") and hit["collider"] == player

func _handle_wandering(_delta):
	if waiting:
		return
	var next_point: Vector2 = agent.get_next_path_position()
	var direction: Vector2 = (next_point - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	_update_directional_animation()
	if agent.is_navigation_finished():
		_start_wait_timer()

func pick_new_destination():
	var random_offset := Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	var new_target := global_position + random_offset
	agent.set_target_position(new_target)

func _start_wait_timer():
	waiting = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(wait_time).timeout
	waiting = false
	pick_new_destination()

func _handle_combat(delta):
	if player == null or !is_instance_valid(player):
		in_combat = false
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()
	var facing: Vector2 = to_player.normalized()
	var min_range: float = max(0.0, desired_range - range_tolerance)
	var max_range: float = desired_range + range_tolerance
	var move_vec := Vector2.ZERO

	if distance < min_range:
		move_vec = (-facing) * move_speed
	elif distance <= max_range:
		var strafe := facing.orthogonal().rotated(randf_range(-0.35, 0.35)).normalized()
		move_vec = strafe * (move_speed * 0.7)
	else:
		var light_strafe := facing.orthogonal().rotated(randf_range(-0.25, 0.25)).normalized()
		move_vec = light_strafe * (move_speed * 0.35)

	velocity = move_vec
	move_and_slide()
	_update_directional_animation()

	time_since_shot += delta
	if time_since_shot >= next_shot_at and _has_line_of_sight_to_player():
		_shoot_projectile(facing)
		time_since_shot = 0.0
		next_shot_at = shoot_interval + randf() * shoot_jitter

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
