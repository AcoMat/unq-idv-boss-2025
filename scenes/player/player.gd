extends CharacterBody2D

@export var speed: float = 200.0

# ===================================
# VARIABLES DE SALTO ORIGINALES
# ===================================
@onready var gravity_magnitude : int = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var gravity: float = gravity_magnitude / 5
@export var jump_force: float = 250.0
@export var max_jump_force := 300.0
@export var charge_rate := 500.0
var is_charging_jump := false
var jump_charge := 0.0
var is_control_enabled = true

# ===================================
# SISTEMA DE STAMINA
# ===================================
@export_group("Stamina System")
@export var max_stamina: float = 100.0
@export var stamina_per_jump_charge: float = 20.0      # Stamina por segundo al cargar salto
@export var double_jump_stamina_cost: float = 30.0     # Costo del doble salto
@export var stamina_recovery_rate: float = 25.0        # 🔧 Aumenté la recuperación (era 15.0)
@export var stamina_recovery_delay: float = 0.5        # 🆕 Delay antes de empezar a recuperar
@export var min_stamina_to_jump: float = 10.0          # Mínimo para poder saltar

var current_stamina: float = 100.0
var is_stamina_depleted: bool = false
var time_since_last_stamina_use: float = 0.0           # 🆕 Tiempo desde último uso

# Señales para comunicar con la UI
signal stamina_changed(current: float, maximum: float)
signal stamina_depleted
signal stamina_recovered

# ===================================
# VARIABLES DE DOBLE SALTO
# ===================================
@export_group("Double Jump")
@export var double_jump_enabled: bool = true
@export var double_jump_force: float = 200.0
var can_double_jump: bool = false

# ===================================
# VARIABLES ORIGINALES
# ===================================
@export_range(0.0,1.0) var vel_loss_percentage: float = 0.5
var now_is_falling := false

func _ready():
	add_to_group("player")
	print("Player con sistema de stamina cargado")
	
	# Inicializar stamina
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func is_player() -> bool:
	return true

func _physics_process(delta: float) -> void:
	# Gravedad siempre
	if (!is_on_floor()):
		velocity.y += gravity * delta
	
	# Resetear doble salto al tocar suelo
	if is_on_floor() and not can_double_jump:
		can_double_jump = true
		print("✅ Doble salto disponible")
	
	# Manejar sistema de stamina
	handle_stamina_system(delta)
	
	# Sistema de salto con stamina
	handle_jumping_with_stamina(delta)
	
	# Movimiento horizontal
	handle_horizontal_movement()
	
	# Lógica de colisiones original
	handle_collisions()
	
	# Aplicar movimiento
	move_and_slide()

func handle_stamina_system(delta: float):
	"""Maneja la recuperación y estado de la stamina - CORREGIDO"""
	
	var stamina_before = current_stamina
	var is_using_stamina = is_charging_jump
	
	# NUEVO: También considerar si está en el aire como "usando stamina" (no recupera)
	var is_player_active = is_using_stamina or not is_on_floor() or velocity.length() > 10.0
	
	if is_player_active:
		# Si está activo (saltando, cayendo, moviéndose), resetear el timer
		time_since_last_stamina_use = 0.0
	else:
		# Solo recuperar si está QUIETO en el suelo
		time_since_last_stamina_use += delta
		
		# Solo recuperar después del delay Y si está quieto Y no está llena
		if time_since_last_stamina_use >= stamina_recovery_delay and current_stamina < max_stamina:
			# Recuperación progresiva más rápida si está muy baja
			var recovery_multiplier = 1.0
			if current_stamina < (max_stamina * 0.3):  # Si está por debajo del 30%
				recovery_multiplier = 1.5  # Recupera 50% más rápido
			
			var recovery_amount = stamina_recovery_rate * recovery_multiplier * delta
			current_stamina = min(max_stamina, current_stamina + recovery_amount)
			
			# Debug menos spam - solo cada 10 puntos
			if int(current_stamina) % 10 == 0 and int(stamina_before) != int(current_stamina):
				print("🔋 Recuperando stamina: ", int(current_stamina), "/", int(max_stamina))
	
	# Verificar si se recuperó de estar agotada
	if is_stamina_depleted and current_stamina >= min_stamina_to_jump:
		is_stamina_depleted = false
		stamina_recovered.emit()
		print("💚 Stamina recuperada - puede saltar de nuevo")
	
	# 🔧 ARREGLO: Emitir señal MÁS FRECUENTEMENTE para que la UI se vea suave
	if abs(stamina_before - current_stamina) > 0.1:  # Cambié a 0.1 para más sensibilidad
		stamina_changed.emit(current_stamina, max_stamina)

