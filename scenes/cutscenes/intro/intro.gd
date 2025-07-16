extends Node2D

var dialog_box := preload("res://scenes/ui/dialogues/dialog_box.tscn")

var dialog1 := ["Había una vez...","Un caballero que le apostó al diablo salud y requizas...","Para ganarle solo tenía que hacer una sola cosa...", "Escapar del LIMBO."]
var knight_loop = true

func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	pass


func _on_ready_timeout() -> void:
	var intro_text_1 = dialog_box.instantiate()
	intro_text_1.text_queue = dialog1
	add_child(intro_text_1)
	await intro_text_1.second_to_last
	knight_loop = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if(knight_loop):
		body.global_position = $Marker2D.global_position
	else:
		body.queue_free()
