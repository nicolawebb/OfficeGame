extends Control

signal on_character_created
onready var continue_button_audio = $continue_audio
onready var Info = get_node("/root/Game/CanvasLayer/InfoCollect")
var NB_CHARACTERS = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	for v in $Viewports.get_children():
		v.get_child(0).portrait_mode(true)
		
	for c in $CenterContainer/VBoxContainer/PortraitsContainer.get_children():
		c.connect("pressed", self, "on_pressed")
		



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for i in range(NB_CHARACTERS):
		var tex = $Viewports.get_child(i).get_texture()
		$CenterContainer/VBoxContainer/PortraitsContainer.get_child(i).texture_normal = tex

func on_pressed():
#	var name = $CenterContainer/VBoxContainer/Name.text
#	var name = Info.player_name
#	if name == "":
#		$CenterContainer/VBoxContainer/Name.placeholder_text = "You must set your name!"
#		return
	var resource_path = "res://assets/characters/skins/businessMaleB_neutral.png"
#	var texture
#
#	for i in range(NB_CHARACTERS):
#		var c = $CenterContainer/VBoxContainer/PortraitsContainer.get_child(i)
#		if c.pressed:
#			texture = $Viewports.get_child(i).get_child(0).neutral_skin
		
#	print("Created character " + name + " with skin " + texture.resource_path)
	continue_button_audio.play()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	visible = false
	
	emit_signal("on_character_created", [resource_path])
	
