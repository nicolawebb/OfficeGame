extends Control

onready var line_edit = $CenterContainer/VBoxContainer/LineEdit  # LineEdit 节点
onready var continue_button = $CenterContainer/VBoxContainer/Continue/Button
onready var ranks = [
	$CenterContainer/VBoxContainer/HBoxContainer/Button,
	$CenterContainer/VBoxContainer/HBoxContainer/Button2,
	$CenterContainer/VBoxContainer/HBoxContainer/Button3,
	$CenterContainer/VBoxContainer/HBoxContainer/Button4,
	$CenterContainer/VBoxContainer/HBoxContainer/Button5,
	$CenterContainer/VBoxContainer/HBoxContainer/Button6,
	$CenterContainer/VBoxContainer/HBoxContainer/Button7,
	$CenterContainer/VBoxContainer/HBoxContainer/Button8,
	$CenterContainer/VBoxContainer/HBoxContainer/Button9,
	$CenterContainer/VBoxContainer/HBoxContainer/Button10,
	$CenterContainer/VBoxContainer/HBoxContainer/Button11
]
onready var continue_button_audio = $continue_audio
onready var InfoCollect = get_node("../InfoCollect")
onready var UI_node = $"../UI"
onready var button_audio = $Qbutton
onready var Game = $"../.."

onready var TrainArea = $"../../TrainArea"
var nag_count = 1
var path ="res://logs"
var answer_data = []
signal fire_put_out
signal completed

# 初始化
func _ready():	
	self.visible = false
	var i = -1
#	for button in ranks:
#		button.connect("pressed", self, "_on_option_selected")
	
	line_edit.connect("text_changed", self, "_on_text_changed")
	
	continue_button.disabled = true
	continue_button.modulate = Color(0.5, 0.5, 0.5)
	
	continue_button.connect("pressed", self, "_on_continue")


func _show_interface():
	emit_signal("fire_put_out")
	self.pause_mode = PAUSE_MODE_PROCESS
	yield(get_tree().create_timer(1.0), "timeout")
	self.visible = true
	
	get_tree().paused = true
	
func _on_text_changed(new_text):
	continue_button.disabled = false
	continue_button.modulate = Color(1, 1, 1)

func _on_continue():
	var input_number = line_edit.text.to_int()
	if input_number >= 1 and input_number <= 10:
		print(input_number)
		logging(line_edit.text.to_int())
		answer_data.append(line_edit.text.to_int())
		line_edit.text = ""
		continue_button_audio.play()
		continue_button.disabled = true
		continue_button.modulate = Color(0.5, 0.5, 0.5)
		get_tree().paused = false
		print(answer_data)
		if nag_count == 2:
			TrainArea.start_game()
		if nag_count == 5:
			yield(get_tree().create_timer(2.0), "timeout")
			UI_node.coming()
		if nag_count == 7 or nag_count == 8:
			emit_signal("completed", answer_data)
			end_game(answer_data)
	#	$Tween.remove_all()
	#	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	#	$Tween.start()
	#	yield($Tween, "tween_all_completed")
		visible = false
	
	else:
		line_edit.text = ""
		line_edit.placeholder_text = "Please enter a number between 1 - 10"
	

func logging(trust_level):
#	pass
	var file = File.new()
	var file_path = InfoCollect.file_path
	if file_path != null:
		var error = file.open(file_path, File.READ_WRITE)

		file.seek_end()  # 移动文件指针到文件末尾
		file.store_string("Test " + str(nag_count) + " trust level: " + str(trust_level) + "\n")  # 在写入数据前添加换行符
		file.close()

		nag_count += 1
		answer_data.append(str(trust_level))
		
		if nag_count == 9:
			emit_signal("completed", answer_data)
	else:
		nag_count += 1

func _input(event):
	if get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
func end_game(answer_data):
	for player in Game.get_node("Players").get_children():
		var id = player.player_id
		var path_modified = "%s/%s_nag_trust_level.csv" % [path, id]	
		var file = File.new()
		var error = file.open(path_modified, File.WRITE)
		if error != OK:
			print("Error opening file: " + path_modified)
			return
		else: 
			print("File created for the user with id %s" % id)

		file.store_line("1,2,3,4,5,6,7")

		var row = ",".join(answer_data)
		file.store_line(row)

		file.close()
		print("Answers saved to the file.")