func handle_jumping_with_stamina(delta: float):
	"""Sistema de salto integrado con stamina - CORREGIDO"""
	
	# ===================================
	# SALTO CARGADO CON STAMINA
	# ===================================
	
	# Verificar si puede iniciar carga de salto
	var can_start_charging = (
		is_on_floor() and 
		not is_charging_jump and 
		current_stamina >= min_stamina_to_jump and 
		not is_stamina_depleted
	)
	
	# Iniciar carga si está en el suelo y tiene stamina
	if Input.is_action_pressed("jump") and can_start_charging:
		print("🔄 Iniciando carga de salto...")
		is_charging_jump = true
		is_control_enabled = false
		jump_charge = jump_force
	
	# Continuar cargando si ya está cargando Y tiene stamina
	if is_charging_jump and Input.is_action_pressed("jump") and is_on_floor():
		# Verificar si tiene stamina para continuar cargando
		if current_stamina > 0:
			jump_charge = min(jump_charge + charge_rate * delta, max_jump_force)
			
			# Consumir stamina al cargar
			var stamina_cost = stamina_per_jump_charge * delta
			current_stamina = max(0, current_stamina - stamina_cost)
			stamina_changed.emit(current_stamina, max_stamina)
			
			# Si se queda sin stamina, FORZAR salto inmediato con la fuerza actual
			if current_stamina <= 0:
				print("⚡ Sin stamina - ejecutando salto con fuerza actual: ", jump_charge)
				is_stamina_depleted = true
				stamina_depleted.emit()
				execute_charged_jump()  # Saltar inmediatamente
				return
		
		# Mantener quieto mientras carga
		velocity.x = 0
	
	# Ejecutar salto cargado al soltar (solo si no se ejecutó por falta de stamina)
	if is_charging_jump and not Input.is_action_pressed("jump"):
		execute_charged_jump()
	
	# ===================================
	# SALTO SIN STAMINA (SALTO DÉBIL)
	# ===================================
	
	# Si intenta saltar sin stamina, dar un saltito muy pequeño
	if Input.is_action_just_pressed("jump") and is_on_floor() and (current_stamina < min_stamina_to_jump or is_stamina_depleted):
		print("😅 Salto débil sin stamina")
		velocity.y = -jump_force * 0.3  # Solo 30% de la fuerza mínima
		can_double_jump = false  # No permitir doble salto
		return
	
	# ===================================
	# DOBLE SALTO CON STAMINA
	# ===================================
	
	if not is_charging_jump and not is_on_floor():
		if Input.is_action_just_pressed("jump") and can_double_jump:
			attempt_double_jump()

func execute_charged_jump():
	"""Ejecuta el salto cargado"""
	print("🚀 Salto ejecutado con fuerza: ", jump_charge)
	
	# Resetear flags
	is_charging_jump = false
	is_control_enabled = true
	
	# Obtener dirección
	var input_vector := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_vector.x = -1
	elif Input.is_action_pressed("move_right"):
		input_vector.x = 1
	
	# Aplicar salto
	velocity.x = input_vector.x * speed
	velocity.y = -jump_charge
	jump_charge = 0.0
	
	# Habilitar doble salto
	can_double_jump = true

