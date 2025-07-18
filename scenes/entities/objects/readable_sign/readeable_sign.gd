extends Node2D

@export var sign_text: Array[String] = ["..."]
@onready var dialog_box := $CanvasLayer/DialogBox

signal open_sign()
signal close_sign()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dialog_box.text_queue = sign_text


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not dialog_box.visible:
		dialog_box.start_dialogue()
		emit_signal("open_sign")

func _on_dialog_box_finished() -> void:
	emit_signal("close_sign")
	dialog_box.visible = false
