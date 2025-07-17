extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	$Sprite2D.play("break")


func _on_sprite_2d_animation_finished() -> void:
	if $Sprite2D.animation == "break":
		$Sprite2D.visible = false
		$CollisionShape2D.disabled = true
		$Respawn.start()


func _on_respawn_timeout() -> void:
	$Sprite2D.visible = true
	$CollisionShape2D.disabled = false
	$Sprite2D.play("default")
