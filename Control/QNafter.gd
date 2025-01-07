extends Control

signal completed2()

var i = 0
onready var continue_button = $ColorRect/Continue/Button
onready var continue_button_audio = $continue_audio
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
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q10/HBoxContainer
]
onready var InfoCollect = get_node("../InfoCollect")




func _ready():
	self.visible = false
	for question in questions:
		for button in question.get_children():
			if button is Button:
				button.connect("pressed", self, "_on_option_selected")

	continue_button.disabled = true
	continue_button.modulate = Color(0.5, 0.5, 0.5)
	
	continue_button.connect("pressed", self, "_on_continue")

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
		continue_button.text = "Exit"
		continue_button.modulate = Color(1, 1, 1)
	else:
		continue_button.disabled = true
		continue_button.modulate = Color(0, 0, 0)
		
	
func save_to_txt():
	var q_num = 0
	var answer_data = []
	
	for question in questions:
		q_num += 1
		for button in question.get_children():
			if button is Button and button.pressed:
				answer_data.append("Question" + str(q_num) + ": " + button.text)
	
	print(answer_data)
	emit_signal("completed2", answer_data)
	
	
func _on_continue():
	save_to_txt()
	continue_button_audio.play()
	
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	get_tree().quit()
