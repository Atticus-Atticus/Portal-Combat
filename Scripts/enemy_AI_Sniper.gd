extends CharacterBody2D

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@export var player_path: NodePath # assign in the Inspector
@onready var player: Node2D = get_node_or_null(player_path)
@onready var projectile_scene: PackedScene = preload("res://NPCs/ProjectileCannon.tscn")
@onready var sprite = $AnimatedSprite2D
@onready var gun = $Cunnon
@onready var barrel = $Cunnon/Node2D

@export var move_speed: float = 200.0
@export var wander_radius: float = 300.0
@export var wait_time: float = 1.0

@export var detection_range: float = 2000.0
@export var sniper_interval: float = 2.0
@export var sniper_waver: float = 0.25

@export var sniper_speed: float = 1400.0
@export var aim_lead: float = 0.6

var waiting := false
var in_combat := false
var time_since_shot: float = 0.0

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
	if in_combat:
		_handle_combat(delta)
	else:
		_handle_wandering(delta)

	_detect_player()

# --- Detection ---
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

	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	return hit.has("collider") and hit["collider"] == player

# --- Wandering ---
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

func _handle_combat(delta: float) -> void:
	if player == null or !is_instance_valid(player):
		in_combat = false
		return

	var to_player: Vector2 = player.global_position - global_position
	var facing: Vector2 = to_player.normalized()

	var sway: Vector2 = facing.orthogonal().rotated(randf_range(-0.2, 0.2)).normalized() * (move_speed * sniper_waver)
	velocity = sway
	move_and_slide()
	_update_directional_animation()

	time_since_shot += delta
	if time_since_shot >= sniper_interval and _has_line_of_sight_to_player():
		var fire_dir: Vector2 = _get_sniper_direction(facing)
		_shoot_projectile(fire_dir)
		time_since_shot = 0.0

func _get_sniper_direction(default_dir: Vector2) -> Vector2:
	if player is CharacterBody2D:
		var cb := player as CharacterBody2D
		var rel: Vector2 = cb.global_position - global_position
		var v: Vector2 = cb.velocity
		var a: float = v.dot(v) - sniper_speed * sniper_speed
		var b: float = 2.0 * rel.dot(v)
		var c: float = rel.dot(rel)
		var t: float = 0.0
		var disc: float = b*b - 4.0*a*c
		if disc > 0.0 and abs(a) > 0.0001:
			var sqrt_disc: float = sqrt(disc)
			var t1: float = (-b - sqrt_disc) / (2.0 * a)
			var t2: float = (-b + sqrt_disc) / (2.0 * a)
			var cand: float = min(t1, t2)
			if cand <= 0.0:
				cand = max(t1, t2)
			if cand > 0.0:
				t = cand
		if t > 0.0:
			var aim_at: Vector2 = cb.global_position + v * t * aim_lead
			return (aim_at - global_position).normalized()
	return default_dir

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
