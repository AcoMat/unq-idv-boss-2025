extends Control

func _ready():
	# Inicialmente ocultar el menú
	hide()
	
	# Conectar botones por código (ajusta las rutas según tu escena)
	var resume_btn = get_node("ResumeButton")  # Cambia por tu ruta
	var quit_btn = get_node("QuitButton")      # Cambia por tu ruta
	
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

func resume():
	get_tree().paused = false
	hide()  # Ocultar el menú cuando se reanuda

func pause():
	get_tree().paused = true
	show()  # Mostrar el menú cuando se pausa
	
func testEsc():
	if Input.is_action_just_pressed("esc") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused:  # Corregido: era "paised"
		resume()

func _on_resume_pressed() -> void:
	resume()

func _on_quit_pressed() -> void:
	get_tree().paused = false  # Importante: despausar antes de salir
	get_tree().quit()

func _process(delta):
	testEsc()
