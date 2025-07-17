extends CharacterBody2D
class_name EnemyBase

var health: int = 3
var speed: float = 60.0
var knockback_force := 150

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_pushed(enemy_position: Vector2):
	print(enemy_position)
	print(global_position)
	# Calcular dirección contraria al enemigo
	var direction = sign(global_position.x - enemy_position.x)
	# Aplicar impulso
	velocity.x = direction * knockback_force
	velocity.y = -abs(knockback_force) * 0.6 


func get_attacked(enemy_position: Vector2):
	get_pushed(enemy_position)
	health -= 1
	if health < 1:
		die()


func die():
	print("Enemy died!")
	queue_free()
