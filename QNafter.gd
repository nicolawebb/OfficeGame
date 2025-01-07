extends Control

var i = 0
var count = 1 
var path ="logs/"
onready var continue_button = $ColorRect/Continue/Button
onready var exit_button = $ColorRect2/CenterContainer/VBoxContainer/HBoxContainer/Button2
onready var continue_button_audio = $continue_audio
onready var Game = $"../.."
onready var button_audio = $Qbutton
onready var questions = [
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q1/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q2/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q3/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q4/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q5/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q6/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q7/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q8/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q9/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q10/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q11/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q12/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q13/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q14/HBoxContainer
]
onready var InfoCollect = get_node("../InfoCollect")


func _ready():
	$ColorRect.visible = true
	$ColorRect2.visible = false
	self.visible = false
#	self.visible = true
	for question in questions:
		for button in question.get_children():
			if button is Button:
				button.connect("pressed", self, "_on_option_selected")

	continue_button.disabled = true
	continue_button.modulate = Color(0.5, 0.5, 0.5)
	
	continue_button.connect("pressed", self, "_on_continue")
	exit_button.connect("pressed", self, "_on_exit")

func _on_option_selected():
#	print("pressed")
	button_audio.play()
	check_all_questions_answered()

func check_all_questions_answered():
	var all_answered = true
	for question in questions:
		var answered = false
		i = 0
		for button in question.get_children():
			i = i+1
			if button is Button and button.pressed:
#				print(str(i))
				answered = true
				break
		if not answered:
			all_answered = false
			break

	if all_answered:
		continue_button.disabled = false
		continue_button.modulate = Color(1, 1, 1)
	else:
		continue_button.disabled = true
		continue_button.modulate = Color(0.5, 0.5, 0.5)
		
func save_to_txt():
	var file = File.new()
	var q_num = 0
#	file.open("user://Control/survey_results.csv", File.WRITE)
#	print('Open')
	var file_path = InfoCollect.file_path
	var error = file.open(file_path, File.READ_WRITE)

	file.seek_end()  # 移动文件指针到文件末尾
	if count == 1:
		file.store_string("\n" + "After Demo" + "\n")

	if count == 2:
		file.store_string("\n" + "After Game" + "\n")

	for question in questions:
		i = 0
		q_num = q_num + 1
		for button in question.get_children():
			i = i+1
			if button is Button and button.pressed:
				button.pressed = false
#				file.store_line(str(i))  # Save question and selected option
				file.seek_end()  # 移动文件指针到文件末尾
				file.store_string("Question" + str(q_num) + ": " + "\n" + button.text + "\n")  # 在写入数据前添加换行符
	
	file.close()
	
func _on_continue():
	if InfoCollect.file_path != null:
		save_to_txt()

	continue_button_audio.play()
	var answer_data = []
	var q_num = 0
	for question in questions:
		q_num += 1
		for button in question.get_children():
			if button is Button and button.pressed:
				answer_data.append(button.text)
	print(answer_data)
	create_a_file(answer_data)
#	$Tween.remove_all()
#	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
#	$Tween.start()
#	yield($Tween, "tween_all_completed")
	if count == 1:
		count += 1
		get_tree().paused = true
		$ColorRect.visible = false
		self.visible = false
		$"../Before_start".visible = true
		for question in questions:
			for button in question.get_children():
				i = i+1
				if button is Button and button.pressed:
					button.pressed = false
	elif count == 2:
		$ColorRect2.visible = true
		$ColorRect.visible = false

func _on_exit():
	continue_button_audio.play()
	
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	get_tree().quit()
	
func create_a_file(answer_data):
	for player in Game.get_node("Players").get_children():
		var id = player.player_id
		var path_modified
		if count == 1:
			path_modified = "%s/%s_qn14_1.csv" % [path, id]
		elif count == 2:
			path_modified = "%s/%s_qn14_2.csv" % [path, id]	
		var file = File.new()
		var error = file.open(path_modified, File.WRITE)
		if error != OK:
			print("Error opening file: " + path_modified)
			return
		else: 
			print("File created for the user with id %s" % id)

		file.store_line("1,2,3,4,5,6,7,8,9,10,11,12,13,14")

		var row = ",".join(answer_data)
		file.store_line(row)

		file.close()
		print("Answers saved to the file.")
