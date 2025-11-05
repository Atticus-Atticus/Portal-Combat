extends CharacterBody2D

@export var SPEED = 400
@export var ACCEL = 100
@export var FRCTION = 3
@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var input_vector = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	var target_velocity = input_vector.normalized() * SPEED
	
	if input_vector.length() > 0:
		velocity = velocity.lerp(target_velocity, ACCEL * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, FRCTION * delta)
	
	move_and_slide()
	_update_animation(input_vector)

func _update_animation(input_vector: Vector2) -> void:
	if input_vector.length() == 0:
		sprite.play("Idle")
		return
	
	if abs(input_vector.x) > abs(input_vector.y):
		sprite.play("Side")
		sprite.flip_h = input_vector.x > 0
	else:
		if input_vector.y > 0:
			sprite.play("Front")
		else:
			sprite.play("Back")

# so, Mort got us into a fucking car wreck
# and now I can't move it move it anymore!
