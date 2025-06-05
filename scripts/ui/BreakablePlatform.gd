extends StaticBody2D
class_name BreakablePlatform

# ===================================
# PLATAFORMA SIMPLE QUE DESAPARECE
# ===================================

# Referencias a nodos hijos
@onready var collision_shape = $CollisionShape2D
@onready var sprite = $Sprite2D
@onready var break_timer = $Timer
@onready var audio_player = $AudioStreamPlayer2D

# Estados simples
enum PlatformState {
	STABLE,      # Plataforma normal
	WARNING,     # Player está encima, va a desaparecer
	GONE         # Plataforma desaparecida para siempre
}

# Variables de configuración
@export var break_delay: float = 2.0           # Tiempo antes de desaparecer
@export var warning_effect: bool = true        # Activar efecto visual de advertencia

# Variables de estado
var current_state: PlatformState = PlatformState.STABLE
var original_color: Color
var shake_tween: Tween

# Señales opcionales
signal platform_breaking(platform: BreakablePlatform)
signal platform_gone(platform: BreakablePlatform)

func _ready():
	"""Inicialización de la plataforma"""
	print("BreakablePlatform simple inicializada")
	
	# Verificar el Timer ANTES de configurarlo
	print("🔍 Estado inicial del Timer:")
	print("  - Autostart: ", break_timer.autostart)
	print("  - Wait time: ", break_timer.wait_time)
	print("  - Is stopped: ", break_timer.is_stopped())
	
	# FORZAR configuración del timer
	break_timer.stop()  # Detener si estaba corriendo
	break_timer.wait_time = break_delay
	break_timer.one_shot = true
	break_timer.autostart = false  # FORZAR que no se inicie solo
	
	# Verificar después de configurar
	print("🔧 Después de configurar:")
	print("  - Autostart: ", break_timer.autostart)
	print("  - Is stopped: ", break_timer.is_stopped())
	
	# Desconectar cualquier conexión previa y reconectar
	if break_timer.timeout.is_connected(_on_break_timer_timeout):
		break_timer.timeout.disconnect(_on_break_timer_timeout)
	break_timer.timeout.connect(_on_break_timer_timeout)
	
	# Guardar color original para efectos
	if sprite:
		original_color = sprite.modulate
	
	# Configurar área de detección del player
	setup_player_detection()
	
	# Estado inicial
	current_state = PlatformState.STABLE
	
	print("✅ Plataforma lista - esperando al player")

func setup_player_detection():
	"""Configura la detección del player usando Area2D"""
	
	print("🔧 Configurando detección del player...")
	
	# Crear Area2D para detectar al player
	var detection_area = Area2D.new()
	detection_area.name = "PlayerDetection"
	add_child(detection_area)
	
	# Crear CollisionShape2D para el área
	var area_collision = CollisionShape2D.new()
	var detection_shape = RectangleShape2D.new()
	
	if collision_shape.shape is RectangleShape2D:
		var platform_shape = collision_shape.shape as RectangleShape2D
		detection_shape.size = platform_shape.size + Vector2(4, 4)
		print("   Tamaño detección: ", detection_shape.size)
	else:
		detection_shape.size = Vector2(68, 20)
		print("   Tamaño detección (default): ", detection_shape.size)
	
	area_collision.shape = detection_shape
	detection_area.add_child(area_collision)
	
	# Configurar para detectar solo al player
	detection_area.collision_layer = 0
	detection_area.collision_mask = 2
	print("   Collision mask: ", detection_area.collision_mask)
	
	# Conectar señales
	detection_area.body_entered.connect(_on_player_entered)
	
	print("✅ Sistema de detección simple configurado")

func _on_player_entered(body):
	"""Se ejecuta cuando el player toca la plataforma"""
	
	# Verificar que sea el player
	if not is_player(body):
		print("❌ No es el player: ", body.name)
		return
	
	# Solo activar si la plataforma está estable
	if current_state != PlatformState.STABLE:
		print("⚠️ Plataforma ya activada, estado: ", PlatformState.keys()[current_state])
		return
	
	print("✅ Player tocó la plataforma - Iniciando countdown de ", break_delay, " segundos")
	
	# Cambiar estado
	current_state = PlatformState.WARNING
	platform_breaking.emit(self)
	
	# INICIAR EL TIMER MANUALMENTE
	if not break_timer.is_stopped():
		break_timer.stop()  # Por si acaso estaba corriendo
	
	break_timer.start()  # Iniciar countdown
	print("⏰ Timer iniciado - quedan ", break_timer.time_left, " segundos")
	
	# Efectos visuales de advertencia
	if warning_effect:
		start_warning_effects()

func is_player(body) -> bool:
	"""Verifica si el cuerpo es el player"""
	
	# Por grupo
	if body.is_in_group("player"):
		return true
	
	# Por nombre
	if body.name.to_lower() == "player":
		return true
	
	# Por método
	if body.has_method("is_player"):
		return body.is_player()
	
	return false

