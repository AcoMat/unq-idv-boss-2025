extends EnemyBase

var current_objetive: Node2D = null
@export var projectile_scene := preload("res://scenes/entities/enemies/mushroom/mushroom_projectile.tscn")
@onready var shoot_sound: AudioStreamPlayer2D = $Shoot
@onready var death_sound: AudioStreamPlayer2D = $Death

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	death_sound.finished.connect(_on_death_sound_finished)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if current_objetive:
		$RayCast2D.enabled = true
		$RayCast2D.target_position = current_objetive.global_position - $RayCast2D.global_position
		$RayCast2D.force_raycast_update()
		if $RayCast2D.is_colliding() and $RayCast2D.get_collider() == current_objetive:
			shoot()


func shoot():
	if $ShootCooldown.is_stopped():
		shoot_sound.play()
		var new_projectile: Node2D = projectile_scene.instantiate()
		get_parent().add_child(new_projectile)
		new_projectile.global_position = global_position
		var direction: Vector2 = (current_objetive.position - global_position)
		new_projectile.init(direction)
		$ShootCooldown.start()


func get_attacked(enemy_position: Vector2):
	super(enemy_position)
	death_sound.play()

func _on_area_2d_body_entered(body: Node2D) -> void:
	current_objetive = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	current_objetive = null
	$RayCast2D.enabled = false

func _on_death_sound_finished():
	queue_free()
