extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass






	pass
	


func _on_rightport_body_entered(body: Node2D) -> void:
	var xtemp : float
	var ytemp : float
	
	ytemp = $"../../Leftport".position.y - ((sqrt(pow(body.position.y - $"..".position.y,2) + pow(body.position.x - $"..".position.x,2))) * sin($"../../Leftport".rotation)) + 60 * sin($"../../Leftport".rotation - PI / 2)
	xtemp = $"../../Leftport".position.x - ((sqrt(pow(body.position.y - $"..".position.y,2) + pow(body.position.x - $"..".position.x,2))) * cos($"../../Leftport".rotation)) + 60 * cos($"../../Leftport".rotation - PI / 2) 
	body.position.x = xtemp
	body.position.y = ytemp
	
	
	ytemp = ((sqrt(pow(body.velocity.x,2) + pow(body.velocity.y,2))) * sin($"../../Leftport".rotation - (PI / 2)))
	xtemp =  ((sqrt(pow(body.velocity.x,2) + pow(body.velocity.y,2))) * cos($"../../Leftport".rotation - (PI / 2)))
	body.velocity.x = xtemp
	body.velocity.y =  ytemp
	pass # Replace with function body.
