extends Node

const SAVEFILE = "user://SAVEFILE.save"

var game_data = {}

func _ready():
	load_data()

func save_exists():
	var file = File.new()
	return file.file_exists(SAVEFILE)

func load_data():
	print_debug("loading saved data...")
	var file = File.new()
	if not file.file_exists(SAVEFILE):
		print_debug("No save exists, creating defualt one")
		game_data = {
			"first_start":true,
			"language":"en",
			"fullscreen_on": false,
			"resolution":Vector2(ProjectSettings.get_setting("display/window/size/width"),ProjectSettings.get_setting("display/window/size/height")),
#			"display_fps": false,
			"background_color": ProjectSettings.get_setting("rendering/environment/default_clear_color"),
			"vsync_on": true,
			"master_vol": 0.5,
			"music_vol": 0.23,
			"sfx_vol": 0.5,
			"mode": Global.GAME_TYPES.EASY,
			"board":null,
			"unlocked_slots":null,
			"stats":null
		}
		save_data()
	file.open(SAVEFILE, File.READ)
	game_data = file.get_var()
	file.close()
	
func save_data():
	var file = File.new()
	file.open(SAVEFILE, File.WRITE)
	file.store_var(game_data)
	file.close()
