extends Node2D
@onready var presentacion: Camera2D = $Presentacion
@onready var player: CharacterBody2D = $Player

func _ready():
	# Posicionar cámara arriba del jugador
	presentacion.global_position = Vector2(600.0, player.global_position.y - 1300)
	# Pausar jugador y iniciar intro
	player.set_physics_process(false)
	await get_tree().create_timer(0.5).timeout
	start_intro()
	
func start_intro():
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	# Terminar un poco arriba del jugador
	var final_position = Vector2(player.global_position.x, player.global_position.y - 100)
	tween.tween_property(presentacion, "global_position", final_position, 4.0)
	await tween.finished
	
	# Cambiar a cámaras de nivel
	presentacion.enabled = false
	$MainLevel.cameras[0].enabled = true
	player.set_physics_process(true)
