extends KinematicBody
# mouselook + motion based on godot FPS tutorial:
# https://docs.godotengine.org/en/stable/tutorials/3d/fps_tutorial/part_one.html

var vel = Vector3.ZERO
var prev_vel = Vector3.ZERO

const MAX_SPEED = 4
const JUMP_SPEED = 5
const ACCEL = 2.5
const EXTINGUISH_RATE = 0.1
const MIN_SCALE = 0.1

var dir = Vector3()

const DEACCEL= 16

var players_in_range = []
signal player_list_updated
signal fire_putOut
signal show_interface
signal call_robot(target_pos)
signal show_advise

var pickedup_object_original_parent
var pickedup_object
var FireExtinguish = false
var last_location

onready var camera = $Rotation_helper/Camera
onready var rotation_helper = $Rotation_helper
onready var interaction = $Rotation_helper/Camera/RayCast
onready var timer = $Timer
onready var nag = $Control
onready var audio = $Foot_step
#onready var hand = $Rotation_helper/Camera/Position3D

# used by Robot.gd to compute visibility of players
onready var face = $Rotation_helper/Camera

var username = "myself"

var MOUSE_SENSITIVITY = 0.1
# Set Spawnpoint
#onready var spawn_point = $SpawnPoint


var player_id: int = -1

func _ready():
#	if spawn_point:
#		global_transform.origin = spawn_point.global_transform.origin
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	last_location = global_transform.origin
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	timer.connect("timeout", self, "_on_Timer_timeout")
	add_to_group("player")
	
func toggle_collisions(enabled=true):
	$CollisionShape.disabled = !enabled

func _on_Timer_timeout():
	check_interaction_collision()
	
func check_interaction_collision():
	if interaction.is_colliding() and FireExtinguish == true:
		var collider = interaction.get_collider()
		var collider_node = collider.get_parent()
		var put_out = false
		if collider_node.is_in_group("fire_can") or collider_node.is_in_group("fire_training"):
#			if collider_node.scale.x < MIN_SCALE and collider_node.scale.y < MIN_SCALE and collider_node.scale.z < MIN_SCALE:
#				collider_node.visible = false
#			else:
#				collider_node.scale -= Vector3(EXTINGUISH_RATE, EXTINGUISH_RATE, EXTINGUISH_RATE)
			var children_particles = collider_node.get_children()
			for particles in children_particles:
				if particles is Particles:
					if particles.scale.x < MIN_SCALE and particles.scale.y < MIN_SCALE and particles.scale.z < MIN_SCALE:
#						particles.visible = false
						particles.emitting = false
						put_out = true
					else:
						particles.scale -= Vector3(EXTINGUISH_RATE, EXTINGUISH_RATE, EXTINGUISH_RATE)
				elif particles is AudioStreamPlayer3D:
					particles.unit_db -= 0.5
					if put_out == true:
						particles.playing = false
				elif particles is OmniLight:
					if particles.light_energy <= 0.4:
						particles.light_energy <= 0.4
					else:
						particles.light_energy -= 0.3 
					if put_out == true:
						particles.visible = false
				elif particles is StaticBody or Area:
					if put_out == true:
						var collision_shape = particles.get_child(0)
						collision_shape.disabled = true
		
		elif collider_node.is_in_group("fire_cant"):
			emit_signal("show_advise")
			var children_particles = collider_node.get_children()
			for particles in children_particles:
				if particles is Particles:
					if particles.scale.x < 3*MIN_SCALE and particles.scale.y < 3*MIN_SCALE and particles.scale.z < 3*MIN_SCALE:
						pass
					else:
						particles.scale -= Vector3(EXTINGUISH_RATE*0.06, EXTINGUISH_RATE*0.06, EXTINGUISH_RATE*0.06)
				elif particles is AudioStreamPlayer3D:
					particles.unit_db -= 0.1
					if put_out == true:
						particles.playing = false
				elif particles is OmniLight:
					if particles.light_energy <= 0.4:
						particles.light_energy == 0.4
					else:
						particles.light_energy -= 0.05 
					if put_out == true:
						particles.visible = false
				elif particles is StaticBody or Area:
					if put_out == true:
						var collision_shape = particles.get_child(0)
						collision_shape.disabled = true
			
		
		if put_out == true and collider_node.is_in_group("fire_can"):
#			emit_signal("show_interface")
			emit_signal("fire_putOut")


puppet func set_puppet_transform(puppet_transform):

	transform = puppet_transform
	
func _physics_process(delta):
	
	process_input(delta)
	process_movement(delta)
	
	# version that also communicate the gaze direction -- not working because
	# puppet head pose overridden by animation
	#rpc_unreliable("set_puppet_transform", transform, $Rotation_helper/CameraTarget.get_global_transform().origin)

puppet func puppet_says(_msg):
	# do nothing on the player itself! (but the other players, eg, the Characters will display the speech bubble)
	pass

puppet func puppet_set_expression(_msg):
	# do nothing on the player itself! (but the other players, eg, the Characters will display the right expression)
	pass

puppet func puppet_update_players_in_range(in_range, not_in_range):
	
	if in_range.empty() and not_in_range.empty():
		return
	
	for agent in in_range:
		var id = agent[0]
		var type = agent[1]
		if type == "player":
			var player = get_node("/root/Game/Players/" + id)
			players_in_range.append(player)
		else:
			var robot = get_node("/root/Game/Robots/" + id)
			players_in_range.append(robot)
	for agent in not_in_range:
		var id = agent[0]
		var type = agent[1]
		if type == "player":
			var player = get_node("/root/Game/Players/" + id)
			players_in_range.erase(player)
		else:
			var robot = get_node("/root/Game/Robots/" + id)
			players_in_range.erase(robot)
	
	# connected to Chat UI in Game.gd
	emit_signal("player_list_updated", players_in_range)

