extends Control

func _ready():
	# Ocultar el menú al inicio
	visible = false

func resume():
	get_tree().paused = false
	visible = false  # Ocultar el menú

func pause():
	get_tree().paused = true
	visible = true   # Mostrar el menú

func testEsc():
	if Input.is_action_just_pressed("esc") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused:
		resume()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_resume_button_pressed() -> void:
	resume()  # Usar tu función resume() en lugar de reload_current_scene()

func _process(delta):
	testEsc()
