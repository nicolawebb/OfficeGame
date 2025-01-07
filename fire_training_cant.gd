extends Spatial

onready var control_interface = $Control
onready var Robot_node = get_node("/root/Game/RobotPath/PathFollow/Robot")

func _ready():
	add_to_group("fire_cant")
	$fire_area.connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
	if body.is_in_group("player"):
		control_interface.show_interface()
		
	if	body.is_in_group("robot"):
		yield(get_tree().create_timer(1.0), "timeout")
		add_to_group("fire_training")
