extends Popup

# Language
onready var lang_btn := get_node("%LangBtn")

# Game
onready var mode_btn := get_node("%ModeBtn")

# Display
onready var fullscreen_btn := get_node("%FullscreenBtn")
onready var resolution_btn := get_node("%ResolutionBtn")
onready var vsync_btn := get_node("%VsyncBtn")
#Sound
onready var master_slider := get_node("%MasterSlider")
onready var music_slider := get_node("%MusicSlider")
onready var sfx_slider := get_node("%SfxSlider")

func _ready():
	print_debug(Save.game_data)
	mode_btn.selected = Save.game_data.mode

	#bad but I want to finish this
	match Save.game_data.language:
		"en":
			lang_btn.selected = 0 
		"cs":
			lang_btn.selected = 1
	GlobalSettings.set_language(Save.game_data.language)

	fullscreen_btn.pressed = Save.game_data.fullscreen_on
	GlobalSettings.toggle_fullscreen(Save.game_data.fullscreen_on)
	vsync_btn.pressed = Save.game_data.vsync_on
	GlobalSettings.toggle_vsync(Save.game_data.vsync_on)
	
	master_slider.value = Save.game_data.master_vol*100
	GlobalSettings.update_master_volume(Save.game_data.master_vol)
	music_slider.value = Save.game_data.music_vol*100
	GlobalSettings.update_music_volume(Save.game_data.music_vol)
	sfx_slider.value = Save.game_data.sfx_vol*100
	GlobalSettings.update_sfx_volume(Save.game_data.sfx_vol)	

func enable_popup(duration:float=1.0):
	popup()
	#in animation
	var defualt_margin_top = margin_top
	margin_top = -1000
	modulate.a = 0.0
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self,"modulate:a",1.0,duration)
	tween.parallel().tween_property(self,"margin_top",defualt_margin_top,duration)


func _on_FullscreenBtn_toggled(button_pressed):
	GlobalSettings.toggle_fullscreen(button_pressed)

#func convert_volume(vol)->float:
#	return linear2db(vol/100)
#
#func convert_db(db)->float:
#	return db2linear(db)*100

func _on_MasterSlider_value_changed(value):
	GlobalSettings.update_master_volume(value/100)

func _on_MusicSlider_value_changed(value):
	GlobalSettings.update_music_volume(value/100)

func _on_SfxSlider_value_changed(value):
	GlobalSettings.update_sfx_volume(value/100)


func _on_ResolutionBtn_item_selected(_index):
	var text:String= resolution_btn.text
	var values := text.split_floats("x")
	GlobalSettings.update_resolution(Vector2(values[0],values[1]))


func _on_VsyncBtn_toggled(button_pressed):
	GlobalSettings.toggle_vsync(button_pressed)


func _on_ModeBtn_item_selected(index):
	# I can't find a way to index enums
	var mode = Global.GAME_TYPES.EASY
	match index:
		0:
			mode = Global.GAME_TYPES.EASY
		1:
			mode = Global.GAME_TYPES.MEDIUM
		2:
			mode = Global.GAME_TYPES.HARD
		3:
			mode = Global.GAME_TYPES.EXPERT
	GlobalSettings.set_mode(mode)


func _on_LangBtn_item_selected(index):
	var lang = "en"
	match index:
		0:
			lang = "en"
		1:
			lang = "cs"
	GlobalSettings.set_language(lang)
