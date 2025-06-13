extends RigidBody2D

var speed = 150
var accel = 3
# PathFinding
var target: CharacterBody2D = null
var wander_center: Vector2
var wander_radius := 200.0
@onready var death_sound: AudioStreamPlayer2D = $Death
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var fly_sound: AudioStreamPlayer2D = $Fly
var is_wandering = true
# Called when the node enters the scene tree for the first time.d
func _ready() -> void:
	gravity_scale = 0
	wander_center = global_position
	death_sound.finished.connect(_on_death_sound_finished)
	fly_sound.play()  # Inicia el sonido de vuelo

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $AttackArea.has_overlapping_bodies() and $AttackCooldown.is_stopped():
		target.get_pushed(global_position)
		$AttackCooldown.start()
		set_collision_mask_value(2, false)
	if target and not nav.is_navigation_finished():
		nav.target_position = target.global_position
		var direction = (nav.get_next_path_position() - global_position).normalized()
		linear_velocity = direction * speed
	else:
		if is_wandering and not nav.is_navigation_finished():
			var direction = (nav.get_next_path_position() - global_position).normalized()
			linear_velocity = direction * speed
		else:
			linear_velocity = linear_velocity.move_toward(Vector2.ZERO, accel)
			if $WanderingTimer.is_stopped():
				$WanderingTimer.start()

func _on_death_sound_finished():
	queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	target = body
	$WanderingTimer.start()

func _on_detection_area_body_exited(body: Node2D) -> void:
	target = null
	$WanderingTimer.stop()

func get_random_wander_point() -> Vector2:
	var angle = randf() * TAU
	var distance = randf() * wander_radius
	return wander_center + Vector2(cos(angle), sin(angle)) * distance

func _on_wandering_timer_timeout() -> void:
	nav.target_position = get_random_wander_point()

func receive_damage():
	fly_sound.stop()  # Detiene el sonido de vuelo
	death_sound.play()
