extends Node2D

@export var sign_text: String = "..."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Control/PanelContainer/Label.text = sign_text
	$Control.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("HOO")
	if body.is_in_group("player"):
		$Control.visible = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	print("HOO")
	if body.is_in_group("player"):
		$Control.visible = false
