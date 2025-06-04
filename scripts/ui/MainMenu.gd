extends Control

# Referencias a los botones
@onready var start_button = $CenterContainer/VBoxContainer/ButtonsContainer/StartButton
@onready var options_button = $CenterContainer/VBoxContainer/ButtonsContainer/OptionsButton
@onready var quit_button = $CenterContainer/VBoxContainer/ButtonsContainer/QuitButton

func _ready():
	print("Menú principal cargado")
	
	# Conectar botones
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Focus inicial
	start_button.grab_focus()

func _on_start_pressed():
	print("Botón presionado - Iniciando juego")
	get_tree().change_scene_to_file("res://main.tscn")

func _on_options_pressed():
	print("Abriendo opciones...")
	get_tree().change_scene_to_file("res://scenes/ui/menus/options_menu.tscn")

func _on_quit_pressed():
	print("Saliendo del juego...")
	get_tree().quit()
