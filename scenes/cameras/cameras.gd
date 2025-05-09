extends Node2D

var cameras : Array[Camera2D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var nodes = get_children(true)
	for child in nodes:
		if child is Camera2D:
			cameras.append(child)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D, camera_number: int) -> void:
	print("Body entered on camera " + str(camera_number))
	for camera in cameras:
		camera.enabled = false 
	cameras[camera_number - 1].enabled = true
