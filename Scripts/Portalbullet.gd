extends CharacterBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	move_and_slide()
	pass





func _on_area_2d_body_entered(body: Node2D) -> void:
	var xtemp : float
	var ytemp : float
	print($".".name)
	if body.has_meta("Portalable"):
		if body.get_meta("Portalable"):
			xtemp = sqrt(pow(body.position.x-$".".position.x,2) + pow(body.position.y-$".".position.y,2))
			if xtemp > body.get_child(0).shape.size.x - 100 :
				ytemp = body.position.y - (((body.get_child(0).shape.size.x - 200)) * sin(body.rotation)) + 20 * sin(body.rotation - PI / 2)
				xtemp = body.position.x - (((body.get_child(0).shape.size.x - 200)) * cos(body.rotation)) + 20 * cos(body.rotation - PI / 2)
			elif xtemp < 100:
				xtemp = body.position.x - (10 * cos(body.rotation)) + 20 * cos(body.rotation - PI / 2) 
				ytemp = body.position.y - (10 * sin(body.rotation)) + 20 * sin(body.rotation - PI / 2) 
			else:
				ytemp = body.position.y - (((sqrt(pow(body.position.x-$".".position.x,2) + pow(body.position.y-$".".position.y,2))) - 100) * sin(body.rotation)) + 20 * sin(body.rotation - PI / 2)
				xtemp = body.position.x - (((sqrt(pow(body.position.x-$".".position.x,2) + pow(body.position.y-$".".position.y,2))) - 100) * cos(body.rotation)) + 20 * cos(body.rotation - PI / 2) 

			if $".".get_meta("Leftportal") == true :
				$"../Leftport".position.x = xtemp
				$"../Leftport".position.y = ytemp
				$"../Leftport".rotation = body.rotation
			else:
				$"../Rightport".position.y = ytemp
				$"../Rightport".position.x = xtemp
				$"../Rightport".rotation = body.rotation
			
			
			

	

	pass # Replace with function body.
