extends CharacterBody2D

@onready var gravity_magnitude : int = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var gravity: float = gravity_magnitude / 4

@export_group("General")
@export var speed: float = 200.0
@export var lifes = 3
var equipped_weapon: Node2D = null

# Jump Vars
@export_group("Jump")
@export var charge_rate := 8.0
@export var double_jump_force: float = 100.0
var is_charging_jump := false
var jump_charge := 0.0
var is_control_enabled = true
var can_double_jump: bool = false

@export_group("Bounce")
@export_range(0.0,1.0) var vel_loss_percentage: float = 0.5
@export var knockback_force := 150
var now_is_falling := false
var was_on_wall: bool = is_on_wall()
var was_on_air: bool = !is_on_floor()
var inertia: Vector2 = velocity


func _ready():
	add_to_group("player")


func _physics_process(delta: float) -> void:
	# Abstraer a handle physics
	if (!is_on_floor()):
		velocity.y += gravity * delta
	# Variables de colisiones original
	was_on_wall = is_on_wall()
	was_on_air = !is_on_floor()
	inertia = velocity
	# Aplicar movimiento
	move_and_slide()
	handle_inputs()
	# Lógica de colisiones original	
	handle_falls()


func handle_inputs():
	# Jump
	handle_jump_inputs()
	# Movement
	if is_control_enabled and is_on_floor() and not is_charging_jump:
		handle_movement()
	# Attack
	if equipped_weapon and Input.is_action_just_pressed("attack"):
		equipped_weapon.attack()


func handle_jump_inputs():
	var can_start_charging = (
		is_on_floor() 
		and not is_charging_jump
		and is_control_enabled
	)
	# INICIAR carga si presiona salto
	if Input.is_action_just_pressed("jump") and can_start_charging:
		is_charging_jump = true
		is_control_enabled = false
	# CONTINUAR cargando mientras mantiene presionado
	if is_charging_jump and Input.is_action_pressed("jump"):
		jump_charge += charge_rate
		# Mantener quieto mientras carga
		velocity.x = 0
	
	# EJECUTAR salto al soltar
	if is_charging_jump and not Input.is_action_pressed("jump"):
		if Input.is_action_pressed("move_left"):
			jump(-1)
		elif Input.is_action_pressed("move_right"):
			jump(1)
		else:
			jump(0)
	
	if not is_charging_jump and not is_on_floor() and Input.is_action_just_pressed("jump") and can_double_jump:
		if Input.is_action_pressed("move_left"):
			double_jump(-1)
		elif Input.is_action_pressed("move_right"):
			double_jump(1)
		else:
			double_jump(0)


func handle_movement():
	var input_direction := 0
	if Input.is_action_pressed("move_left"):
		input_direction -= 1
	elif Input.is_action_pressed("move_right"):
		input_direction += 1
	velocity.x = input_direction * speed


func jump(direction: int):
	is_charging_jump = false
	# Obtener dirección
	var input_vector := Vector2.ZERO
	input_vector.x = direction
	$DoubleJumpCooldown.start()
	# Aplicar salto con fuerza calculada
	velocity.x = input_vector.x * (jump_charge * 0.5)
	velocity.y = -jump_charge
	# Resetear variables
	jump_charge = 0.0


func double_jump(direction: int):
	# Aplicar doble salto
	velocity.y = -double_jump_force
	can_double_jump = false
	var input_vector := Vector2.ZERO
	input_vector.x = direction
	if input_vector.x != 0:
		velocity.x = input_vector.x * speed * 0.8


func handle_falls():
	if is_on_wall() or is_on_ceiling() and not was_on_wall and !is_control_enabled :
		now_is_falling = true
		can_double_jump = false
		if(!is_on_ceiling()):
			velocity.x = inertia.x * -1 * vel_loss_percentage
		else:
			velocity.x = inertia.x * vel_loss_percentage
		
	# Just landed on floor
	if was_on_air and is_on_floor():
		if now_is_falling:
			velocity = Vector2.ZERO
			$JustFeltCooldown.start()
			$Sprite2D.region_rect = Rect2(377,82,29,14)
			now_is_falling = false
		else:
			is_control_enabled = true
	
	# Slip from floor
	if !was_on_air and !is_on_floor() and is_control_enabled:
		now_is_falling = true
		is_control_enabled = false
		velocity.x = inertia.x * vel_loss_percentage


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


func _on_double_jump_cooldown_timeout() -> void:
	if not is_on_floor() and not now_is_falling and not is_control_enabled : 
		can_double_jump = true


func _on_just_felt_cooldown_timeout() -> void:
	is_control_enabled = true
	can_double_jump = false
	$Sprite2D.region_rect = Rect2(234,22,24,26)

	
