extends Spatial

onready var control_interface = $Control
signal near_to_fire

func _ready():
	add_to_group("fire_training")
	$fire_area.connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
	if body.is_in_group("player"):
		control_interface.show_interface()
		
	if body.is_in_group("robot"):
		emit_signal("near_to_fire")
