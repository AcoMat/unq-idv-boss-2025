extends Area2D

@export var push_direction: Vector2 = Vector2.DOWN
@export var push_force: float = 1000.0

var bodies_in_area: Array = []

func _physics_process(delta):
	for body in bodies_in_area:
		if body.has_method("apply_central_impulse"):
			# Si es un RigidBody2D
			body.apply_central_impulse(push_direction.normalized() * push_force * delta)
		elif body.has_method("add_force"):
			# Alternativa para cuerpos que lo soporten (ej. RigidBody2D)
			body.add_force(push_direction.normalized() * push_force, Vector2.ZERO)
		elif body.has_method("apply_push_force"):
			# Si es un personaje que implementa su propia lógica
			body.apply_push_force(push_direction.normalized() * push_force * delta)
		elif body.has_method("move_and_slide"):
			# Personajes tipo CharacterBody2D
			body.velocity += push_direction.normalized() * push_force * delta


func _on_body_entered(body: Node2D) -> void:
	if body not in bodies_in_area:
		bodies_in_area.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body in bodies_in_area:
		bodies_in_area.erase(body)
