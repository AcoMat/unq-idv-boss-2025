extends Control
@onready var play: Button = $VBoxContainer/Play
@onready var button: AudioStreamPlayer2D = $Button

func _ready() -> void:
	play.pressed.connect(_on_play_pressed)

func sound_and_change_scene(scene_path: String) -> void:
	button.play()
	await button.finished
	get_tree().change_scene_to_file(scene_path)

func _on_play_pressed() -> void:
	button.play()
	await button.finished
	SceneManager.change_scene("res://scenes/cutscenes/intro/intro.tscn")

func _on_options_pressed() -> void:
	await sound_and_change_scene("res://scenes/ui/menus/main_menu/options/options.tscn")

func _on_quit_pressed() -> void:
	button.play()
	await button.finished
	get_tree().quit()
