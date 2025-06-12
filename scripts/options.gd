extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options
@onready var button: AudioStreamPlayer = $Button

func play_sound_and_change_scene(path: String) -> void:
	button.play()
	await button.finished
	get_tree().change_scene_to_file(path)

func _on_back_pressed() -> void:
	play_sound_and_change_scene("res://scenes/ui/menus/menu.tscn")

func _ready():
	main_buttons.visible = true
	options.visible = false

func _on_volume_pressed() -> void:
	button.play()
	await button.finished
	main_buttons.visible = false
	options.visible = true

func _on_back_opstions_pressed() -> void:
	button.play()
	await button.finished
	_ready()
