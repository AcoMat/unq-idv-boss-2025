extends Node2D
@onready var message_box  = $CanvasLayer2/Control

func _ready():
	show_message()

func show_message():
	var tween = create_tween()
	tween.tween_property(message_box, "modulate:a", 0.0, 0.5)
	tween.tween_property(message_box, "modulate:a", 1.0, 0.5)
	tween.tween_interval(4.0)
	tween.tween_property(message_box, "modulate:a", 0.0, 0.5)
