extends Node2D

var weapon: PackedScene = preload("res://scenes/player/sword/sword.tscn")
@onready var sound_sword: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if sprite.visible:
		body.equip_weapon(weapon)
		sound_sword.play()
		sprite.visible = false
		collision_shape.call_deferred("disable", true)


func _on_sound_sword_finished() -> void:
	queue_free()
