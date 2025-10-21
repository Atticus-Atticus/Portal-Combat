extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_rightport_body_entered(body: Node2D) -> void:
	body.position = $"../../Leftport".position


	if round($"..".rotation_degrees - $"../../Leftport".rotation_degrees) / 90  == 3:
		body.velocity.x = - body.velocity.y
		body.velocity.y = - body.velocity.x 
	elif round($"..".rotation_degrees - $"../../Leftport".rotation_degrees) / 90 == 1:
		body.velocity.x = body.velocity.y
		body.velocity.y = body.velocity.x
	elif round($"..".rotation_degrees - $"../../Leftport".rotation_degrees) / 90 == 2:
		body.velocity.x = - body.velocity.x
		body.velocity.y = - body.velocity.y 
	