func is_in_range(agent):
	return agent in players_in_range

#func pick_object():
#	var collider = interaction.get_collider()
#	if collider != null and collider is RigidBody:
#		print("Colliding")
#		picked_object = collider

# connect to the Chat UI 'on_chat_msg' signal in Game.gd
func say(msg):
	
	if GameState.mode != GameState.STANDALONE:
		rpc_id(1, "execute_puppet_says", msg)
	
	# TODO: if *another* character is speaking next to a robot,
	# the robot in my game instance won't be notified!
	# -> robots can not hear remote players
	for agent in players_in_range:
		if agent.has_method("heard"):
			agent.heard(msg, username)
		

# connect to the Chat UI 'on_chat_msg' signal in Game.gd
func typing():
	
	if GameState.mode != GameState.STANDALONE:
		rpc_id(1, "execute_puppet_typing")

puppet func puppet_typing():
	# do nothing on the player itself! (but the other players, eg, the Characters will display the speech bubble)
	pass

# connect to the Chat UI 'on_chat_msg' signal in Game.gd
func not_typing_anymore():
	
	if GameState.mode != GameState.STANDALONE:
		rpc_id(1, "execute_puppet_not_typing_anymore")

puppet func puppet_not_typing_anymore():
	# do nothing on the player itself! (but the other players, eg, the Characters will display the speech bubble)
	pass

# connect to the UI 'on_set_expr' signal in Game.gd
func set_expression(expr):
	
	if GameState.mode != GameState.STANDALONE:
		rpc_id(1, "execute_puppet_set_expression", expr)

func pickup_object(object):
	pass
#
#	# already holding an object?
#	if pickedup_object:
#		return
#
#	if GameState.mode != GameState.STANDALONE:
#		rpc("pickup_object", str(object.get_path()))
#
#	pickedup_object = object
#
#	pickedup_object_original_parent = object.get_parent()
#	pickedup_object_original_parent.remove_child(object)
#
#	$Rotation_helper/Camera/PickupAnchor.add_child(object)
#	object.set_picked()
#
#	object.transform = Transform() # set the object transform to 0 -> origin matches the anchor point


func release_object():
	
	if pickedup_object:
		
		if GameState.mode != GameState.STANDALONE:
			rpc("release_object")
		
		$Rotation_helper/Camera/PickupAnchor.remove_child(pickedup_object)
		pickedup_object_original_parent.add_child(pickedup_object)
		pickedup_object.set_global_transform($Rotation_helper/Camera/PickupAnchor.get_global_transform())
		pickedup_object.set_released()
		pickedup_object = null

# used to test in Game whether an object colliding with the ray cast for visibility testing
# is indeed a character (via .has_method(i_am_a_character))
func i_am_a_character():
	pass
	
	
# returns true if the player is facing 'point' (in global coordinates)
func is_facing(point):
	var local_point = point - global_transform.origin
	var gaze = Vector3(0,0,1).rotated(Vector3(0,1,0), rotation.y)
	return local_point.dot(gaze) > 0
	

func process_input(_delta):

	# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("ui_up"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("ui_down"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("ui_left"):
		input_movement_vector.x -= 1
		#self.rotate_y(deg2rad(1))
	if Input.is_action_pressed("ui_right"):
		input_movement_vector.x += 1
		#self.rotate_y(deg2rad(-1))

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x

	# ----------------------------------

	# ----------------------------------
	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("ui_jump"):
			vel.y = JUMP_SPEED
	# ----------------------------------

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()

	vel.y = 0 # -> gravity managed by the server in Character._process_physics

	var hvel = vel
	hvel.y = 0

	var target = dir
	target *= MAX_SPEED

	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	
	if vel != prev_vel:
		if GameState.mode == GameState.CLIENT:
			# execute the actual motion on the server, so that physics are computed
			# the resulting new position will be updated by the server via 'set_puppet_transform'
			rpc_unreliable_id(1, "execute_move_and_slide", vel)
		elif GameState.mode == GameState.STANDALONE:
			vel.y += GameState.GRAVITY * delta
			vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, GameState.MAX_SLOPE_ANGLE)
		else:
			assert(false)
	
	prev_vel = vel

func _tp(pos, rot):
	self.global_transform.origin = pos
	self.global_transform.basis = rot
	
	

func _input(event):
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
		
		if GameState.mode == GameState.CLIENT:
			rpc_unreliable_id(1, "execute_set_rotation", deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		elif GameState.mode == GameState.STANDALONE:
			self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		else:
			assert(false)
			
		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -20, 30)
		rotation_helper.rotation_degrees = camera_rot
		
	if Input.is_action_pressed("fireextinguisher"):
		FireExtinguish = true
	elif event.is_action_released ("fireextinguisher"):
		FireExtinguish = false

	# trying to workaround HTML5 security:
	# MOUSE_MODE_CAPTURED can *only* take place during an 'actual' event (eg
	# a click, but not a motion)
	# Therefore, if waiting *one frame* to change to mouselook (as done for non-HTML5
	# platform), the mouselook won't trigger as it will take place during a 'mouse motion'
	# event.
	#
	# The original reason for waiting one frame is to ensure the click events are
	# properly register, eg to pickup objects. However, it seems to work in HTML5
	# without waiting...
	if event.is_action_pressed("CallForHelp"):
		emit_signal("call_robot", self.global_transform.origin)
	
	if OS.get_name() == "HTML5":
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED and \
		Input.is_action_pressed("mouselook"):
				print("Capturing mouse")
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED and \
		not Input.is_action_just_pressed("mouselook") and \
		Input.is_action_pressed("mouselook"):
				print("Capturing mouse")
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and \
	   event.is_action_released("mouselook"):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			release_object()

