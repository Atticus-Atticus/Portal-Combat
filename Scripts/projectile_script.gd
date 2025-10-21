extends Area2D

@export var velocity: Vector2
@export var lifetime := 10.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
