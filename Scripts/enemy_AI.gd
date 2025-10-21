extends CharacterBody2D

@onready var agent: NavigationAgent2D = $NavigationAgent2D

@export var speed = 100
@export var wander_radius = 300
@export var wait_time = 2

var waiting = false

func _ready() -> void:
	_pick_destination()

func _physics_process(delta: float) -> void:
	if waiting:
		return
	
	var next_destination = agent.get_next_path_position()
	
	var direction = (next_destination - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	if agent.is_navigation_finished():
		_wait_timer()
	
func _pick_destination():
	var random = Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	var new_target = global_position + random
	
	agent.set_target_position(new_target)
	
func _wait_timer():
	waiting = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(wait_time).timeout
	waiting = false
	_pick_destination()
