extends Area2D

#signal drag_end(start_pos,end_pos)
signal mouse_down(target)
signal mouse_up(target)

export (Global.CARD_TYPES) var card_type setget set_type, get_type

# setters and getters
func set_type(new_type):
	card_type = new_type
	set_card_image(new_type)
func get_type():
	return card_type

func set_card_image(type):
	$Sprites.frame = type

func _on_Card_input_event(_viewport, _event, _shape_idx):
	if Input.is_action_just_pressed("LMC"):
		emit_signal("mouse_down",self)
	if Input.is_action_just_released("LMC"):
		emit_signal("mouse_up",self)

func _on_Card_mouse_entered():
#	mouse_over = true
	pass

func _on_Card_mouse_exited():
#	mouse_over = false
	pass

