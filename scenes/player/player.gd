extends CharacterBody2D

var lifes = 3
# Pj movement
@export var speed: float = 200.0
# Pj weapon
var equipped_weapon: Node2D = null
# ===================================
# VARIABLES DE SALTO ORIGINALES
# ===================================
@onready var gravity_magnitude : int = ProjectSettings.get_setting("physics/2d/default_gravity")
# Jump Vars
@onready var gravity: float = gravity_magnitude / 5
@export var jump_force: float = 250.0
@export var charge_rate := 500.0
var is_charging_jump := false
var jump_charge := 0.0
var is_control_enabled = true
@export var min_jump_force: float = 150.0          # 🆕 Salto mínimo (0.5 seg)
@export var max_jump_force: float = 400.0          # 🆕 Salto máximo (5 seg)
@export var min_charge_time: float = 0.5           # 🆕 Tiempo mínimo para saltar
@export var max_charge_time: float = 5.0           # 🆕 Tiempo máximo de carga
@export var base_stamina_cost: float = 10.0        # 🆕 Costo base de stamina
@export var max_stamina_cost: float = 60.0         # 🆕 Costo máximo de stamina

var jump_charge_time: float = 0.0                  # 🆕 Tiempo cargando
var current_jump_force: float = 0.0                # 🆕 Fuerza actual calculada
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

# ===================================
# SISTEMA DE VIENTO SEPARADO
# ===================================
var wind_velocity: Vector2 = Vector2.ZERO
var wind_decay_rate: float = 0.95  # Qué tan rápido se desvanece el viento
var max_wind_velocity: float = 300.0

var current_stamina: float = 100.0
var is_stamina_depleted: bool = false
var time_since_last_stamina_use: float = 0.0           # 🆕 Tiempo desde último uso
var is_in_wind_zone: bool = false
var current_wind_force: float = 0.0

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
var knockback_force := 150

func _ready():
	add_to_group("player")
	
	# Inicializar stamina
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func is_player() -> bool:
	return true

func _physics_process(delta: float) -> void:
	if (!is_on_floor()):
		velocity.y += gravity * delta
	# Resetear doble salto al tocar suelo
	if is_on_floor() and not can_double_jump:
		can_double_jump = true
	# Manejar sistema de stamina
	handle_stamina_system(delta)
	# Sistema de salto con stamina
	handle_jumping_with_stamina(delta)
	# Movimiento horizontal NORMAL (sin cambios)
	handle_horizontal_movement()
	handle_attack()
	# NUEVO: Aplicar viento como fuerza adicional
	apply_wind_forces(delta)
	# Variables de colisiones original
	var was_on_wall: bool = is_on_wall()
	var was_on_air: bool = !is_on_floor()
	var inertia: Vector2 = velocity
	# Aplicar movimiento
	move_and_slide()
	# Lógica de colisiones original
	handle_collisions(was_on_wall,was_on_air,inertia)

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
	
	# Verificar si se recuperó de estar agotada
	if is_stamina_depleted and current_stamina >= min_stamina_to_jump:
		is_stamina_depleted = false
		stamina_recovered.emit()
	
	# 🔧 ARREGLO: Emitir señal MÁS FRECUENTEMENTE para que la UI se vea suave
	if abs(stamina_before - current_stamina) > 0.1:  # Cambié a 0.1 para más sensibilidad
		stamina_changed.emit(current_stamina, max_stamina)

# ===================================
# FUNCIÓN PRINCIPAL - REEMPLAZAR COMPLETAMENTE
# ===================================
func handle_jumping_with_stamina(delta: float):
	"""Sistema de salto variable basado en tiempo de carga"""
	
	# ===================================
	# SALTO CARGADO CON TIEMPO VARIABLE
	# ===================================
	
	# Verificar si puede iniciar carga de salto
	var can_start_charging = (
		is_on_floor() and 
		not is_charging_jump and 
		current_stamina >= base_stamina_cost and 
		not is_stamina_depleted
	)
	
	# INICIAR carga si presiona salto
	if Input.is_action_just_pressed("jump") and can_start_charging:

		is_charging_jump = true
		is_control_enabled = false
		jump_charge_time = 0.0
		current_jump_force = min_jump_force
	
	# CONTINUAR cargando mientras mantiene presionado
	if is_charging_jump and Input.is_action_pressed("jump") and is_on_floor():

		# Incrementar tiempo de carga
		jump_charge_time += delta
		
		# Calcular fuerza basada en tiempo (interpolación)
		var time_progress = clamp(jump_charge_time / max_charge_time, 0.0, 1.0)
		current_jump_force = lerp(min_jump_force, max_jump_force, time_progress)
		
		# Calcular costo de stamina basado en fuerza
		var force_progress = (current_jump_force - min_jump_force) / (max_jump_force - min_jump_force)
		var stamina_cost_per_frame = lerp(base_stamina_cost, max_stamina_cost, force_progress) * delta / max_charge_time
		
		# Consumir stamina gradualmente
		current_stamina = max(0, current_stamina - stamina_cost_per_frame)
		stamina_changed.emit(current_stamina, max_stamina)
		
		# Si se queda sin stamina, forzar salto
		if current_stamina <= 0:
			is_stamina_depleted = true
			stamina_depleted.emit()
			execute_timed_jump()
			return

	
		# Mantener quieto mientras carga
		velocity.x = 0
	
	# EJECUTAR salto al soltar (solo si cargó el tiempo mínimo)
	if is_charging_jump and not Input.is_action_pressed("jump"):
		if jump_charge_time >= min_charge_time:
			execute_timed_jump()
		else:
			# Si soltó muy rápido, cancelar salto
			cancel_jump_charge()
	
	# ===================================
	# SALTO SIN STAMINA (igual que antes)
	# ===================================

	if Input.is_action_just_pressed("jump") and is_on_floor() and (current_stamina < base_stamina_cost or is_stamina_depleted):
		velocity.y = -min_jump_force * 0.3
		can_double_jump = false

		return
	
	# ===================================
	# DOBLE SALTO (sin cambios)
	# ===================================
	if not is_charging_jump and not is_on_floor():
		if Input.is_action_just_pressed("jump") and can_double_jump:
			attempt_double_jump()


