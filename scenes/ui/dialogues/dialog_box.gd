extends Control

@onready var label := $Panel/Label
@onready var arrow := $Panel/TextureRect
@onready var sound := $AudioStreamPlayer2D

signal second_to_last()
signal finished()

@export var text_queue: Array[String] = ["..."]
@export var speed := 0.03

var skip_dialogue := false
var playing_dialogue := false
var current_index := 0
var awaiting_input := false

func _ready() -> void:
	visible = false


func start_dialogue() -> void:
	visible = true
	current_index = 0
	arrow.visible = false
	await show_text(text_queue[current_index])


func _input(event):
	if event.is_action_pressed("ui_accept"):
		if playing_dialogue:
			skip_dialogue = true
		elif awaiting_input:
			arrow.visible = false
			awaiting_input = false
			if text_queue.size() > 1 and current_index == text_queue.size() - 2:
				second_to_last.emit()
			current_index += 1
			if current_index < text_queue.size():
				await show_text(text_queue[current_index])
			else:
				finished.emit()
				visible = false

func show_text(text: String) -> void:
	playing_dialogue = true
	skip_dialogue = false
	label.text = ""

	for i in text.length():
		if skip_dialogue:
			label.text = text
			break
		label.text += text[i]
		if text[i] != " ":
			sound.pitch_scale = randf_range(0.95, 1.05)
			sound.play()
		await get_tree().create_timer(speed).timeout

	playing_dialogue = false

	# Mostrar la flecha y esperar al jugador
	await get_tree().create_timer(0.3).timeout 
	arrow.visible = true
	awaiting_input = true
