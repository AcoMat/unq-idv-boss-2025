extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_start_timeout() -> void:
	pass
	


func _on_final_body_entered(body: Node2D) -> void:
	$tutorial_final/FinalTimer.start()
	body.queue_free()


func _on_final_timer_timeout() -> void:
	$tutorial_final/ColorRect.visible = true
	SceneManager.change_scene("res://main.tscn")
	#Cambiar al level 1 dsp
