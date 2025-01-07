extends KinematicBody

export var speed = 1.25
signal backed
signal near_to_fire
signal show_interface
onready var smoke = $RobotMesh/smoke
onready var smoke_audio = $RobotMesh/AudioSmoke
onready var engine_audio = $RobotMesh/AudioEngine
onready var Fg = $"../../../FireGroup_after"
onready var Breaking = self.get_node("Breaking")

const EXTINGUISH_RATE = 0.002
const MIN_SCALE = 0.1

var path = []
var stage_fire = 0
var lets_getout =false
var cur_path_idx = 0
var velocity = Vector3.ZERO
var threshold = .1
var nav_node
var UI_node
var EmerP
var FireGroup_node
var last_location
var fire_putOut = false
var wait_time = 2.0
var target_rotation = null
var called = false
var is_waited = false
var in_area = 0
var enter_building = false
var on_it_way = false
var breaking = false	
var count = 0

var good_visible = false
var bad_visible = false
var good_nonvisible = false
var bad_nonvisible = false


func _ready():
	smoke.emitting = false
	last_location = global_transform.origin
	nav_node = get_node("/root/Game/Navigation")
	UI_node = get_node("/root/Game/CanvasLayer/UI")
	FireGroup_node = get_node("/root/Game/FireGroup")
	EmerP = get_node("/root/Game/EmergencyPoint")
	# Calculate initial path to Emergency Point
	path = nav_node.get_simple_path(self.global_transform.origin, EmerP.global_transform.origin)
	
func _physics_process(delta):
#	print(count, ":", called)
#	count += 1
	if global_transform.origin.distance_squared_to(last_location) > 0.001:
		engine_audio.play()
	else:
		engine_audio.stop()
		
	last_location = global_transform.origin

	if enter_building == true and breaking == false:
		if called:
			speed = 2.0
			if path.size() > 0:
				move_to_target(delta)
			else:
				if target_rotation != null:
					rotate_to_target_rotation(delta)
				UI_node.reached_target()
#				yield(get_tree().create_timer(2.0), "timeout")
				cur_path_idx = 0
	#			yield(get_tree().create_timer(wait_time), "timeout")
				if in_area == 1:
					if fire_putOut:
						smoke.emitting = false
						smoke_audio.stop()
						UI_node.show_good_job()
						yield(get_tree().create_timer(wait_time*0.5), "timeout")
						on_it_way = false
						called = false
						fire_putOut = false
					else:
						smoke.emitting = true
						smoke_audio.play()
				else:
					if in_area == 2:
						UI_node.show_cant_help()
	#				yield(get_tree().create_timer(wait_time), "timeout")
					elif in_area == 0:
						UI_node.show_nofire()
						yield(get_tree().create_timer(wait_time), "timeout")
					on_it_way = false
					called = false

		elif not called and not breaking:
			speed = 2.0
			if path.size() == 0:  # Ensure path is recalculated if empty
				path = nav_node.get_simple_path(self.global_transform.origin, EmerP.global_transform.origin)
			if path.size() > 0:
				move_to_target(delta)
			else:
				print("reach")
			
	elif breaking == true:
		pass
		
		
	##needs refactoring
	if smoke.emitting == true:
		for child_area in FireGroup_node.get_children():
			if child_area.is_in == true:
				for child_node in child_area.get_children():
					if child_node.get_name() == 'fire':
						for particles in child_node.get_children():
							if particles is Particles:
								if particles.scale.x < MIN_SCALE and particles.scale.y < MIN_SCALE and particles.scale.z < MIN_SCALE:
			#						particles.visible = false
									pass
								else:
									particles.scale -= Vector3(EXTINGUISH_RATE, EXTINGUISH_RATE, EXTINGUISH_RATE)
							elif particles is AudioStreamPlayer3D:
								particles.unit_db -= 0.02
							elif particles is OmniLight:
								if particles.light_energy <= 0.2:
									particles.light_energy == 0
								else:
									particles.light_energy -= 0.01

			
