extends Node2D

@onready var agent: NavigationAgent2D = $NavigationAgent2D
var speed := 50.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Path2D/PathFollow2D.progress += speed * delta


func _on_hit_range_body_entered(body: Node2D) -> void:
	body.receive_damage_from($Path2D/PathFollow2D/RigidBody2D.global_position)