func attempt_double_jump():
	"""Intenta realizar doble salto con verificación de stamina"""
	
	# Verificar si tiene suficiente stamina
	if current_stamina < double_jump_stamina_cost:
		print("⚡ Sin stamina para doble salto (necesita ", double_jump_stamina_cost, ", tiene ", current_stamina, ")")
		return
	
	print("🌟 Doble salto ejecutado!")
	
	# Consumir stamina
	current_stamina = max(0, current_stamina - double_jump_stamina_cost)
	time_since_last_stamina_use = 0.0  # 🆕 Resetear timer de recuperación
	stamina_changed.emit(current_stamina, max_stamina)
	
	# Verificar si se agotó
	if current_stamina < min_stamina_to_jump:
		is_stamina_depleted = true
		stamina_depleted.emit()
	
	# Aplicar doble salto
	velocity.y = -double_jump_force
	can_double_jump = false
	
	# Movimiento horizontal
	var input_vector := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_vector.x = -1
	elif Input.is_action_pressed("move_right"):
		input_vector.x = 1
	
	if input_vector.x != 0:
		velocity.x = input_vector.x * speed * 0.8

func handle_horizontal_movement():
	"""Movimiento horizontal"""
	if is_control_enabled and is_on_floor() and not is_charging_jump:
		var input_vector := Vector2.ZERO
		if Input.is_action_pressed("move_left"):
			input_vector.x = -1
		elif Input.is_action_pressed("move_right"):
			input_vector.x = 1
		velocity.x = input_vector.x * speed

func handle_collisions():
	"""Lógica de colisiones original"""
	var was_on_wall: bool = is_on_wall()
	var was_on_air: bool = !is_on_floor()
	var inertia = velocity
	
	if is_on_wall() or is_on_ceiling() and not was_on_wall and !is_control_enabled:
		apply_knockback(inertia, !is_on_ceiling())
	
	# Just landed on floor
	if was_on_air and is_on_floor():
		if now_is_falling:
			velocity = Vector2.ZERO
			print("💥 Hit the ground")
			$FallCooldown.start()
			$Sprite2D.region_rect = Rect2(377,82,29,14)
			now_is_falling = false
		else:
			is_control_enabled = true
	
	# Fell from floor
	if !was_on_air and !is_on_floor() and is_control_enabled:
		now_is_falling = true
		is_control_enabled = false
		velocity.x = inertia.x * vel_loss_percentage

func apply_knockback(inertia: Vector2, change_direction: bool):
	now_is_falling = true
	if(change_direction):
		velocity.x = inertia.x * -1 * vel_loss_percentage
	else:
		velocity.x = inertia.x * vel_loss_percentage
	$KnockDownCooldown.start()

func _on_fall_cooldown_timeout() -> void:
	is_control_enabled = true
	$Sprite2D.region_rect = Rect2(234,22,24,26)

# ===================================
# MÉTODOS PÚBLICOS PARA UI
# ===================================

func get_stamina_percentage() -> float:
	"""Retorna porcentaje de stamina (0.0 - 1.0)"""
	return current_stamina / max_stamina

func get_current_stamina() -> float:
	"""Retorna stamina actual"""
	return current_stamina

func get_max_stamina() -> float:
	"""Retorna stamina máxima"""
	return max_stamina

func is_stamina_low() -> bool:
	"""Verifica si la stamina está baja"""
	return current_stamina < (max_stamina * 0.3)

func restore_stamina(amount: float):
	"""Restaura stamina (para power-ups)"""
	current_stamina = min(max_stamina, current_stamina + amount)
	stamina_changed.emit(current_stamina, max_stamina)
	
	if is_stamina_depleted and current_stamina >= min_stamina_to_jump:
		is_stamina_depleted = false
		stamina_recovered.emit()

# ===================================
# DEBUG
# ===================================

func _input(event):
	if event.is_action_pressed("ui_select"):  # Tab
		print("=== STAMINA DEBUG ===")
		print("Current: ", current_stamina, "/", max_stamina)
		print("Percentage: ", get_stamina_percentage() * 100, "%")
		print("Depleted: ", is_stamina_depleted)
		print("Can jump: ", current_stamina >= min_stamina_to_jump)
		print("====================")
