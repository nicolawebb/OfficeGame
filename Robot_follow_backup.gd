#extends KinematicBody
#
#export var speed = 2.5	
#signal backed
#signal near_to_fire
#onready var smoke = $RobotMesh/smoke
#onready var smoke_audio = $RobotMesh/AudioStreamPlayer3D
#
#var path = []
#var cur_path_idx = 0
#var velocity = Vector3.ZERO
#var threshold = .1
#var return_path = []
#var nav_node
#var UI_node
#var FireGroup_node
#var fire_putOut = false
#var wait_time = 2.0
#var initial_rotation = null
#var target_rotation = null
#var called = false
#var is_waited = false
#var in_area = 0
#var on_it_way = false
#var count = 0
#
#func _ready():
#	smoke.emitting = false
#	nav_node = get_node("/root/Game/Navigation")
#	UI_node = get_node("/root/Game/CanvasLayer/UI")
#	FireGroup_node = get_node("/root/Game/FireGroup")
#
#func _physics_process(delta):
#	if called and not is_waited:
#		if path.size() > 0:
#			move_to_target(delta)
#		else:
#			if target_rotation != null:
#				rotate_to_target_rotation(delta)
#			UI_node.reached_target()
#			cur_path_idx = 0
#			yield(get_tree().create_timer(wait_time), "timeout")
#			if in_area == 1:
#				if fire_putOut:
#					smoke.emitting = false
#					smoke_audio.stop()
#					UI_node.show_good_job()
#					yield(get_tree().create_timer(wait_time), "timeout")
#					is_waited = true
#					on_it_way = false
#				else:
#					smoke.emitting = true
#					smoke_audio.play()
#			else:
#				if in_area == 2:
#					UI_node.show_cant_help()
#				yield(get_tree().create_timer(wait_time), "timeout")
#				is_waited = true	
#				on_it_way = false
#
#	elif is_waited:
#
#		if return_path.size() > 0:
#			move_to_return(delta)
#		else:
#			is_waited = false
#			called = false
#			if initial_rotation != null:
#				rotate_to_initial_rotation(delta)
#				# Ensure keep rotating until rotation is complete
#				while not global_transform.basis.is_equal_approx(initial_rotation):
#					yield(get_tree(), "idle_frame")
#					rotate_to_initial_rotation(delta)
#			emit_signal("backed")
#
#			fire_putOut = false
#
#func _is_fire_putOut():
#	fire_putOut = true
#
#func move_to_target(delta):
#	if global_transform.origin.distance_to(path[cur_path_idx]) < threshold:
#		path.remove(cur_path_idx)
#	else:
#		var direction = path[cur_path_idx] - global_transform.origin
#		direction.y = 0  # Keep moving horizontally
#		velocity = direction.normalized() * speed
#		if direction.length() > 0:
#			look_at(global_transform.origin + direction.rotated(Vector3.UP, PI), Vector3.UP)
#		var collision = move_and_collide(velocity * delta)
#		if collision:
#			velocity = velocity.slide(collision.normal)
#
#func move_to_return(delta):
#	if global_transform.origin.distance_to(return_path[cur_path_idx]) < threshold:
#		return_path.remove(cur_path_idx)
#	else:
#		var direction = return_path[cur_path_idx] - global_transform.origin
#		direction.y = 0  # Keep moving horizontally
#		velocity = direction.normalized() * speed
#		if direction.length() > 0:
#			look_at(global_transform.origin + direction.rotated(Vector3.UP, PI), Vector3.UP)
#		var collision = move_and_collide(velocity * delta)
#		if collision:
#			velocity = velocity.slide(collision.normal)
#
#func _get_target_path(target_position):
#	if on_it_way == false:
#		on_it_way = true
#		in_area = FireGroup_node.is_in_area()
##		print(in_area)
##		print(target_position)
#		if in_area == 1 or in_area == 2:
#			target_position = FireGroup_node.target_pos
#			target_rotation = FireGroup_node.target_rot.orthonormalized()
#		initial_rotation = global_transform.basis.orthonormalized()
##		print(target_position)
#		path = nav_node.get_simple_path(global_transform.origin, target_position)
#		called = true
#		is_waited = false
#		cur_path_idx = 0
#		return_path = nav_node.get_simple_path(target_position, global_transform.origin)
#	else:
#		UI_node.on_my_way()
#
#func rotate_to_target_rotation(delta):
#	var current_rotation = global_transform.basis.orthonormalized()
#	var slerp_factor = min(1.0, delta * speed)  # 旋转速度控制
#	var new_rotation = current_rotation.slerp(target_rotation.orthonormalized(), slerp_factor)
#	global_transform.basis = new_rotation
#	if current_rotation.is_equal_approx(target_rotation):
#		target_rotation = null  # 完成旋转后重置初始朝向
#
#func rotate_to_initial_rotation(delta):
#	var current_rotation = global_transform.basis.orthonormalized()
#	var slerp_factor = min(1.0, delta * speed)  # 旋转速度控制
#	var new_rotation = current_rotation.slerp(initial_rotation.orthonormalized(), slerp_factor)
#	global_transform.basis = new_rotation
