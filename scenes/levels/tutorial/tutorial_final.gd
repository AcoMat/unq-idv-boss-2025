extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_final_body_entered(body: Node2D) -> void:
	$EndFall.play()


func _on_end_fall_finished() -> void:
	$ColorRect.visible = true
	$FinalTimer.start()


func _on_final_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
