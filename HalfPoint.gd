extends Spatial

onready var area = $Area
onready var control = $Control
onready var collision = $StaticBody/CollisionShape
onready var UI_node = get_node("/root/Game/CanvasLayer/UI")

func _ready():
	control.visible = false
	collision.disabled = false
	
func _on_Area_body_entered(body):
	if body.is_in_group("player"):
		if UI_node.fire_putout < 5:
			control.visible = true
			
		else:
			collision.disabled = true
			

func _on_Area_body_exited(body):
	if body.is_in_group("player"):
		if UI_node.fire_putout <=5 and control.visible == true:
			control.visible = false
