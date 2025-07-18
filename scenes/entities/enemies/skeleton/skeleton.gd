extends EnemyBase

@onready var floor_check := $floor_check
@onready var wall_check := $wall_check
@onready var sprite := $SkeletonSprite
@onready var attack_sprite := $AttackSprite

enum State {
	PATROLLING,
	ATTACKING,
	DYING
}

var state: State = State.PATROLLING
var direction := -1

func _physics_process(delta: float) -> void:
	super(delta)
	
	match state:
		State.PATROLLING:
			_process_patrolling(delta)
		State.ATTACKING:
			_process_attacking(delta)
		State.DYING:
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, 500 * delta)

	move_and_slide()


# --- Estados ---
func _process_patrolling(delta: float) -> void:
	if not floor_check.is_colliding() or wall_check.is_colliding() and is_on_floor():
		direction *= -1
		_flip()

	velocity = velocity.lerp(Vector2(direction * speed, 0), 0.1)

func _process_attacking(delta: float) -> void:
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 500 * delta)


# --- Cambio de estados ---
func _change_state(new_state: State) -> void:
	if state == new_state:
		return
	
	match new_state:
		State.PATROLLING:
			speed = 60
			sprite.visible = true
			attack_sprite.visible = false

		State.ATTACKING:
			speed = 0
			velocity = Vector2.ZERO
			sprite.visible = false
			attack_sprite.visible = true
			attack_sprite.play("attack")

		State.DYING:
			speed = 0
			attack_sprite.visible = false
			attack_sprite.stop()
			sprite.visible = true
			sprite.play("death")
			$Death.play()

	state = new_state


# --- Eventos ---
func get_attacked(attacker_position: Vector2) -> void:
	get_pushed(attacker_position)
	health -= 1
	if health < 1:
		die()
	# Girar hacia el atacante
	var new_direction = sign(attacker_position.x - global_position.x)
	if new_direction != direction:
		direction = new_direction
		_flip()

func _flip():
	if direction < 0:
		sprite.flip_h = true
		attack_sprite.flip_h = true
		attack_sprite.offset.x = -20
	else:
		sprite.flip_h = false
		attack_sprite.flip_h = false
		attack_sprite.offset.x = 0

	$AttackArea.scale.x *= -1
	floor_check.target_position.x *= -1
	wall_check.target_position.x *= -1


func _on_attack_area_body_entered(body: Node2D) -> void:
	if state != State.DYING:
		_change_state(State.ATTACKING)


func _on_attack_sprite_animation_finished() -> void:
	if attack_sprite.animation == "attack":
		$Attack.play()
		for body in $AttackArea.get_overlapping_bodies():
			body.get_attacked(global_position)
		attack_sprite.play("after_attack")
	elif state != State.DYING:
		_change_state(State.PATROLLING)


func die():
	if state != State.DYING:
		_change_state(State.DYING)


func _on_skeleton_sprite_animation_finished() -> void:
	if sprite.animation == "death":
		queue_free()
