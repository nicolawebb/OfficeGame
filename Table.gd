extends Spatial

var is_in = false
var fire = true
onready var UI_node = get_node("/root/Game/CanvasLayer/UI")
onready var Fg = $".."


func _on_Area_body_entered(body):
	if body.is_in_group("player"):
		is_in = true
		
	if body.is_in_group("robot"):
		if self.get_node("fire/flames").emitting == true:
			UI_node.find_aFire()
			fire = false


func _on_Area_body_exited(body):
	if body.is_in_group("player"):
		is_in = false
