extends Node2D


func _on_final_body_entered(body: Node2D) -> void:
	body.queue_free()
	$tutorial_final/EndFall.play()


func _on_end_fall_finished() -> void:
	$tutorial_final/ColorRect.visible = true
	$tutorial_final/FinalTimer.start()


func _on_final_timer_timeout() -> void:
	SceneManager.change_scene("res://levels/level_1/level_1.tscn")
