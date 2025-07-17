extends Area2D

@export var next_scene_path: String 
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer
@onready var open_door: AudioStreamPlayer2D = $OpenDoor

func _ready():
	animated_sprite_2d.play("closed")

func _on_body_entered(player):
	if player.is_in_group("player"):
		player.is_control_enabled = false
		player.velocity = Vector2.ZERO
		open_door.play()
		animated_sprite_2d.play("open")
		await animated_sprite_2d.animation_finished
		SceneManager.change_scene(next_scene_path)
