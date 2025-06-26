extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	$Area2D/CollisionShape2D.disabled = true


func _process(_delta: float) -> void:
	if Input.is_action_pressed("move_left"):
		scale = abs(scale) * -1
		$SwordSprite.flip_v = true
	elif Input.is_action_pressed("move_right"):
		scale = abs(scale)
		$SwordSprite.flip_v = false


func attack() -> void:
	if $AttackCooldown.is_stopped():
		visible = true
		$Area2D/CollisionShape2D.disabled = false
		# Podrian haber mas tipos de ataques
		cut()
		$AttackCooldown.start()


func cut():
	$Sword_attack.play()
	$SwordSprite.play("cut")

func _on_sword_sprite_animation_finished() -> void:
	visible = false
	$Area2D/CollisionShape2D.disabled = true

 
func _on_area_2d_body_entered(body: Node2D) -> void:
	body.receive_damage()
