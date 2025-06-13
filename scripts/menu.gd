extends Control
@onready var play: Button = $VBoxContainer/Play
@onready var button: AudioStreamPlayer2D = $Button

func _ready() -> void:
	play.pressed.connect(_on_play_pressed)

func play_sound_and_change_scene(scene_path: String) -> void:
	button.play()
	await button.finished
	get_tree().change_scene_to_file(scene_path)


func _on_play_pressed() -> void:
	await play_sound_and_change_scene("res://main2.tscn")
	
func _on_options_pressed() -> void:
	await play_sound_and_change_scene("res://scenes/ui/menus/options.tscn")

func _on_quit_pressed() -> void:
	button.play()
	await button.finished
	get_tree().quit()
