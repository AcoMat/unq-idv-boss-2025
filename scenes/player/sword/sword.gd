extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	$Area2D/CollisionShape2D.disabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("move_left"):
		scale = abs(scale) * -1
	elif Input.is_action_pressed("move_right"):
		scale = abs(scale)


func attack() -> void:
	if $AttackCooldown.is_stopped():
		visible = true
		$Area2D/CollisionShape2D.disabled = false
		# Podrian haber mas tipos de ataques
		stab()
		$AttackCooldown.start()


func stab():
	$SwordSprite.play("stab")

func _on_sword_sprite_animation_finished() -> void:
	visible = false
	$Area2D/CollisionShape2D.disabled = true

 
func _on_area_2d_body_entered(body: Node2D) -> void:
	body.receive_damage()
