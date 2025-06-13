extends StaticBody2D
@onready var attack_sound: AudioStreamPlayer2D = $"../../../Attack"
@onready var death_sound: AudioStreamPlayer2D = $"../../../Death"

@export var speed: float = 50.0
var path_follow: PathFollow2D
var last_position: Vector2

var target: CharacterBody2D
var attacking := false

func _ready() -> void:
	path_follow = get_parent()


func _process(delta: float) -> void:
	if path_follow and $Cooldown.is_stopped() and not attacking:
		path_follow.progress += speed * delta
		global_position = path_follow.global_position
		var movement = global_position - last_position
		if movement.x > 0:
			$AnimatedSprite2D.flip_h = false
		elif movement.x < 0:
			$AnimatedSprite2D.flip_h = true
		last_position = global_position

func attack():
	$AnimatedSprite2D.play("attack")
	$Cooldown.start()
	attacking = true

func deal_damage():
	attack_sound.play()
	if target:
		target.get_attacked(global_position)

func _on_hit_range_body_entered(body: Node2D) -> void:
	target = body
	attack()

func _on_hit_range_body_exited(body: Node2D) -> void:
	target = null

func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "attack":
		$AnimatedSprite2D.play("return_attack")
		deal_damage()
	if $AnimatedSprite2D.animation == "death":
		queue_free()


func receive_damage():
	death_sound.play()
	path_follow = null
	$HitRange.monitoring = false
	$AnimatedSprite2D.play("death")


func _on_cooldown_timeout() -> void:
	attacking = false
	$AnimatedSprite2D.play("default")
