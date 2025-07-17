extends Node2D

var dialog_box := preload("res://scenes/ui/dialogues/dialog_box.tscn")

var knight_loop = true

func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	pass


func _on_ready_timeout() -> void:
	$DialogsLayer/IntroText.start_dialogue()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if knight_loop:
		var target_position = $LoopMarker.global_position
		var rigid_body := body as RigidBody2D
		
		var new_transform := Transform2D(0, target_position)
		PhysicsServer2D.body_set_state(rigid_body.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, new_transform)

		rigid_body.linear_velocity = Vector2.ZERO
		rigid_body.angular_velocity = 0.0
	else:
		body.queue_free()


func _on_intro_text_second_to_last() -> void:
	knight_loop = false


func _on_intro_text_finished() -> void:
	$Start.start()


func _on_start_timeout() -> void:
	print("START")
	SceneManager.change_scene("res://levels/tutorial/tutorial_level.tscn")
