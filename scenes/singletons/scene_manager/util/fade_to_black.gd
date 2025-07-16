extends Control
@onready var animPlayer = $CanvasLayer/AnimationPlayer
signal fade_finished()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func fade_out():
	animPlayer.play("fade_to_black")


func fade_in():
	animPlayer.play("fade_from_black")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	fade_finished.emit()
