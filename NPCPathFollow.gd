extends PathFollow

#export(Texture) var skin
#export(String) var npc_name = "Mysterious person"

var SPEED = 7 / 3.6 # in m/s

var next_pause = randf()
var PAUSE_LENGTH=2 #sec
var go_signal1 = false
var go_signal2 = false

var current_pause = -1
onready var npc = $Character

func _ready():
	var skin = "res://assets/characters/skins/businessMaleB_neutral.png"
	var npc_name = "Mysterious person"
	npc.set_base_skin(skin)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

#	if current_pause > 0:
#		current_pause -= delta
#	else:
#		offset += SPEED * delta
	if go_signal1:
		if offset >= 0.0 and offset <= 14.0 and not go_signal2:
			offset += SPEED * delta
			
		elif go_signal2:
			if offset >= 74.8:
				pass
			else:
				offset += SPEED * delta
			
	#	if current_pause < 0 and abs(next_pause - unit_offset) < 0.001:
	#		next_pause = randf()
	#		current_pause = PAUSE_LENGTH
	
#	if unit_offset >= 1:
#		unit_offset = 0

func go_npc1():
	go_signal1 = true

func go_npc2():
	go_signal2 = true
