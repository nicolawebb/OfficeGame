extends Control

onready var continue_button = $ColorRect/CenterContainer/VBoxContainer/CenterContainer/Button
onready var continue_button_audio = $continue_audio
onready var QNafter = $"../QNafter"

func _ready():
	self.visible = false
	continue_button.connect("pressed", self, "_on_continue")

func _on_CheckPoint_game_over():
	self.visible =true
	get_tree().paused = not get_tree().paused

func _on_continue():
	continue_button_audio.play()
	
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	get_tree().paused = false
	
	$"../QNafter".visible = true
	$"../QNafter".get_node("ColorRect").visible = true
	visible = false
	
