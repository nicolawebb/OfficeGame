extends Spatial

var is_in = false
var child
onready var UI_node = get_node("/root/Game/CanvasLayer/UI")
onready var Breaking = get_node("/root/Game/RobotPath/PathFollow/Robot/Breaking")
onready var Mo = $"../../MainOffice"

func _ready():
	child = self.get_children()

func _on_Area_body_entered(body):
	if body.is_in_group("player"):
		is_in = true
		
	if body.is_in_group("robot"):
		if self.get_node("fire/flames").emitting == true and Breaking.after_breaking == true:
			afterBreaking()
			UI_node.find_aFire()
#			pass

	if body.is_in_group("npc"):
		UI_node.chat_port()
		yield(get_tree().create_timer(1.5), "timeout")
		Mo.stage_2()

func _on_Area_body_exited(body):
	if body.is_in_group("player"):
		is_in = false

	if body.is_in_group("npc"):
		UI_node.chat_port()

func afterBreaking():
	for child_node in child:
		if child_node.is_in_group("fire_cant"):
			child_node.add_to_group("fire_can")
			
func all_putOut():
	var allputout = true
	for child_node in child:
		if child_node.is_in_group("fire_can"):
			if child_node.get_node("flames").emitting == true:
				allputout = false
	
	return allputout
