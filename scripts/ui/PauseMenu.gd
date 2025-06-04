extends Control

func _ready():
	print("Menú de pausa cargado")
	# GameManager se encarga de las conexiones
	visible = false
	
	# Configurar process mode para funcionar cuando esté pausado
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
