extends EnemyBase

@onready var floor_check := $floor_check
@onready var wall_check := $wall_check
@onready var sprite := $SkeletonSprite
@onready var attack_sprite := $AttackSprite
var direction := -1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if not floor_check.is_colliding() or wall_check.is_colliding():
		direction *= -1
		_flip()

	if abs(velocity.x) < speed:
		velocity.x = direction * speed
	move_and_slide()
	velocity = velocity.lerp(Vector2(direction * speed, 0), 0.1)


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
	wall_check.target_position.x *=  -1


func _on_attack_area_body_entered(body: Node2D) -> void:
	speed = 0
	sprite.visible=false
	$AttackSprite.visible=true
	$AttackSprite.play("attack")


func _on_attack_sprite_animation_finished() -> void:
	if $AttackSprite.animation == "attack":
		for body in $AttackArea.get_overlapping_bodies():
			body.get_attacked(global_position)
		$AttackSprite.play("after_attack")
	else:
		speed = 60
		attack_sprite.visible=false
		sprite.visible = true
		
