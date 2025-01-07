extends Control

signal call_robot

func _input(event):
	if event.is_action_pressed("CallForHelp"):
#			get_tree().paused = not get_tree().paused
#			self.visible = not self.visible
			emit_signal("call_robot")
