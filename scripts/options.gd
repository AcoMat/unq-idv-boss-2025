extends Control
@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/menu.tscn")

func _ready():
	main_buttons.visible = true
	options.visible = false

func _on_volume_pressed() -> void:
	print("volume pressed")
	main_buttons.visible = false
	options.visible = true


func _on_back_opstions_pressed() -> void:
	_ready()
