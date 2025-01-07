extends Control

onready var timer = $Timer

func _ready():
	self.visible = false
	timer.connect("timeout", self, "_on_timer_timeout")
	
func show_interface():
	self.visible = true

	timer.start(1.0)
	
func _on_timer_timeout():

#	yield($Tween, "tween_all_completed")
	
	self.visible = false
	timer.stop()
