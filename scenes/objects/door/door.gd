extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer
@onready var open_door: AudioStreamPlayer2D = $OpenDoor

func _ready():
	animated_sprite_2d.play("closed")

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("¡El rey llegó a la puerta!")
		body.door = true
		collision_shape_2d.queue_free()
		open_door.play()
		animated_sprite_2d.play("open")
		timer.start()
		await (timer.timeout)
		get_tree().change_scene_to_file("res://main.tscn")
