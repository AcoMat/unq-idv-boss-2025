extends Node2D

var cameras: Array[Camera2D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cameras = get_all_cameras_sorted()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D, cam_id: int) -> void:
	for camera in cameras:
		camera.enabled = false
	cameras[cam_id].enabled = true


func get_all_cameras_sorted():
	var get_cameras: Array[Camera2D] = []
	for child in get_children():
		if child is Camera2D:
			get_cameras.append(child)
	get_cameras.sort_custom(func(a: Camera2D, b: Camera2D): return a.global_position.y > b.global_position.y) #ordeno por altura
	return get_cameras
