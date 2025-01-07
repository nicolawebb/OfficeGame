extends KinematicBody

export var speed = 1.25
signal backed
signal near_to_fire
signal show_interface
onready var smoke = $RobotMesh/smoke
onready var smoke_audio = $RobotMesh/AudioSmoke
onready var engine_audio = $RobotMesh/AudioEngine

const EXTINGUISH_RATE = 0.002
const MIN_SCALE = 0.1

var end_training = false
var path = []
var fire
var cur_path_idx = 0
var velocity = Vector3.ZERO
var threshold = .1
var nav_node
var UI_node
var stage_2 = false
var TrainArea_node
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

func _ready():
	smoke.emitting = false
	last_location = global_transform.origin
	nav_node = get_node("/root/Game/TrainArea/Scene/Navigation")
	UI_node = get_node("/root/Game/CanvasLayer/UI")
	TrainArea_node = get_node("/root/Game/TrainArea")
	fire = TrainArea_node.get_node("Training2/fire")
	
func _physics_process(delta):
#	print(count, ":", called)
#	count += 1
	if global_transform.origin.distance_squared_to(last_location) > 0.001:
		engine_audio.play()
	else:
		engine_audio.stop()
		
	last_location = global_transform.origin

	if called and not end_training:
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
			if TrainArea_node.is_in and TrainArea_node.robot_is_in:
				if fire_putOut or TrainArea_node.done == 2:
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
				UI_node.show_nofire()
				yield(get_tree().create_timer(wait_time), "timeout")
				on_it_way = false
				called = false
			
	if smoke.emitting == true:
		for particles in fire.get_children():
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

func move_to_target(delta):
#	print(global_transform.origin.distance_to(path[cur_path_idx])-0.5)
	if global_transform.origin.distance_to(path[cur_path_idx]) - 0.5 < threshold:
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
	if not end_training:
		print("called")
		if (on_it_way == false and stage_2 == true):
			on_it_way = true
			if TrainArea_node.is_in:
				target_position = TrainArea_node.target_pos
				target_rotation = TrainArea_node.target_rot.orthonormalized()
			path = nav_node.get_simple_path(global_transform.origin, target_position)
			called = true
			cur_path_idx = 0

		elif on_it_way == true:
			UI_node.on_my_way()
	
func rotate_to_target_rotation(delta):
	var current_rotation = global_transform.basis.orthonormalized()
	var slerp_factor = min(1.0, delta * speed)  # 旋转速度控制
	var new_rotation = current_rotation.slerp(target_rotation.orthonormalized(), slerp_factor)
	global_transform.basis = new_rotation
	if current_rotation.is_equal_approx(target_rotation):
		target_rotation = null  # 完成旋转后重置初始朝向
		
