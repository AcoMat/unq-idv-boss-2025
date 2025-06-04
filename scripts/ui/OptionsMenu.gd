extends Control

@onready var master_slider = $CenterContainer/VBoxContainer/AudioSection/MasterVolumeContainer/MasterSlider
@onready var back_button = $CenterContainer/VBoxContainer/ButtonsContainer/BackButton

func _ready():
	print("Opciones cargadas")
	
	# Conectar controles
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
	
	back_button.pressed.connect(_on_back_pressed)
	
	# Cargar volumen actual
	if master_slider:
		var current_volume = db_to_linear(AudioServer.get_bus_volume_db(0))
		master_slider.value = current_volume
	
	# Focus inicial
	back_button.grab_focus()

func _on_master_volume_changed(value: float):
	"""Cambiar volumen maestro"""
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_back_pressed():
	print("Volviendo al menú principal")
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
