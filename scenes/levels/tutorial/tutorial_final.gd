extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_final_body_entered(body: Node2D) -> void:
	$FinalTimer.start()


func _on_final_timer_timeout() -> void:
	if not $Blackout.is_visible_in_tree():
		$Blackout.visible = true
		$FinalTimer.wait_time = 1.0
		$FinalTimer.start()
	else:
		get_tree().change_scene_to_file("res://main.tscn")
