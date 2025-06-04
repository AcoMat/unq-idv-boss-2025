extends Node

# Script para main.tscn
# Controla qué elementos mostrar cuando se carga el juego

@onready var ui = $UI
@onready var player = $Player
@onready var sections = $Sections
@onready var cameras = $Cameras

# Referencias a menús
var main_menu
var pause_menu
var hud

func _ready():
	print("Main scene iniciada - Configurando juego...")
	
	# Buscar elementos de UI
	find_ui_elements()
	
	# Configurar estado inicial del juego
	setup_game_state()
	
	# Mostrar el primer nivel
	show_level(1)

func find_ui_elements():
	"""Encuentra los elementos de UI"""
	if ui:
		main_menu = ui.get_node_or_null("MainMenu")
		pause_menu = ui.get_node_or_null("PauseMenu") 
		hud = ui.get_node_or_null("HUD")
		
		print("UI encontrados:")
		print("- MainMenu: ", main_menu != null)
		print("- PauseMenu: ", pause_menu != null)
		print("- HUD: ", hud != null)

func setup_game_state():
	"""Configura el estado inicial del juego"""
	print("Configurando estado del juego...")
	
	# Ocultar menús
	if main_menu:
		main_menu.visible = false
		print("MainMenu ocultado")
	
	if pause_menu:
		pause_menu.visible = false
		print("PauseMenu ocultado")
		
		# Conectar botones del menú de pausa
		connect_pause_menu_buttons()
	
	# Mostrar HUD del juego
	if hud:
		hud.visible = true
		print("HUD mostrado")
	
	# Activar player
	if player:
		player.visible = true
		player.set_process_mode(Node.PROCESS_MODE_INHERIT)
		print("Player activado")
	
	# Asegurar que no esté pausado
	get_tree().paused = false
	print("Juego despausado")

func connect_pause_menu_buttons():
	"""Conecta los botones del menú de pausa"""
	if not pause_menu:
		return
	
	var resume_button = pause_menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonsContainer/ResumeButton")
	var main_menu_button = pause_menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonsContainer/MainMenuButton")
	
	if resume_button and not resume_button.pressed.is_connected(resume_game):
		resume_button.pressed.connect(resume_game)
		print("ResumeButton conectado")
	
	if main_menu_button and not main_menu_button.pressed.is_connected(go_to_main_menu):
		main_menu_button.pressed.connect(go_to_main_menu)
		print("MainMenuButton conectado")

func go_to_main_menu():
	"""Va al menú principal"""
	print("Volviendo al menú principal...")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")

func show_level(level_number: int):
	"""Muestra un nivel específico"""
	print("Mostrando nivel: ", level_number)
	
	if not sections:
		print("⚠️ Sections no encontrado")
		return
	
	# Ocultar todos los niveles
	for child in sections.get_children():
		child.visible = false
		print("Ocultando: ", child.name)
	
	# Mostrar el nivel solicitado
	var level_name = "Level" + str(level_number)
	var target_level = sections.get_node_or_null(level_name)
	
	if target_level:
		target_level.visible = true
		print("✅ Nivel ", level_number, " activado")
	else:
		print("❌ Nivel no encontrado: ", level_name)
		print("Niveles disponibles:")
		for child in sections.get_children():
			print("  - ", child.name)

func _input(event):
	"""Manejo de input del juego"""
	if event.is_action_pressed("ui_cancel"):
		# ESC para pausar/despausar
		if pause_menu:
			if pause_menu.visible:
				# Si el menú de pausa está visible, resumir juego
				resume_game()
			else:
				# Si no está visible, pausar juego
				pause_game()
		else:
			# Si no hay menú de pausa, ir al menú principal
			print("No hay menú de pausa, volviendo al menú principal...")
			get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
	
	# Debug: cambiar niveles con números
	if Input.is_key_pressed(KEY_1):
		show_level(1)
	elif Input.is_key_pressed(KEY_2):
		show_level(2)
	elif Input.is_key_pressed(KEY_3):
		show_level(3)

func pause_game():
	"""Pausa el juego y muestra el menú de pausa"""
	if pause_menu:
		print("Pausando juego...")
		get_tree().paused = true
		pause_menu.visible = true
		pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func resume_game():
	"""Reanuda el juego y oculta el menú de pausa"""
	if pause_menu:
		print("Reanudando juego...")
		get_tree().paused = false
		pause_menu.visible = false
