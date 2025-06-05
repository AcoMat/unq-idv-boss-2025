# Script para TestScene.tscn
extends Node2D

func _ready():
	print("Escena de prueba cargada")
	print("Controles:")
	print("- Flechas/WASD: Mover")
	print("- Espacio: Saltar")
	print("- Pisa la plataforma roja para probarla")

func _input(event):
	# QUITAR EL REINICIO AUTOMÁTICO - era esto lo que causaba el problema
	# R para reiniciar la escena MANUALMENTE
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_R):  # R + Enter
		print("Reiniciando escena manualmente...")
		get_tree().reload_current_scene()
		
	# ESC para salir
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
