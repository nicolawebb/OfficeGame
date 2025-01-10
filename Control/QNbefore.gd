extends Control

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
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q10/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q11/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q12/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q13/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q14/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q15/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q16/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q17/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q18/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q19/HBoxContainer,
	$ColorRect/Questionnaire/ScrollContainer/VBoxContainer/Q20/HBoxContainer
]
onready var InfoCollect = get_node("../InfoCollect")
signal completed()
signal completedDEMO()

func _ready():
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
		continue_button.modulate = Color(1, 1, 1)
	else:
		continue_button.disabled = true
		continue_button.modulate = Color(0.5, 0.5, 0.5)
		
func save_to_txt():
	var q_num = 0
	var answer_data = []
	
	for question in questions:
		q_num += 1
		for button in question.get_children():
			if button is Button and button.pressed:
				answer_data.append(button.text)
	print(answer_data)
	emit_signal("completed", answer_data)

	
func _on_continue():
	save_to_txt()
	continue_button_audio.play()
	
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	visible = false



func get_current_time() -> String:
	var datetime = OS.get_datetime()
	var day = str(datetime.day).pad_zeros(2)
	var hour = str(datetime.hour).pad_zeros(2)
	var minute = str(datetime.minute).pad_zeros(2)
	var second = str(datetime.second).pad_zeros(2)
	return day + hour + minute + second