# ===================================
# NUEVAS FUNCIONES - AGREGAR ESTAS
# ===================================
func execute_timed_jump():
	"""Ejecuta el salto con la fuerza calculada por tiempo"""
	# Resetear flags
	is_charging_jump = false
	is_control_enabled = true
	
	# Obtener dirección
	var input_vector := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_vector.x = -1
	elif Input.is_action_pressed("move_right"):
		input_vector.x = 1
	
	# Aplicar salto con fuerza calculada
	velocity.x = input_vector.x * speed
	velocity.y = -current_jump_force
	
	# Resetear variables
	jump_charge_time = 0.0
	current_jump_force = 0.0
	
	# Habilitar doble salto
	can_double_jump = true

func cancel_jump_charge():
	"""Cancela la carga de salto si se soltó muy rápido"""
	is_charging_jump = false
	is_control_enabled = true
	jump_charge_time = 0.0
	current_jump_force = 0.0

# ===================================
# FUNCIÓN PARA UI - AGREGAR ESTA
# ===================================
func get_jump_charge_progress() -> float:
	"""Retorna el progreso de carga del salto (0.0 - 1.0)"""
	if not is_charging_jump:
		return 0.0
	return clamp(jump_charge_time / max_charge_time, 0.0, 1.0)


func execute_charged_jump():
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

func handle_collisions(was_on_wall: bool,was_on_air: bool, inertia: Vector2 ):
	"""Lógica de colisiones original"""
	
	if is_on_wall() or is_on_ceiling() and not was_on_wall and !is_control_enabled :
		now_is_falling = true
		if(!is_on_ceiling()):
			velocity.x = inertia.x * -1 * vel_loss_percentage
		else:
			velocity.x = inertia.x * vel_loss_percentage
		
	# Just landed on floor
	if was_on_air and is_on_floor():
		if now_is_falling:
			velocity = Vector2.ZERO
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

func _on_fall_cooldown_timeout() -> void:
	is_control_enabled = true
	$Sprite2D.region_rect = Rect2(234,22,24,26)
	
func equip_weapon(weapon: PackedScene):
	if equipped_weapon:
		equipped_weapon.queue_free()
	equipped_weapon = weapon.instantiate()
	add_child(equipped_weapon)
	equipped_weapon.global_position = global_position
  
func receive_damage_from(damagePosition: Vector2):
	lifes -= 1
	if lifes < 1:
		queue_free()
	
	if not $FallCooldown.is_stopped():
		pass
	var direction := global_position.direction_to(damagePosition) * -1
	
	# Aplicar la fuerza de empuje
	velocity.x = knockback_force
	if abs(direction.y) < 0.3:
		velocity.y = -100 # salto pequeño
	else:
		velocity.y = -abs(direction.y * knockback_force)
	
	is_control_enabled = false
	now_is_falling = true

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

# ===================================


	

	# Sumar viento a la velocidad final CON MULTIPLICADOR
	velocity += wind_velocity * delta * 10.0  # ⭐ MULTIPLICADOR x10

# MODIFICAR las funciones de interacción con ventilador:
# NUEVA función para que el ventilador aplique viento:

func add_wind_force(force: Vector2):
	wind_velocity += force
	# Limitar viento máximo
	if wind_velocity.length() > max_wind_velocity:
		wind_velocity = wind_velocity.normalized() * max_wind_velocity


func handle_attack():
	if equipped_weapon and Input.is_action_just_pressed("attack"):
		equipped_weapon.attack()
