extends CharacterBody2D

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

# so, Mort got us into a fucking car wreck
# and now I can't move it move it anymore!
