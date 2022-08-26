extends Node

# Game
func set_mode(mode):
	Save.game_data.mode = mode
	Save.save_data()

func set_language(lang):
	TranslationServer.set_locale(lang)
	Save.game_data.language = lang
	Save.save_data()
# Display
func toggle_fullscreen(val):
	OS.window_fullscreen = val
	Save.game_data.fullscreen_on = val
	Save.save_data()

func update_resolution(val:Vector2):
	OS.set_window_size(val)
	Save.game_data.resolution = val
	Save.save_data()

func toggle_vsync(val):
	OS.vsync_enabled = val
	Save.game_data.vsync_on = val
	Save.save_data()

# Sound
func update_master_volume(vol):
	AudioServer.set_bus_volume_db(0,linear2db(vol))
	Save.game_data.master_vol = vol
	Save.save_data()

func update_music_volume(vol):
	AudioServer.set_bus_volume_db(1,linear2db(vol))
	Save.game_data.music_vol = vol
	Save.save_data()
	

func update_sfx_volume(vol):
	AudioServer.set_bus_volume_db(2,linear2db(vol))
	Save.game_data.sfx_vol = vol
	Save.save_data()