func start_warning_effects():
	"""Inicia efectos visuales de advertencia"""
	
	if not sprite:
		return
	
	print("🚨 Iniciando efectos de advertencia...")
	
	# Efecto de parpadeo rojo
	create_blink_effect()
	
	# Efecto de temblor
	create_shake_effect()

func create_blink_effect():
	"""Crea efecto de parpadeo cambiando el color"""
	
	var blink_tween = create_tween()
	blink_tween.set_loops()  # Bucle infinito hasta que se rompa
	
	# Alternar entre color original y rojo
	blink_tween.tween_property(sprite, "modulate", Color.RED, 0.2)
	blink_tween.tween_property(sprite, "modulate", original_color, 0.2)

func create_shake_effect():
	"""Crea efecto de temblor en la plataforma"""
	
	if shake_tween:
		shake_tween.kill()
	
	shake_tween = create_tween()
	shake_tween.set_loops()
	
	var original_pos = sprite.position
	var shake_intensity = 2.0
	
	# Movimiento de temblor
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(shake_intensity, 0), 0.05)
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(-shake_intensity, 0), 0.05)
	shake_tween.tween_property(sprite, "position", original_pos, 0.05)

func _on_break_timer_timeout():
	"""Se ejecuta cuando el timer se agota - desaparecer la plataforma"""
	print("🚨 ¡ALERTA! Timer timeout ejecutado")
	print("   Estado actual: ", PlatformState.keys()[current_state])
	print("   ¿Debería estar en WARNING? ", current_state == PlatformState.WARNING)
	
	# Solo proceder si estamos en estado WARNING
	if current_state == PlatformState.WARNING:
		print("💥 ¡Timer agotado legítimamente! Plataforma desapareciendo...")
		disappear_platform()
	else:
		print("⚠️ Timer timeout INESPERADO - Estado: ", PlatformState.keys()[current_state])
		print("   Ignorando timeout...")

func disappear_platform():
	"""Hace desaparecer la plataforma permanentemente"""
	
	# Cambiar estado
	current_state = PlatformState.GONE
	print("🗑️ Estado cambiado a GONE")
	
	# Emitir señal
	platform_gone.emit(self)
	
	# Detener todos los efectos
	stop_warning_effects()
	
	# Efectos de rotura
	create_break_effects()
	
	# Deshabilitar colisión
	collision_shape.disabled = true
	print("🚫 Colisión deshabilitada")
	
	# Ocultar sprite
	if sprite:
		sprite.visible = false
		print("👻 Sprite ocultado")
	
	# Reproducir sonido
	play_break_sound()
	
	print("✅ Plataforma eliminada permanentemente")

func stop_warning_effects():
	"""Detiene todos los efectos de advertencia"""
	
	# Detener tweens activos
	get_tree().create_tween().kill()
	if shake_tween:
		shake_tween.kill()
	
	# Restaurar posición original
	if sprite:
		sprite.position = Vector2.ZERO

func create_break_effects():
	"""Crea efectos visuales de rotura"""
	
	print("🎆 Efectos de rotura activados")
	
	# Crear fragmentos que caen
	create_falling_fragments()

func create_falling_fragments():
	"""Crea fragmentos que caen cuando se rompe"""
	
	# Crear varios fragmentos pequeños
	for i in range(4):
		var fragment = ColorRect.new()
		fragment.size = Vector2(8, 8)
		fragment.color = original_color
		fragment.position = global_position + Vector2(randf_range(-20, 20), randf_range(-10, 10))
		
		# Agregar al parent de la plataforma
		get_parent().add_child(fragment)
		
		# Animación de caída
		var fragment_tween = create_tween()
		var fall_target = fragment.position + Vector2(randf_range(-50, 50), 200)
		
		fragment_tween.parallel().tween_property(fragment, "position", fall_target, 1.0)
		fragment_tween.parallel().tween_property(fragment, "rotation", randf_range(-PI, PI), 1.0)
		fragment_tween.parallel().tween_property(fragment, "modulate", Color.TRANSPARENT, 1.0)
		
		# Eliminar fragmento al terminar
		fragment_tween.tween_callback(fragment.queue_free)

func play_break_sound():
	"""Reproduce sonido de rotura"""
	
	if audio_player:
		# Aquí cargarías tu archivo de sonido
		# audio_player.stream = preload("res://sounds/platform_break.ogg")
		# audio_player.play()
		print("🔊 Sonido de rotura reproducido")

# ===================================
# MÉTODOS PÚBLICOS ÚTILES
# ===================================

func force_disappear():
	"""Fuerza la desaparición inmediata de la plataforma"""
	break_timer.stop()
	disappear_platform()

func is_gone() -> bool:
	"""Verifica si la plataforma ya desapareció"""
	return current_state == PlatformState.GONE

func get_platform_state() -> PlatformState:
	"""Retorna el estado actual de la plataforma"""
	return current_state
