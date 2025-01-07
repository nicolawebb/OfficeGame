extends Control

onready var portrait = $CharacterViewport/Character
onready var fire_progress = $Top/VBoxContainer/ProgressBar
onready var ChatLabel = $Bottom/ColorRect/VBoxContainer/CenterContainer/ColorRect/CenterContainer/VBoxContainer/Chat
onready var Icon = $Bottom/ColorRect/VBoxContainer/Control/TextureRect
onready var Advise = $Advise
onready var chat_port = $Top/HBoxContainer2
onready var blank = $Top/Control
onready var chat_label = $Top/HBoxContainer2/NameBox/Name
onready var Robot_game = get_node("/root/Game/RobotPath/PathFollow/Robot")
onready var Robot_train = get_node("/root/Game/TrainArea/Training2/Path/PathFollow/Robot")

var robot_online = preload("res://assets/icons/robot-online.svg")
var robot_online_hover = preload("res://assets/icons/robot-online.svg")
var robot_offline = preload("res://assets/icons/robot-sleepy.svg")
var robot_offline_hover = preload("res://assets/icons/robot-sleepy-hover.svg")
var robot_connecting = preload("res://assets/icons/robot-connecting.svg")
var robot_connecting_hover = preload("res://assets/icons/robot-connecting-hover.svg")

var chat_active = preload("res://assets/icons/chat_active.svg")
var chat_inactive = preload("res://assets/icons/chat.svg")
var fire_putout = 0
var wait_time = 2.0

signal on_expression
signal all_putOut

# Called when the node enters the scene tree for the first time.
func _ready():
	ChatLabel.visible = false
	Advise.visible = false
	ChatLabel.autowrap = true
	chat_port.visible = false
	blank.visible = true
	
	var _err = $RightPanel/IconSet/settings.connect("pressed", self, "on_settings") 
	_err = $RightPanel/IconSet/chat.connect("pressed", self, "on_chat") 
	
	if GameState.robots_enabled():
#		_err = $RightPanel/IconSet/robot.connect("pressed", self, "on_robot_clicked")    
		_err = GameState.connect("robot_state_changed", self, "on_robot_state_changed")
	else:
		$RightPanel/IconSet/robot.hide()
	
	#_err = $Bottom/Actions/ExpressionGroup/happy.connect("pressed", self, "emit_signal", ["on_expression", GameState.Expressions.NEUTRAL])
	#_err = $Bottom/Actions/ExpressionGroup/sad.connect("pressed", self, "emit_signal", ["on_expression", GameState.Expressions.SAD])
	#_err = $Bottom/Actions/ExpressionGroup/angry.connect("pressed", self, "emit_signal", ["on_expression", GameState.Expressions.ANGRY])
	#_err = $Bottom/Actions/ExpressionGroup/excited.connect("pressed", self, "emit_signal", ["on_expression", GameState.Expressions.HAPPY])
	
	connect("on_expression" ,portrait, "set_expression")
	
	portrait.portrait_mode(true)
	portrait.set_close_up_camera()

#func set_name_skin(name, skin):
#	$Top/HBoxContainer2/NameBox/Name.text = name
#	portrait.set_base_skin(skin)
	
func on_settings():
	$Settings.show()

func on_chat():
	if not $RightPanel/Chat.is_visible_in_tree():
		$RightPanel/IconSet/chat.texture_normal = chat_active
		$RightPanel/IconSet/chat.texture_hover = chat_active
		$RightPanel/Chat.show()
	else:
		$RightPanel/IconSet/chat.texture_normal = chat_inactive
		$RightPanel/IconSet/chat.texture_hover = chat_active
		$RightPanel/Chat.hide()
	
func toggle_robots_support(active):
	if active:
#		$RightPanel/IconSet/robot.show()
		pass
	else:
		$RightPanel/IconSet/robot.hide()
		
func on_robot_clicked():
	
	# if we were DISCONNECTED, try to connect...
	if GameState.robot_state == GameState.RobotState.DISCONNECTED:
		GameState.emit_signal("robot_state_changed", GameState.RobotState.CONNECTING)
		return
		
	# ...if we were trying to connect, disconnect
	if GameState.robot_state == GameState.RobotState.CONNECTING:
		GameState.emit_signal("robot_state_changed", GameState.RobotState.DISCONNECTED)
		return

func on_robot_state_changed(state):
	
	match state:
		GameState.RobotState.DISCONNECTED:
			$RightPanel/IconSet/robot.texture_normal = robot_offline
			$RightPanel/IconSet/robot.texture_hover = robot_offline_hover
		GameState.RobotState.CONNECTED:
			$RightPanel/IconSet/robot.texture_normal = robot_online
			$RightPanel/IconSet/robot.texture_hover = robot_online_hover
		GameState.RobotState.CONNECTING:
			$RightPanel/IconSet/robot.texture_normal = robot_connecting
			$RightPanel/IconSet/robot.texture_hover = robot_connecting_hover


func _process(_delta):
	var tex = $CharacterViewport.get_texture()
	$Top/HBoxContainer2/Portrait.texture = tex

