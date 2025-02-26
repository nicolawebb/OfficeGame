extends Control

onready var continue_button = $CenterContainer/VBoxContainer/Continue/Button
#onready var Ledit1 = $CenterContainer/VBoxContainer/HBoxContainer/FirstName
#onready var Ledit2 = $CenterContainer/VBoxContainer/HBoxContainer/FirstName2
onready var Ledit3 = $CenterContainer/VBoxContainer/HBoxContainer2/Age
onready var Age_warning = $CenterContainer/VBoxContainer/HBoxContainer3/CenterContainer/Age_warning

onready var prolific_id = $CenterContainer/VBoxContainer/HBoxContainer2/prolificid
onready var Obutton1 = $CenterContainer/VBoxContainer/HBoxContainer2/Gender
onready var Obutton2 = $CenterContainer/VBoxContainer/Q1/Know
onready var Obutton3 = $CenterContainer/VBoxContainer/Q2/Know2
onready var continue_button_audio = $continue_audio
onready var button_audio = $Qbutton
var file_path
#var player_name = ""
signal export_file_path(path)
signal infocollected()

var option_selected = {
	"Gender": false,
	"Know": false,
	"Know2": false
}

# Called when the node enters the scene tree for the first time.
func _ready():
	Age_warning.visible = false
	
	Obutton1.connect("item_selected", self, "_on_option_button_item_selected", ["Gender"])
	Obutton2.connect("item_selected", self, "_on_option_button_item_selected", ["Know"])
	
	continue_button.disabled = true
	continue_button.modulate = Color(0.5, 0.5, 0.5)
		
	continue_button.connect("pressed", self, "_on_continue")




var text_data_list = []
func _on_continue():

	var file = File.new()
	print("erfger")
#	if Ledit1.text == '' or Ledit2.text == '':
#		player_name = 'Anonymous'
#	else:
#		player_name = Ledit1.text + " " + Ledit2.text
	
	var text_data = prolific_id.text  + "," + Obutton1.get_item_text(Obutton1.selected) + "," + Ledit3.text + "," + Obutton2.get_item_text(Obutton2.selected) + "," + Obutton3.get_item_text(Obutton3.selected) + "\n"
	
	# Append text_data to the list
	text_data_list.append(text_data)
	
	# Emit signal with the updated list
	emit_signal("infocollected", text_data_list)
	
	continue_button_audio.play()
	
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	emit_signal("export_file_path", file_path)
	
	visible = false
	
func _on_option_button_item_selected(index, button_name):
	option_selected[button_name] = true
	button_audio.play()
	check_all_questions_answered()
	
func check_all_questions_answered():

	var answered1 = true
#	if Ledit1.text == "" or Ledit2.text == "" or Ledit3.text == "":
	if Ledit3.text == "":
		answered1 = false

	var answered2 = true
	for key in option_selected.keys():
		if not option_selected[key]:
			answered2 = false
			break
		else:
			answered2 = true
			
	if answered1 and answered2:
		continue_button.disabled = false
		continue_button.modulate = Color(1, 1, 1)
	else:
		continue_button.disabled = true
		continue_button.modulate = Color(0.5, 0.5, 0.5)
		



func get_current_time() -> String:
	var datetime = OS.get_datetime()
	var day = str(datetime.day).pad_zeros(2)
	var hour = str(datetime.hour).pad_zeros(2)
	var minute = str(datetime.minute).pad_zeros(2)
	var second = str(datetime.second).pad_zeros(2)
	return day + hour + minute + second


func _on_Age_text_entered():
	var age = $CenterContainer/VBoxContainer/HBoxContainer2/Age.text
	if age.to_int() >= 80 or age.to_int() <= 10:
		age == ''
		Age_warning.visible = true
		return false
	
	Age_warning.visible = false
	return true

func validate():
	var id = $CenterContainer/VBoxContainer/HBoxContainer2/prolificid.text
	if id.length() != 24:
		$CenterContainer/VBoxContainer/HBoxContainer3/CenterContainer2.visible = true
		return false
	
	$CenterContainer/VBoxContainer/HBoxContainer3/CenterContainer2.visible = false
	return true

func _on_Button_pressed(): 	
	var file = File.new()
#	print("erfger")
#	if Ledit1.text == '' or Ledit2.text == '':
#		player_name = 'Anonymous'
#	else:
#		player_name = Ledit1.text + " " + Ledit2.text
	
	var text_data = prolific_id.text  + "," + Obutton1.get_item_text(Obutton1.selected) + "," + Ledit3.text + "," + Obutton2.get_item_text(Obutton2.selected) + "," + Obutton3.get_item_text(Obutton3.selected) + "\n"
	
	# Append text_data to the list
	text_data_list.append(text_data)
	
	# Emit signal with the updated list
	emit_signal("infocollected", text_data_list)
	
	continue_button_audio.play()
	
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	emit_signal("export_file_path", file_path)
	
	visible = false

	

func _on_Button2_pressed():
	
	#validate
	var gender = $CenterContainer/VBoxContainer/HBoxContainer2/Gender.selected
	var q1 = $CenterContainer/VBoxContainer/Q1/Know.selected
	var q2 = $CenterContainer/VBoxContainer/Q2/Know2.selected
	var prolific_id = $CenterContainer/VBoxContainer/HBoxContainer2/prolificid.text
	var age = $CenterContainer/VBoxContainer/HBoxContainer2/Age.text
	
	if prolific_id.strip_edges() == "" or age.strip_edges() == "" or gender == 0 or q1 == 0 or q2 == 0:
		continue_button.disabled = true
		$complete_form.visible = true
	
	else:
		
		$complete_form.visible = false
		continue_button.disabled = false
		
		var text_data = prolific_id  + "," + Obutton1.get_item_text(Obutton1.selected) + "," + Ledit3.text + "," + Obutton2.get_item_text(Obutton2.selected) + "," + Obutton3.get_item_text(Obutton3.selected) + "\n"
		
		# Append text_data to the list
		text_data_list.append(text_data)
		
		# Emit signal with the updated list
		emit_signal("infocollected", text_data_list)
		print(text_data_list)
		
		continue_button_audio.play()
		
		$Tween.remove_all()
		$Tween.interpolate_property(self, "modulate:a", null, 0.0, 0.5, Tween.TRANS_QUART, Tween.EASE_IN)
		$Tween.start()
		yield($Tween, "tween_all_completed")
		emit_signal("export_file_path", file_path)
		
		visible = false


func _on_prolificid_focus_exited():
	validate()
	


func _on_Age_focus_exited():
	_on_Age_text_entered()
