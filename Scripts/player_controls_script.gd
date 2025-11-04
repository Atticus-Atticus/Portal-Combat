extends CharacterBody2D
@onready var projectile_scene: PackedScene = preload("res://NPCs/Portalbull.tscn")
@export var SPEED = 400
@export var ACCEL = 100
@export var FRCTION = 8

func _physics_process(delta: float) -> void:
	var input_vector = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	var target_velocity = input_vector.normalized() * SPEED
	
	if input_vector.length() > 0:
		velocity = velocity.lerp(target_velocity, ACCEL * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, FRCTION * delta)
		
	move_and_slide()
	
	if Input.is_action_just_pressed("RMB"):
		if projectile_scene == null:
			return
		var portbull = projectile_scene.instantiate()
		get_parent().add_child(portbull)
		portbull.position.x = $".".position.x + 60 * (get_viewport().get_mouse_position().x - $".".position.x) / sqrt(pow(get_viewport().get_mouse_position().x - $".".position.x,2)+pow(get_viewport().get_mouse_position().y - $".".position.y,2))
		portbull.position.y = $".".position.y+ 60 * (get_viewport().get_mouse_position().y - $".".position.y) / sqrt(pow(get_viewport().get_mouse_position().x - $".".position.x,2)+pow(get_viewport().get_mouse_position().y - $".".position.y,2))
		
		portbull.velocity.y = 300 * (get_viewport().get_mouse_position().y - $".".position.y) / sqrt(pow(get_viewport().get_mouse_position().x - $".".position.x,2)+pow(get_viewport().get_mouse_position().y - $".".position.y,2))
		portbull.velocity.x = 300 * (get_viewport().get_mouse_position().x - $".".position.x) / sqrt(pow(get_viewport().get_mouse_position().x - $".".position.x,2)+pow(get_viewport().get_mouse_position().y - $".".position.y,2))
		portbull.set_meta("Leftportal",false)
	elif Input.is_action_just_pressed("LMB"):
		if projectile_scene == null:
			return
		var portbull = projectile_scene.instantiate()
		get_parent().add_child(portbull)
		portbull.position.x = $".".position.x + 60 * (get_viewport().get_mouse_position().x - $".".position.x) / sqrt(pow(get_viewport().get_mouse_position().x - $".".position.x,2)+pow(get_viewport().get_mouse_position().y - $".".position.y,2))
		portbull.position.y = $".".position.y+ 60 * (get_viewport().get_mouse_position().y - $".".position.y) / sqrt(pow(get_viewport().get_mouse_position().x - $".".position.x,2)+pow(get_viewport().get_mouse_position().y - $".".position.y,2))
		
		portbull.velocity.y = 300 * (get_viewport().get_mouse_position().y - $".".position.y) / sqrt(pow(get_viewport().get_mouse_position().x - $".".position.x,2)+pow(get_viewport().get_mouse_position().y - $".".position.y,2))
		portbull.velocity.x = 300 * (get_viewport().get_mouse_position().x - $".".position.x) / sqrt(pow(get_viewport().get_mouse_position().x - $".".position.x,2)+pow(get_viewport().get_mouse_position().y - $".".position.y,2))
		portbull.set_meta("Leftportal",true)
