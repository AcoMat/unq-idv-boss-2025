extends CharacterBody2D

@export var speed: float = 200.0
@export var gravity: float = 1200.0
@export var knockback_force: Vector2 = Vector2(-200, -300)
@export var knockback_duration: float = 1.0

var is_control_enabled: bool = true
var is_jumping: bool = false

func _physics_process(delta: float) -> void:
	# Always apply gravity
	if (!is_on_floor()):
		velocity.y += gravity * delta

	# Knockback cooldown
	if not is_control_enabled:
		pass
		
		
	if Input.is_action_just_pressed("jump"):
		is_jumping = !is_jumping

	# Horizontal movement when allowed
	if is_control_enabled:
		var input_vector := Vector2.ZERO
		if Input.is_action_pressed("move_left"):
			input_vector.x = -1
		elif Input.is_action_pressed("move_right"):
			input_vector.x = 1

		velocity.x = input_vector.x * speed

	# Collision check and knockback trigger
	var was_on_wall = is_on_wall()
	move_and_slide()
	
	if is_jumping and is_on_wall() and not was_on_wall and is_control_enabled :
		apply_knockback()

func apply_knockback():
	is_control_enabled = false

	var knockback_dir = -sign(velocity.x) if velocity.x != 0 else -1
	velocity = Vector2(knockback_dir * knockback_force.x, knockback_force.y)