func _is_fire_putOut():
	fire_putOut = true
	print("Put out")
	if FireGroup_node.get_node("Lounge").is_in == true:
		fire_putOut = false
	elif Fg.get_node("Table").is_in == true:
		fire_putOut = false
		smoke.emitting = false
		smoke_audio.stop()
		UI_node.show_good_job()
		yield(get_tree().create_timer(wait_time*0.5), "timeout")
		on_it_way = false
		called = false
	else:
		stage_fire += 1
		if stage_fire == 2 or stage_fire == 4 or stage_fire == 12:
			emit_signal("show_interface")
	#		pass
		
	var child_fire = FireGroup_node.get_children()
	var condition = true
	for single_fire in child_fire:
		if single_fire.get_node("fire/flames").emitting == true \
		and single_fire.get_name() != "Restroom":
			condition = false
	
	if condition == true:
		yield(get_tree().create_timer(0.5), "timeout")
		breaking = true

func move_to_target(delta):
	if global_transform.origin.distance_to(path[cur_path_idx]) < threshold:
		path.remove(cur_path_idx)
	else:
		var direction = path[cur_path_idx] - global_transform.origin
		direction.y = 0  # Keep moving horizontally
		velocity = direction.normalized() * speed
		if direction.length() > 0:
			look_at(global_transform.origin + direction.rotated(Vector3.UP, PI), Vector3.UP)
		var collision = move_and_collide(velocity * delta)
		if collision:
			velocity = velocity.slide(collision.normal)
			
func _get_target_path(target_position):
	if on_it_way == false and breaking == false and enter_building == true:
		on_it_way = true
		in_area = FireGroup_node.is_in_area()
		if in_area == 1 or in_area == 2:
			target_position = FireGroup_node.target_pos
			target_rotation = FireGroup_node.target_rot.orthonormalized()
		path = nav_node.get_simple_path(global_transform.origin, target_position)
#		print(path)
		called = true
		cur_path_idx = 0

	elif Breaking.morefire_executed == true and on_it_way == false:
		on_it_way = true
		in_area = Fg.is_in_area()
		if in_area == 1 or in_area == 2:
			target_position = Fg.target_pos
			target_rotation = Fg.target_rot.orthonormalized()
		path = nav_node.get_simple_path(global_transform.origin, target_position)
#		print(path)
		called = true
		cur_path_idx = 0

	elif on_it_way == true:
		UI_node.on_my_way()
	

		
	
	
	
	elif breaking == true and lets_getout == false:
#		good_visible = true		
		bad_visible = true
		if Breaking.restRtarget_executed == true:
			pass
			##WIP
			
		elif on_it_way == false and good_nonvisible:
#			on_it_way = true
			UI_node.good_nonvisible_explanation()
			
		elif on_it_way == false and good_visible:
			on_it_way = true
			target_position = Fg.target_pos
			target_rotation = Fg.target_rot.orthonormalized()
			path = nav_node.get_simple_path(global_transform.origin, target_position)
			UI_node.good_visible_explanation()
			
		elif on_it_way == false and bad_nonvisible:
#			on_it_way = true
			UI_node.bad_nonvisible_explanation()
			
		elif on_it_way == false and bad_visible:
			on_it_way = true
			target_position = Fg.target_pos
			target_rotation = Fg.target_rot.orthonormalized()
			path = nav_node.get_simple_path(global_transform.origin, target_position)
			UI_node.bad_visible_explanation()
		else:
			UI_node.in_breaking()
	
#	elif breaking == true and lets_getout == true:
#		UI_node.dangerous()
	
func rotate_to_target_rotation(delta):
	var current_rotation = global_transform.basis.orthonormalized()
	var slerp_factor = min(1.0, delta * speed)  # 旋转速度控制
	var new_rotation = current_rotation.slerp(target_rotation.orthonormalized(), slerp_factor)
	global_transform.basis = new_rotation
	if current_rotation.is_equal_approx(target_rotation):
		target_rotation = null  # 完成旋转后重置初始朝向
		
func _on_CheckPoint_body_entered(body):
	enter_building = true

func letsgetout():
	lets_getout = true
