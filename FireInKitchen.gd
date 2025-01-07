extends Spatial

var stage2_signal = false
onready var UI_node = get_node("/root/Game/CanvasLayer/UI")

func _ready():
	self.visible = false
	translation.y -= 30
	
func _on_Area_body_entered(body):
	if body.is_in_group("robot"):
		if self.get_node("fire/flames").emitting == true and stage2_signal == true:
			UI_node.find_aFire()
			
func stage2():
	stage2_signal = true
	translation.y += 30
	self.visible = true
