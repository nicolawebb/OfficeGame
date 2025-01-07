extends Spatial

onready var particles = $smoke
onready var audio = $AudioStreamPlayer3D

func _ready():
	particles.emitting = false

func _input(event):
	if event.is_action_pressed("fireextinguisher"):
			particles.emitting = true
			audio.play()
			
	elif event.is_action_released ("fireextinguisher"):
			particles.emitting = false
			audio.stop()
