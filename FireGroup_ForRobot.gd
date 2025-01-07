extends Spatial

onready var UI_node = get_node("/root/Game/CanvasLayer/UI")
onready var Canteen = $Canteen
onready var HRdep = $HRdep
onready var Manager = $Manager

var target_pos = Vector3()
var target_rot
var in_area = 0
# 0 == false | 1 == area except lounge | 2 == lounge

func is_in_area():
	in_area = 0
	var area_group = self.get_children()
	for child_area in area_group:
		if child_area.is_in == true and child_area.get_node("fire/flames").emitting == true:
			print(child_area.get_name())
			in_area = 1
			if child_area.get_name() == 'Lounge':
				in_area = 2
			target_pos = child_area.get_node("RobotStop").global_transform.origin
			target_rot = child_area.get_node("RobotStop").global_transform.basis

	
	return in_area
