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
	"""Configura la detección del player usando RayCasting balanceado"""
	
	print("🔧 Configurando detección balanceada del player con RayCast...")
	
	# Crear 3 RayCast2D estratégicamente posicionados
	for i in range(3):  # 3 rayos: izquierda, centro, derecha
		var raycast = RayCast2D.new()
		raycast.name = "PlayerRay" + str(i)
		add_child(raycast)
		
		# Obtener ancho real de la plataforma
		var platform_width = 64.0  # Ancho por defecto
		if collision_shape.shape is RectangleShape2D:
			platform_width = (collision_shape.shape as RectangleShape2D).size.x
		
		# Posicionar rayos: izquierda (-30%), centro (0%), derecha (+30%)
		var offset_x = (i - 1) * (platform_width * 0.3)
		raycast.position.x = offset_x
		
		# Rayo de altura moderada - ni muy corto ni muy largo
		raycast.target_position = Vector2(0, -25)  # 25 pixels hacia arriba
		
		# PROBAR MÚLTIPLES COLLISION MASKS para encontrar al player
		raycast.collision_mask = 0b11111111  # Todas las layers (255)
		
		raycast.enabled = true
		raycast.force_raycast_update()  # Forzar actualización inmediata
		
		print("   Rayo ", i, " en X:", offset_x, " alcance: 25px, mask: todas las layers")
	
	print("✅ Sistema de RayCast balanceado configurado")

func _physics_process(_delta):
	"""Chequea constantemente si el player está sobre la plataforma"""
	
	# Solo verificar si la plataforma está estable
	if current_state != PlatformState.STABLE:
		return
	
	# Forzar actualización de todos los rayos
	for child in get_children():
		if child.name.begins_with("PlayerRay"):
			var raycast = child as RayCast2D
			raycast.force_raycast_update()
	
	# Verificar si algún rayo detecta al player
	var rays_hitting_player = 0
	var detected_player = null
	var debug_info = []
	
	for child in get_children():
		if child.name.begins_with("PlayerRay"):
			var raycast = child as RayCast2D
			var ray_debug = {
				"name": raycast.name,
				"enabled": raycast.enabled,
				"colliding": raycast.is_colliding(),
				"position": raycast.global_position,
				"target": raycast.global_position + raycast.target_position,
				"mask": raycast.collision_mask
			}
			
			if raycast.is_colliding():
				var collider = raycast.get_collider()
				ray_debug["collider_name"] = collider.name
				ray_debug["collider_groups"] = collider.get_groups()
				ray_debug["collider_layer"] = collider.collision_layer if collider.has_method("set_collision_layer") else "N/A"
				ray_debug["is_player"] = is_player(collider)
				
				# Si es cualquier cuerpo que pueda ser el player, intentar activar
				if is_player(collider) or collider.name.to_lower().contains("player") or collider.is_in_group("player"):
					rays_hitting_player += 1
					detected_player = collider
					print("🎯 ", raycast.name, " HIT POTENTIAL PLAYER: ", collider.name)
			
			debug_info.append(ray_debug)
	
	# Debug cada 60 frames (1 segundo aprox)
	if Engine.get_process_frames() % 60 == 0:
		print("🔍 DEBUG RAYCAST STATUS:")
		for info in debug_info:
			print("  ", info.name, ":")
			print("    Enabled: ", info.enabled)
			print("    Colliding: ", info.colliding)
			if info.has("collider_name"):
				print("    Collider: ", info.collider_name)
				print("    Groups: ", info.collider_groups)
				print("    Layer: ", info.collider_layer)
				print("    Is Player: ", info.is_player)
		print("  Total rays hitting player: ", rays_hitting_player)
		print("  ---")
	
	# Solo necesita 1 rayo para activar
	if rays_hitting_player >= 1:
		print("✅ Player detectado por ", rays_hitting_player, " rayo(s) - Activando plataforma")
		activate_platform()

func activate_platform():
	"""Activa la secuencia de rotura de la plataforma"""
	
	print("✅ Activando plataforma - Iniciando countdown de ", break_delay, " segundos")
	
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
