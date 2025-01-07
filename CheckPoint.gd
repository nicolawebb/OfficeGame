extends Area

var all_putout = false
signal game_over

func _on_CheckPoint_body_entered(body):
	if all_putout == true and body.is_in_group("player"):
		emit_signal("game_over")


func _on_UI_all_putOut():
	all_putout = true
