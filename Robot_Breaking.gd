extends Spatial
	
var after_breaking = false
var velocity = Vector3.ZERO
var wait_breaking = 9.0
var step = 1
var path
var restRtarget_executed = false
var letsGetout_executed = false
var letsGetout2_executed = false
var morefire_executed = false
var target_pos
var target_rot
var cur_path_idx = 0
var threshold = .1

var good_visible = false
var bad_visible = false
var good_nonvisible = false
var bad_nonvisible = false

signal show_interface

onready var Robot_node = get_node("/root/Game/RobotPath/PathFollow/Robot")
onready var EmerP = get_node("/root/Game/EmergencyPoint")
onready var nav_node = get_node("/root/Game/Navigation")
onready var UI_node = get_node("/root/Game/CanvasLayer/UI")
onready var Restroom = get_node("/root/Game/FireGroup/Restroom")
onready var CheckPoint = get_node("/root/Game/CheckPoint")
onready var fireinkitchen = get_node("/root/Game/FireInKitchen")
onready var NPC = get_node("/root/Game/S2_NPC/NPC1")	
onready var Fg = $"../../../../FireGroup_after"
	
func _process(delta):
	
	if Robot_node.breaking and not after_breaking:
		if Robot_node.count == 0:
			print("breaking")
			Robot_node.smoke.emitting = false
			Robot_node.smoke_audio.stop()
			Robot_node.on_it_way = false
			Robot_node.called = false
			Robot_node.fire_putOut = false
			Robot_node.speed = 2.0
			Robot_node.count += 1
			emit_signal("show_interface")			# After fire in Warehouse
			Robot_node.path = nav_node.get_simple_path(self.global_transform.origin, EmerP.global_transform.origin)
			print("count:" ,Robot_node.count)
			
#		elif good_visible:
#			#change
#			if Robot_node.path.size() > 0:
#				Robot_node.move_to_target(delta)
#			elif Robot_node.path.size() == 0:
#				if Robot_node.count == 1 and Restroom.is_in == true:
#					print("2")
#	#				yield(get_tree().create_timer(wait_breaking), "timeout")
#					after_breaking = true	
#					Robot_node.count += 1
					
		else:
#			if path.size() == 0:  # Ensure path is recalculated if empty
#				path = nav_node.get_simple_path(self.global_transform.origin, EmerP.global_transform.origin)
			if Robot_node.path.size() > 0:
				Robot_node.move_to_target(delta)
			elif Robot_node.path.size() == 0:
				if Robot_node.count == 1 and Restroom.is_in == true:
					#add 
					print("2")
	#				yield(get_tree().create_timer(wait_breaking), "timeout")
					after_breaking = true	
					Robot_node.count += 1
	
	elif Robot_node.breaking and after_breaking:
#		print("after breaking", after_breaking)
#		print(Robot_node.fire_putOut)
		match step:
			1:		#The robot back to restroom and put out fire
				Robot_node.speed = 2.0
				if Robot_node.count == 2 and not restRtarget_executed:
					Robot_node.count += 1
					get_restR_target()
					print("executed.1", Robot_node.count)
				elif restRtarget_executed:
					if Robot_node.path.size() > 0:
						Robot_node.move_to_target(delta)
					else:
						if Robot_node.target_rotation != null:
							Robot_node.rotate_to_target_rotation(delta)
						UI_node.reached_target()
		#				yield(get_tree().create_timer(2.0), "timeout")
						cur_path_idx = 0
			#			yield(get_tree().create_timer(wait_time), "timeout")
						if Restroom.all_putOut():
							Robot_node.smoke.emitting = false
							Robot_node.smoke_audio.stop()
							UI_node.lets_getout()
							yield(get_tree().create_timer(Robot_node.wait_time*0.5), "timeout")
							Robot_node.on_it_way = false
							Robot_node.called = false
							Robot_node.fire_putOut = false
							step = 2
						else:
							Robot_node.smoke.emitting = true
							Robot_node.smoke_audio.play()
#						else:
#							if Robot_node.in_area == 2:
#								UI_node.show_cant_help()
#			#				yield(get_tree().create_timer(wait_time), "timeout")
#							elif Robot_node.in_area == 0:
#								UI_node.show_nofire()
#								yield(get_tree().create_timer(Robot_node.wait_time), "timeout")
#							Robot_node.on_it_way = false
#							Robot_node.called = false			
				else:
					pass
