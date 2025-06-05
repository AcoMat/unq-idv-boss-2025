extends Control

# ===================================
# UI SIMPLE DE STAMINA
# ===================================

# Nodos de la UI - CORREGIR RUTAS SIN CONTAINER
@onready var stamina_bar = $StaminaBar
@onready var stamina_bg = $StaminaBackground
@onready var stamina_label = $StaminaLabel

# Colores de la barra
var color_full = Color.CYAN
var color_half = Color.YELLOW  
var color_low = Color.RED
var color_empty = Color.DARK_RED

# Variables de animación
var target_width: float = 200.0
var max_width: float = 200.0

func _ready():
	print("UI de Stamina cargada")
	
	# Debug: Verificar que los nodos existen
	print("🔍 Verificando nodos:")
	print("  - StaminaBar: ", $StaminaBar if has_node("StaminaBar") else "NO ENCONTRADO")
	print("  - StaminaBackground: ", $StaminaBackground if has_node("StaminaBackground") else "NO ENCONTRADO")
	print("  - StaminaLabel: ", $StaminaLabel if has_node("StaminaLabel") else "NO ENCONTRADO")
	
	# Buscar y conectar al player
	call_deferred("connect_to_player")

func connect_to_player():
	"""Conecta automáticamente con el player"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("🔍 Player encontrado: ", player.name)
		
		if player.has_signal("stamina_changed"):
			player.stamina_changed.connect(_on_stamina_changed)
			print("✅ Conectado a stamina_changed")
		else:
			print("❌ Player no tiene señal stamina_changed")
			
		if player.has_signal("stamina_depleted"):
			player.stamina_depleted.connect(_on_stamina_depleted)
			print("✅ Conectado a stamina_depleted")
			
		if player.has_signal("stamina_recovered"):
			player.stamina_recovered.connect(_on_stamina_recovered)
			print("✅ Conectado a stamina_recovered")
		
		print("✅ UI conectada al player")
		
		# Inicializar con valores actuales
		_on_stamina_changed(player.get_current_stamina(), player.get_max_stamina())
	else:
		print("❌ No se encontró player con grupo 'player'")
		
		# Buscar por nombre como backup
		var all_players = get_tree().get_nodes_in_group("player")
		print("Players en grupo 'player': ", all_players)

func _on_stamina_changed(current: float, maximum: float):
	"""Actualiza la UI cuando cambia la stamina"""
	
	var percentage = current / maximum
	
	# Debug ANTES de hacer cambios
	print("🔧 ANTES - StaminaBar existe: ", stamina_bar != null)
	if stamina_bar:
		print("🔧 ANTES - Size: ", stamina_bar.size, " Scale: ", stamina_bar.scale)
	
	# Actualizar label
	if stamina_label:
		stamina_label.text = "%d/%d" % [int(current), int(maximum)]
		print("✅ Label actualizado: ", stamina_label.text)
	else:
		print("❌ StaminaLabel es null")
	
	# Cambiar la barra usando AMBOS métodos para asegurar que funcione
	if stamina_bar:
		# Método 1: Scale
		stamina_bar.scale.x = percentage
		
		# Método 2: Size (como backup)
		var new_width = 200 * percentage
		stamina_bar.size.x = new_width
		
		# Actualizar color
		update_bar_color(percentage)
		
		print("✅ Barra actualizada - Scale: ", stamina_bar.scale.x, " Size: ", stamina_bar.size.x)
	else:
		print("❌ StaminaBar es null")
	
	# Debug final
	print("📊 UI actualizada: ", int(current), "/", int(maximum), " (", int(percentage * 100), "%)")

func animate_bar():
	"""Anima la barra suavemente"""
	if not stamina_bar:
		return
	
	var tween = create_tween()
	tween.tween_property(stamina_bar, "size:x", target_width, 0.2)
	tween.parallel().tween_method(update_bar_color, stamina_bar.size.x / max_width, target_width / max_width, 0.2)

func update_bar_color(percentage: float):
	"""Actualiza el color según el porcentaje"""
	if not stamina_bar:
		return
	
	if percentage <= 0.0:
		stamina_bar.color = color_empty
	elif percentage <= 0.3:
		stamina_bar.color = color_low
	elif percentage <= 0.6:
		stamina_bar.color = color_half
	else:
		stamina_bar.color = color_full

func _on_stamina_depleted():
	"""Efecto cuando se agota la stamina"""
	print("🚨 UI: Stamina agotada")
	if stamina_bar:
		var flash_tween = create_tween()
		flash_tween.tween_property(stamina_bar, "modulate", Color.WHITE, 0.1)
		flash_tween.tween_property(stamina_bar, "modulate", Color.RED, 0.1)
		flash_tween.tween_property(stamina_bar, "modulate", Color.WHITE, 0.1)

func _on_stamina_recovered():
	"""Efecto cuando se recupera la stamina"""
	print("💚 UI: Stamina recuperada")
	if stamina_bar:
		var recovery_tween = create_tween()
		recovery_tween.tween_property(stamina_bar, "modulate", Color.GREEN, 0.2)
		recovery_tween.tween_property(stamina_bar, "modulate", Color.WHITE, 0.3)
