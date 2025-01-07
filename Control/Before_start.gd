extends Control

onready var continue_button = $ColorRect/Button

func _ready():
	visible = false
	
	$ColorRect/Button.connect("pressed", self, "_on_continue")

func _on_continue():
	$continue_audio.play()
	get_tree().paused = false
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	visible = false
