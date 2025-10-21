extends CharacterBody2D

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var player: Node2D = get_node_or_null(player_path)
@onready var projectile_scene: PackedScene = preload("res://NPCs/Projectile.tscn")

@export var move_speed: float = 200.0
@export var wander_radius: float = 300.0
@export var wait_time: float = 1.0
@export var detection_range: float = 400.0
@export var attack_range: float = 300.0
@export var shoot_interval: float = 1.2
@export var player_path: NodePath #assigned in the Inspector

var waiting := false
var in_combat := false
var time_since_shot := 0.0

func _ready():
	randomize()
	pick_new_destination()

func _physics_process(delta):
	if in_combat:
		_handle_combat(delta)
	else:
		_handle_wandering(delta)

	_detect_player()

#Detection
func _detect_player():
	if player == null or !is_instance_valid(player):
		in_combat = false
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
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

	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	return hit.has("collider") and hit["collider"] == player

#Wandering
func _handle_wandering(_delta):
	if waiting:
		return
	var next_point := agent.get_next_path_position()
	var direction := (next_point - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	if agent.is_navigation_finished():
		_start_wait_timer()

func pick_new_destination():
	var random_offset := Vector2(randf_range(-wander_radius, wander_radius),
								 randf_range(-wander_radius, wander_radius))
	var new_target := global_position + random_offset
	agent.set_target_position(new_target)

func _start_wait_timer():
	waiting = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(wait_time).timeout
	waiting = false
	pick_new_destination()

#Combat
func _handle_combat(delta):
	if player == null or !is_instance_valid(player):
		in_combat = false
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var facing := to_player.normalized()
	velocity = Vector2.ZERO

	if distance > attack_range or !_has_line_of_sight_to_player():
		# close distance / re-acquire
		agent.set_target_position(player.global_position)
		var next_point := agent.get_next_path_position()
		var advance := (next_point - global_position).normalized()
		velocity = advance * move_speed
		move_and_slide()
	else:
		# shoot + dodge/weave
		time_since_shot += delta
		if time_since_shot >= shoot_interval:
			_shoot_projectile(facing)
			time_since_shot = 0.0

		# jittery strafe around current facing
		var dodge := facing.rotated(randf_range(-0.9, 0.9)).orthogonal().normalized()
		velocity = dodge * (move_speed * 0.6)
		move_and_slide()

func _shoot_projectile(dir: Vector2):
	if projectile_scene == null:
		return
	var p = projectile_scene.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.rotation = dir.angle()
	if p.has_method("set"):
		p.set("velocity", dir * 400.0)
