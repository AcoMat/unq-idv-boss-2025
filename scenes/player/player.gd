extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_force: float = 250.0
@export var gravity: float = 200.0
@export var knockback_force: float = 200

var is_control_enabled = true

func _physics_process(delta: float) -> void:
	# Always apply gravity
	if (!is_on_floor()):
		velocity.y += gravity * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()
		
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


func jump():
	if(is_on_floor()):
		is_control_enabled = false
		print(is_control_enabled)
		print("JUMP")
		velocity.y -= jump_force


func _on_fall_cooldown_timeout() -> void:
	is_control_enabled = true
	print("landed")
