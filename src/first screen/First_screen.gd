extends Control


onready var en_btn = $HBoxContainer/UK
onready var cs_btn = $HBoxContainer/CS


func set_language_and_start(lang:String):
	GlobalSettings.set_language(lang)
	get_tree().change_scene("res://src/main.tscn")

func _on_UK_pressed():
	set_language_and_start("en")


func _on_CS_pressed():
	set_language_and_start("cs")


func _on_ES_pressed():
	set_language_and_start("es")
