extends RigidBody2D

var current_objetive: Node2D = null
@export var projectile_scene := preload("res://scenes/enemies/enemy2/mushroom_projectile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_objetive:
		$RayCast2D.enabled = true
		$RayCast2D.target_position = current_objetive.global_position - $RayCast2D.global_position
		$RayCast2D.force_raycast_update()
		if $RayCast2D.is_colliding() and $RayCast2D.get_collider() == current_objetive:
			shoot()


func shoot():
	if $ShootCooldown.is_stopped():
		var new_projectile: Node2D = projectile_scene.instantiate()
		get_parent().add_child(new_projectile)
		new_projectile.global_position = global_position
		var direction: Vector2 = (current_objetive.position - global_position)
		new_projectile.init(direction)
		$ShootCooldown.start()


func _on_area_2d_body_entered(body: Node2D) -> void:
	current_objetive = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	current_objetive = null
	$RayCast2D.enabled = false


func receive_damage():
	queue_free()
