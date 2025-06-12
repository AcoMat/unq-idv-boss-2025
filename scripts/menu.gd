extends Control
@onready var play: Button = $VBoxContainer/Play
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	play.pressed.connect(_on_play_pressed)

func play_sound_and_change_scene(scene_path: String) -> void:
	audio_stream_player.play()
	await audio_stream_player.finished
	get_tree().change_scene_to_file(scene_path)


func _on_play_pressed() -> void:
	await play_sound_and_change_scene("res://scenes/levels/main/main_level.tscn")
	
func _on_options_pressed() -> void:
	await play_sound_and_change_scene("res://scenes/ui/menus/options.tscn")

func _on_quit_pressed() -> void:
	audio_stream_player.play()
	await audio_stream_player.finished
	get_tree().quit()


func _on_tutorial_pressed() -> void:
	print("tutorial tocado")
	await play_sound_and_change_scene("res://main2.tscn")
