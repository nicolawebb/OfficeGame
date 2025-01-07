extends Spatial

onready var Training1 = $Training1
onready var Training2 = $Training2
onready var Robot_node = $Training2/Path/PathFollow/Robot
onready var B_S = $"../CanvasLayer/Before_start"
onready var QNafter = get_node("/root/Game/CanvasLayer/QNafter")
onready var UI_node
signal tp(origin, basis)
signal show_interface

var target_pos = Vector3()
var target_rot
var done = 0
var is_in =false
var robot_is_in = false

func _ready():
	UI_node = get_node("/root/Game/CanvasLayer/UI")
	
	Robot_node.get_node("CollisionShape").disabled = true
	
	Training1.visible = true
	Training2.visible = false
	Training1.get_node("fire").visible = false
	Training1.get_node("fire/AudioStreamPlayer3D").stop()
	
	Training2.get_node("fire").visible = false
	Training2.get_node("fire/AudioStreamPlayer3D").stop()
	Training2.get_node("fire/fire_shape/CollisionShape").disabled = true
	Training2.get_node("Area3/CollisionShape").disabled = true
	Training2.get_node("Area4/CollisionShape").disabled = true
	target_pos = get_node("Training2/Area5/Position3D").global_transform.origin
	target_rot = get_node("Training2/Area5/Position3D").global_transform.basis
	
	Training1.get_node("Text_Intro/AcceptDialog").pause_mode = Node.PAUSE_MODE_PROCESS

	
	
#	var spawn = Training1.get_node("Position3Dstart")
	var spawn = Training2.get_node("Position3D")
	emit_signal("tp", spawn.global_transform.origin, spawn.global_transform.basis.orthonormalized())
	
func _on_Area_body_entered(body):		#Area1
	if body.is_in_group("player") and Training1.visible:
		Training1.get_node("Text_Intro/AcceptDialog").visible = true
		get_tree().paused = true  # Pause the game tree
		Training1.get_node("Text_Intro/AcceptDialog").connect("confirmed", self, "_on_confirmation_dialog_confirmed")
		
	elif body.is_in_group("player") and Training2.visible:
		Training1.get_node("Text_Intro/AcceptDialog").dialog_text = "However, most of the flames in the building are difficult to put out on your own. In this case, you may need help from your robot companion."
		Training1.get_node("Text_Intro/AcceptDialog").visible = true
		get_tree().paused = true  # Pause the game tree
		
# Function called when the confirmation dialog is confirmed
func _on_confirmation_dialog_confirmed():
	get_tree().paused = false  # Resume the game tree

func _on_Area2_body_entered(body):
	if body.is_in_group("player") and Training1.visible:
#		Training1.get_node("Text_Inst").visible = true
		Training1.get_node("fire").visible = true
		Training1.get_node("fire/AudioStreamPlayer3D").play()
		
		Training1.get_node("Text_Intro/AcceptDialog").dialog_text = "Like this one, try to press 'F' key to use the fire-extinguisher in your hand to put out the fire"
		Training1.get_node("Text_Intro/AcceptDialog").visible = true
		get_tree().paused = true  # Pause the game tree
		
	elif body.is_in_group("player") and Training2.visible:
		Training2.get_node("Path").visible = true
		Training1.get_node("Text_Intro/AcceptDialog").dialog_text = "This is your robot companion. You can call it by pressing the 'E' key. In addition, the robot will communicate with you through the chatbox in the lower left corner"
		Training1.get_node("Text_Intro/AcceptDialog").visible = true
		get_tree().paused = true  # Pause the game tree

func _process(delta):
	if Training1.get_node("fire/flames").emitting == false and done == 0:
#		Training1.get_node("Text_Inst").visible = false
		Training1.get_node("Text_GJ").visible = true
		done += 1
		goto_training2()
	
	elif Training2.get_node("fire/flames").emitting == false and done == 1:
#		Training2.get_node("Text_Inst2").visible = false
		Training2.get_node("Text_GJ2").visible = true
		done += 1
		go_nag()

#func _on_Area3_body_entered(body):
#	if body.is_in_group("player"):
##		Training2.get_node("Text_Intro4").visible = true
#		Training2.get_node("Path").visible = true
#
#		Training1.get_node("Text_Intro/AcceptDialog").dialog_text = "This is your robot companion. You can call it by pressing the 'E' key. In addition, the robot will communicate with you through the chatbox in the lower left corner"
#		Training1.get_node("Text_Intro/AcceptDialog").visible = true
#		get_tree().paused = true  # Pause the game tree
		
func _on_Area4_body_entered(body):
	if body.is_in_group("player"):
#		Training2.get_node("Text_Inst2").visible = true
		Training2.get_node("fire").visible = true
		Training2.get_node("fire/AudioStreamPlayer3D").play()
		
		Training1.get_node("Text_Intro/AcceptDialog").dialog_text = "The robot will automatically detects nearby flames and approaches them then activate the fire-extinguisher. Now try to put out a fire with the robot."
		Training1.get_node("Text_Intro/AcceptDialog").visible = true
		get_tree().paused = true  # Pause the game tree
		
	
func goto_training2():
	yield(get_tree().create_timer(2.0), "timeout")
	Training1.visible = false
	Training2.get_node("fire/fire_shape/CollisionShape").disabled = false
	Training2.get_node("Area3/CollisionShape").disabled = false
	Training2.get_node("Area4/CollisionShape").disabled = false
	Training2.visible = true
#	Training1.get_node("Text_Intro/AcceptDialog").visible = true
	var position = Training2.get_node("Position3D")
	Robot_node.get_node("CollisionShape").disabled = false
	Robot_node.stage_2 = true
	emit_signal("tp", position.global_transform.origin, position.global_transform.basis.orthonormalized())


func _on_Area5_body_entered(body):
	if body.is_in_group("player"):
		is_in = true
		
	if body.is_in_group("robot"):
		robot_is_in = true
		UI_node.find_aFire()

func _on_Area5_body_exited(body):
	if body.is_in_group("player"):
		is_in = false
		
func go_nag():
	emit_signal("show_interface")
	
func start_game():
	yield(get_tree().create_timer(1.0), "timeout")
	var position = get_node("/root/Game/SpawnPoint")
	emit_signal("tp", position.global_transform.origin, position.global_transform.basis.orthonormalized())
	self.visible = false
	Robot_node.end_training = true
	QNafter.visible = true
	Robot_node.stage_2 = false
	UI_node.reached_target()
	UI_node.start_intro()
