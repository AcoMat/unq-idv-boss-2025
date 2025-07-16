extends Node

var current_scene: Node = null
var fade_transition := preload("res://scenes/singletons/scene_manager/util/fade_to_black.tscn")
var main_menu_path := "res://scenes/cutscenes/intro/intro.tscn"


func _ready():
	change_scene(main_menu_path)


func change_scene(path: String):
	var transition = fade_transition.instantiate()
	add_child(transition)
	transition.fade_out()
	await transition.fade_finished
	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
		# Wait for a frame to ensure the old scene is freed before adding the new one.
		await get_tree().process_frame
#
	var new_scene_resource = load(path)
	if not new_scene_resource:
		printerr("SceneManager: Failed to load scene at path: ", path)
		# Fade back in to not leave the player on a black screen.
		await transition.fade_finished
		transition.fade_in()
		return
	transition.fade_in()
	current_scene = new_scene_resource.instantiate()
	get_tree().root.add_child(current_scene)
	await transition.fade_finished
	transition.queue_free()
	
