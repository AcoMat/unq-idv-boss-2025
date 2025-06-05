extends CharacterBody2D

var lifes = 3
# Pj movement
@export var speed: float = 200.0
# Pj weapon
var equipped_weapon: Node2D = null
# Gravity
@onready var gravity_magnitude : int = ProjectSettings.get_setting("physics/2d/default_gravity")
# Jump Vars
@onready var gravity: float = gravity_magnitude / 5
@export var jump_force: float = 250.0
@export var max_jump_force := 300.0
@export var charge_rate := 500.0
var is_charging_jump := false
var jump_charge := 0.0
var is_control_enabled = true
#Collision Vars
@export_range(0.0,1.0) var vel_loss_percentage: float = 0.5
var now_is_falling := false
var knockback_force := 150

func _physics_process(delta: float) -> void:
	handle_input(delta)
	apply_physics(delta)
	
	
func apply_physics(delta):
	# Always apply gravity
	if (!is_on_floor()):
		velocity.y += gravity * delta
		
	# Collision check and knockback trigger
	var was_on_wall: bool = is_on_wall()
	var was_on_air: bool = !is_on_floor()
	var inertia = velocity
	# APPLY MOVEMENT
	move_and_slide()
	
	if is_on_wall() or is_on_ceiling() and not was_on_wall and !is_control_enabled :
		now_is_falling = true
		if(!is_on_ceiling()):
			velocity.x = inertia.x * -1 * vel_loss_percentage
		else:
			velocity.x = inertia.x * vel_loss_percentage
		
	# Just landed on floor
	if was_on_air and is_on_floor():
		if now_is_falling:
			# Pj just crashed on the floor
			# TODO: Improve this measuring the fall velocity, small falls shouldnt make the pj smash into the floor
			velocity = Vector2.ZERO
			$FallCooldown.start()
			$Sprite2D.region_rect = Rect2(377,82,29,14)
			now_is_falling = false
		else:
			is_control_enabled = true
			
	# Felt from floor
	if !was_on_air and !is_on_floor() and is_control_enabled:
		now_is_falling = true
		is_control_enabled = false
		velocity.x = inertia.x * vel_loss_percentage

func handle_input(delta):
	# Attack with weapon
	if Input.is_action_just_pressed("attack"):
		if equipped_weapon:
			equipped_weapon.attack()
		
	# Inicia carga si se presiona salto estando en el suelo
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.x = 0
		is_charging_jump = true
		is_control_enabled = false
		jump_charge = min(jump_charge + charge_rate * delta, max_jump_force)
	
	# Al soltar salto, ejecuta el salto con la fuerza cargada
	if Input.is_action_just_released("jump") and is_charging_jump:
		is_charging_jump = false
		var input_vector := Vector2.ZERO
		if Input.is_action_pressed("move_left"):
			input_vector.x = -1
		elif Input.is_action_pressed("move_right"):
			input_vector.x = 1
		velocity.x = input_vector.x * speed
		velocity.y = -jump_charge
		jump_charge = 0.0
	
	if is_control_enabled and is_on_floor():
		var input_vector := Vector2.ZERO
		if Input.is_action_pressed("move_left"):
			input_vector.x = -1
			$Sprite2D.flip_h = true
		elif Input.is_action_pressed("move_right"):
			$Sprite2D.flip_h = false
			input_vector.x = 1
		velocity.x = input_vector.x * speed

func _on_fall_cooldown_timeout() -> void:
	is_control_enabled = true
	$Sprite2D.region_rect = Rect2(234,22,24,26)
	
func equip_weapon(weapon: PackedScene):
	if equipped_weapon:
		equipped_weapon.queue_free()
	equipped_weapon = weapon.instantiate()
	add_child(equipped_weapon)
	equipped_weapon.global_position = global_position

func change_gravity(multiplier: float):
	gravity = gravity * multiplier
	
func reset_gravity():
	gravity = gravity_magnitude / 5
	
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
