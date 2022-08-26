extends Area2D

export var index := 0
export var closed := false

signal mouse_down(target)
signal mouse_up(target)


func _on_Empty_space_input_event(_viewport, _event, _shape_idx):
	if Input.is_action_just_pressed("LMC"):
		emit_signal("mouse_down",self)
	if Input.is_action_just_released("LMC"):
		emit_signal("mouse_up",self)