#			
			2:
				if not letsGetout_executed:
					lets_get_out()
					letsGetout_executed = true
					print("executed.2")
					NPC.go_npc2()
				else:
					if Robot_node.path.size() > 0:
						Robot_node.move_to_target(delta)
					else:
						if Robot_node.target_rotation != null:
							Robot_node.rotate_to_target_rotation(delta)
		#				yield(get_tree().create_timer(2.0), "timeout")
						cur_path_idx = 0
						UI_node.show_cant_putout()
						if fireinkitchen.get_node("fire/flames").emitting == false:
							step = 3
							emit_signal("show_interface")
							Robot_node.called = false
							Robot_node.fire_putOut = false
							
			3:
				if not morefire_executed:
					UI_node.more_fire()
					morefire_executed = true
					Fg.stage3()
					print("executed.2")
				else:
					if Robot_node.called:
						Robot_node.speed = 2.0
						if Robot_node.path.size() > 0:
							Robot_node.move_to_target(delta)
						else:
							if Robot_node.target_rotation != null:
								Robot_node.rotate_to_target_rotation(delta)
							UI_node.reached_target()
			#				yield(get_tree().create_timer(2.0), "timeout")
							cur_path_idx = 0
				#			yield(get_tree().create_timer(wait_time), "timeout")
							if Robot_node.in_area == 1:
								if Robot_node.fire_putOut:
									Robot_node.smoke.emitting = false
									Robot_node.smoke_audio.stop()
									UI_node.show_good_job()
									yield(get_tree().create_timer(Robot_node.wait_time*0.5), "timeout")
									Robot_node.on_it_way = false
									Robot_node.called = false
									Robot_node.fire_putOut = false
								else:
									Robot_node.smoke.emitting = true
									Robot_node.smoke_audio.play()
							else:
								if Robot_node.in_area == 2:
									UI_node.show_cant_help()
				#				yield(get_tree().create_timer(wait_time), "timeout")
								elif Robot_node.in_area == 0:
									UI_node.show_nofire()
									yield(get_tree().create_timer(Robot_node.wait_time), "timeout")
								Robot_node.on_it_way = false
								Robot_node.called = false
								
				if UI_node.fire_putout == 15:
					step = 4
					print("goto 4")

			4:
				if not letsGetout2_executed:
					lets_get_out2()
					letsGetout2_executed = true
					print("executed.4")
				else:
					UI_node.lets_getout()
					if Robot_node.path.size() > 0:
						Robot_node.move_to_target(delta)
					else:
						if Robot_node.target_rotation != null:
							Robot_node.rotate_to_target_rotation(delta)
		#				yield(get_tree().create_timer(2.0), "timeout")
						cur_path_idx = 0
				

func get_restR_target():
	yield(get_tree().create_timer(wait_breaking), "timeout")
	emit_signal("show_interface")
	restRtarget_executed = true
	NPC.go_npc1()
	target_pos = Restroom.get_node("RobotStop").global_transform.origin
	target_rot = Restroom.get_node("RobotStop").global_transform.basis.orthonormalized()
	Robot_node.path = nav_node.get_simple_path(self.global_transform.origin, target_pos)
#	print(path.size())
	
func lets_get_out():
	emit_signal("show_interface")
	print("3")
	UI_node.breaking_stage2()
#	UI_node.lets_getout()
	target_pos = fireinkitchen.get_node("RobotStop").global_transform.origin
	target_rot = fireinkitchen.get_node("RobotStop").global_transform.basis.orthonormalized()
	Robot_node.path = nav_node.get_simple_path(self.global_transform.origin, target_pos)
	Robot_node.letsgetout()
	fireinkitchen.stage2()


func lets_get_out2():
	yield(get_tree().create_timer(Robot_node.wait_time*1.5), "timeout")
	UI_node.lets_getout()
	target_pos = CheckPoint.get_node("RobotStop").global_transform.origin
	target_rot = CheckPoint.get_node("RobotStop").global_transform.basis.orthonormalized()
	Robot_node.path = nav_node.get_simple_path(self.global_transform.origin, target_pos)