func _on_nag_fire_put_out():
	fire_putout += 1
	fire_progress.value = fire_putout
	if fire_putout == 15:
		emit_signal("all_putOut")

func breaking_stage2():
	fire_progress.max_value = 15

func _get_target_path(target_pos):
	if Robot_game.enter_building or Robot_train.stage_2:
		Icon.texture = robot_online
		ChatLabel.visible = true
		ChatLabel.text = "I'm coming"
		
func show_good_job():
	Icon.texture = robot_online
	ChatLabel.visible = true
	ChatLabel.text = "Fire extinguished"
	yield(get_tree().create_timer(wait_time), "timeout")
	Icon.texture = robot_offline
	ChatLabel.text = ""
	ChatLabel.visible = false
	
func on_my_way():
	Icon.texture = robot_offline
	ChatLabel.visible = true
	ChatLabel.text = "I'm on my way"
	yield(get_tree().create_timer(wait_time), "timeout")
	ChatLabel.text = ""
	ChatLabel.visible = false
	
func in_breaking():
	Icon.texture = robot_offline
	ChatLabel.visible = true
	ChatLabel.text = "I can't come to help you right now, I'm busy"
	yield(get_tree().create_timer(wait_time), "timeout")
	ChatLabel.text = ""
	ChatLabel.visible = false
	
func show_cant_help():
	Icon.texture = robot_offline
	ChatLabel.visible = true
	ChatLabel.text = "I can't help you for this, but I think you can put it out by yourself"
	yield(get_tree().create_timer(2*wait_time), "timeout")
	ChatLabel.text = ""
	ChatLabel.visible = false
	
func show_nofire():
	Icon.texture = robot_offline
	ChatLabel.visible = true
	ChatLabel.text = "I don't see any fire here"
	ChatLabel.autowrap = true
	yield(get_tree().create_timer(wait_time), "timeout")
	ChatLabel.text = ""
	ChatLabel.visible = false	

func find_aFire():
	Icon.texture = robot_connecting
	ChatLabel.visible = true
	ChatLabel.text = "I find a fire!"
	
func reached_target():
	Icon.texture = robot_offline
	ChatLabel.text = ""
	ChatLabel.visible = false
	
func _show_advise():
	Advise.visible = true
	yield(get_tree().create_timer(2.0), "timeout")
	Advise.visible = false
	
func _on_CheckPoint_game_over():
	self.visible = false

func coming():
	Icon.texture = robot_online
	ChatLabel.visible = true
	ChatLabel.text = "I'm coming"
	
func lets_getout():
	Icon.texture = robot_online
	ChatLabel.visible = true
	ChatLabel.text = "All fires extinguished, let's exit the building"
#	yield(get_tree().create_timer(wait_time*2.0), "timeout")
#	ChatLabel.text = ""
#	ChatLabel.visible = false	

func dangerous():
	Icon.texture = robot_online
	ChatLabel.visible = true
	ChatLabel.text = "There's no need to stay in the building, let's get out first"
	yield(get_tree().create_timer(wait_time), "timeout")
	ChatLabel.text = ""
	ChatLabel.visible = false	
	
func show_cant_putout():
	Icon.texture = robot_offline
	ChatLabel.visible = true
	ChatLabel.text = "There's a fire in the kitchen. I can't put it out."
#	yield(get_tree().create_timer(2*wait_time), "timeout")
#	ChatLabel.text = ""
#	ChatLabel.visible = false
	
func chat_port():
	chat_port.visible = not chat_port.visible
	blank.visible = not blank.visible	
	chat_label.text = 'Thank you so much !'
	
	
func good_visible_explanation():
	Icon.texture = robot_offline
	ChatLabel.visible = true
	ChatLabel.text = "I'm sorry, I can't come help you right now. I need to go help someone evacuate the building first."
	yield(get_tree().create_timer(wait_time), "timeout")
	ChatLabel.text = ""
	ChatLabel.visible = false
	
func bad_visible_explanation():
	Icon.texture = robot_offline
	ChatLabel.visible = true
	ChatLabel.text = "I'm busy"
	yield(get_tree().create_timer(wait_time), "timeout")
	ChatLabel.text = ""
	ChatLabel.visible = false
	
func good_nonvisible_explanation():
	Icon.texture = robot_offline
	ChatLabel.visible = true
	ChatLabel.text = "I'm sorry, I can't come help you right now. I need to go help someone evacuate the building first."
	yield(get_tree().create_timer(wait_time), "timeout")## change
	ChatLabel.text = ""
	ChatLabel.visible = false
	
func bad_nonvisible_explanation():
	Icon.texture = robot_offline
	ChatLabel.visible = true
	ChatLabel.text = "I'm busy"
	yield(get_tree().create_timer(wait_time), "timeout")## change
	ChatLabel.text = ""
	ChatLabel.visible = false
	
func _input(event):
	if event.is_action_pressed("hack"):
		emit_signal("all_putOut")
		
func start_intro():
	pass
	
func more_fire():
	Icon.texture = robot_online
	ChatLabel.visible = true
	ChatLabel.text = "More flames appeared in the building"
