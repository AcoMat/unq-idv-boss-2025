extends CharacterBody2D

var is_charging_jump := false
var jump_charge := 0.0

@export var max_jump_force := 600.0
@export var charge_rate := 500.0
@export var speed: float = 200.0
@export var jump_force: float = 250.0
@export var gravity: float = 200.0
@export var knockback_force: float = 200

var is_control_enabled = true

func _physics_process(delta: float) -> void:
	# Always apply gravity
	if (!is_on_floor()):
		velocity.y += gravity * delta
		
# Inicia carga si se presiona salto estando en el suelo
	if Input.is_action_pressed("jump") and is_on_floor():
		is_charging_jump = true
		jump_charge = min(jump_charge + charge_rate * delta, max_jump_force)

# Al soltar salto, ejecuta el salto con la fuerza cargada
	if Input.is_action_just_released("jump") and is_charging_jump:
		if is_on_floor():
			velocity.y = -jump_charge
			is_control_enabled = false
			$FallCooldown.start()
		is_charging_jump = false
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
	move_and_slide()
	
	if is_on_wall() and not was_on_wall and !is_control_enabled :
		apply_knockback(intertia)
	if was_on_air and is_on_floor():
		velocity = Vector2.ZERO
		$FallCooldown.start()


func apply_knockback(intertia: Vector2):
	print("knockback")
	print(intertia.x)
	print(intertia.y)
	var knockback_dir: float = -sign(intertia.x)
	velocity.x = knockback_dir * knockback_force
	$KnockDownCooldown.start()

func _on_fall_cooldown_timeout() -> void:
	is_control_enabled = true
	print("landed")
