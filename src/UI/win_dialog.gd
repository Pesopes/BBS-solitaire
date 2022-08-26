extends WindowDialog

onready var time_val := get_node("%TimeValue")
onready var click_val := get_node("%ClickValue")
onready var mode_val := get_node("%ModeValue")

func format_time(secs)->String:
	var formatted = Time.get_time_string_from_unix_time(secs)
	return formatted

func win_popup(time_start,time_end,clicks,mode):
	time_val.text  = format_time(time_end-time_start)
	click_val.text = str(clicks)
	mode_val.text = str(Global.GAME_TYPES.keys()[mode])
	popup_centered()
