extends PathFollow

export var speed = 1
var entered_building = false
var call_robot = false
var is_following_path = true
var wait_time = 1.0
signal entered()

func _on_CheckPoint_body_entered(body):
	if body.is_in_group("player"):
		entered_building = true
		print("Entering the building")
	entered_building = true
	emit_signal("entered", true)
	print("Entering the building")
	

func _process(delta):
	if entered_building and not call_robot:
		if is_following_path:
#			set_offset(get_offset() + speed * delta)
			pass
	else:
		if call_robot:
			# 机器人已经被召唤到目标位置，不再跟随路径
#			is_following_path = false
			pass
			# 在此处添加机器人响应召唤的逻辑
			# 例如，你可以更新机器人的位置或停止它的运动

# 这个函数用于处理机器人被召唤的逻辑
func _get_target_path(target_pos):
	call_robot = true
	is_following_path = false
	
func _return_to_path():
	yield(get_tree().create_timer(wait_time), "timeout")
	call_robot = false
	is_following_path = true
