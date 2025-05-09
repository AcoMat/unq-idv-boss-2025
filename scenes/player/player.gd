extends CharacterBody2D

@export var speed: float = 200.0
@export var gravity: float = 200.0

# Jump Vars
@export var jump_force: float = 250.0
@export var max_jump_force := 300.0
@export var charge_rate := 500.0
var is_charging_jump := false
var jump_charge := 0.0
var is_control_enabled = true

#Collision Vars
@export_range(0.0,1.0) var vel_loss_percentage: float = 0.5
var now_is_falling := false

func _physics_process(delta: float) -> void:
	# Always apply gravity
	if (!is_on_floor()):
		velocity.y += gravity * delta
		
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
		elif Input.is_action_pressed("move_right"):
			input_vector.x = 1
		velocity.x = input_vector.x * speed
	
	# Collision check and knockback trigger
	var was_on_wall: bool = is_on_wall()
	var was_on_air: bool = !is_on_floor()
	var intertia = velocity
	# APPLY MOVEMENT
	move_and_slide()
	
	if is_on_wall() and not was_on_wall and !is_control_enabled :
		apply_knockback(intertia)
	
	# Just landed on floor
	if was_on_air and is_on_floor():
		if now_is_falling:
			# Pj just crashed on the floor
			# TODO: Improve this measuring the fall velocity, small falls shouldnt make the pj smash into the floor
			velocity = Vector2.ZERO
			print("hit the ground")
			$FallCooldown.start()
			$Sprite2D.region_rect = Rect2(377,82,29,14)
			now_is_falling = false
		else:
			is_control_enabled = true
			
	# Felt from floor
	if !was_on_air and !is_on_floor() and is_control_enabled:
		now_is_falling = true
		is_control_enabled = false
		velocity.x = intertia.x * vel_loss_percentage


func apply_knockback(intertia: Vector2):
	now_is_falling = true
	velocity.x = intertia.x * -1 * vel_loss_percentage
	$KnockDownCooldown.start()

func _on_fall_cooldown_timeout() -> void:
	is_control_enabled = true
	$Sprite2D.region_rect = Rect2(234,22,24,26)
