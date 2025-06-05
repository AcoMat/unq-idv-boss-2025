extends Area2D

# ===================================
# CONFIGURACIÓN SIMPLE
# ===================================
@export var wind_force: float = 100.0
@export var wind_direction: Vector2 = Vector2.LEFT
@export var is_active: bool = true
@export var max_push_velocity: float = 250.0

# ===================================
# VARIABLES
# ===================================
var debug_timer: float = 0.0
var players_in_area: Array = []

func _ready():
	print("💨 ========== VENTILADOR INICIADO ==========")
	print("💨 Fuerza: ", wind_force)
	print("💨 Dirección: ", wind_direction)
	
	# FORZAR configuración de capas para coincidir con el player
	collision_layer = 4   # Capa 3 (ventilador)
	collision_mask = 1024 # Detecta capa 11 (player está en layer 10, que es bit 1024)
	monitoring = true
	monitorable = true
	
	print("🔧 Mi Collision Layer: ", collision_layer)
	print("🔧 Mi Collision Mask: ", collision_mask)
	print("🔧 Monitoring: ", monitoring)
	print("🔧 Monitorable: ", monitorable)
	
	# Conectar señales
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	# BUSCAR PLAYER EN LA ESCENA
	call_deferred("find_players_in_scene")

func find_character_bodies(node: Node, bodies_array: Array):
	"""Función auxiliar para encontrar CharacterBody2D recursivamente"""
	if node is CharacterBody2D:
		bodies_array.append(node)
	
	for child in node.get_children():
		find_character_bodies(child, bodies_array)

func find_players_in_scene():
	"""Buscar todos los posibles players"""
	print("🔍 ========== BUSCANDO PLAYERS ==========")
	
	# Método 1: Por grupo
	var players_by_group = get_tree().get_nodes_in_group("player")
	print("🔍 Players por grupo 'player': ", players_by_group.size())
	for p in players_by_group:
		print("  - ", p.name, " en pos: ", p.global_position)
		print("    Collision Layer: ", p.collision_layer if "collision_layer" in p else "N/A")
		print("    Collision Mask: ", p.collision_mask if "collision_mask" in p else "N/A")
	
	# Método 2: Por clase CharacterBody2D
	var character_bodies = []
	find_character_bodies(get_tree().root, character_bodies)
	
	print("🔍 CharacterBody2D encontrados: ", character_bodies.size())
	for cb in character_bodies:
		print("  - ", cb.name, " en pos: ", cb.global_position)
		print("    Collision Layer: ", cb.collision_layer)
		print("    Collision Mask: ", cb.collision_mask)
		print("    Grupos: ", cb.get_groups())
	
	# Método 3: Distancia al ventilador
	print("🔍 Mi posición: ", global_position)
	var nearby_bodies = []
	for cb in character_bodies:
		var distance = global_position.distance_to(cb.global_position)
		print("  - Distancia a ", cb.name, ": ", distance)
		if distance < 500:  # Dentro de 500 píxeles
			nearby_bodies.append(cb)
	
	print("🔍 Bodies cercanos: ", nearby_bodies.size())
	print("🔍 ==========================================")

func _physics_process(delta: float):
	if not is_active:
		return
	
	# Debug extendido cada 2 segundos
	debug_timer += delta
	if debug_timer >= 2.0:
		debug_timer = 0.0
		debug_ventilador_extendido()
	
	# Método alternativo: detectar manualmente por distancia
	detect_players_manually()
	
	# Aplicar viento
	for player in players_in_area:
		if is_instance_valid(player):
			apply_wind_to_player(player, delta)

func detect_players_manually():
	"""Detectar players manualmente por distancia"""
	var all_bodies = get_tree().get_nodes_in_group("player")
	
	for body in all_bodies:
		if not body is CharacterBody2D:
			continue
			
		var distance = global_position.distance_to(body.global_position)
		var is_close = distance < 200  # Ajusta esta distancia según tu ventilador
		
		if is_close and not players_in_area.has(body):
			print("🎯 Player detectado manualmente: ", body.name, " dist: ", distance)
			_on_body_entered(body)
		elif not is_close and players_in_area.has(body):
			print("🎯 Player salió (manual): ", body.name)
			_on_body_exited(body)

func _on_body_entered(body: Node2D):
	"""Cuando un cuerpo entra al área del ventilador"""
	print("📥 BODY ENTERED: ", body.name, " (", body.get_class(), ")")
	
	if is_player(body):
		print("✅ ES PLAYER - agregando a lista")
		if not players_in_area.has(body):
			players_in_area.append(body)
		
		if body.has_method("enter_wind_zone"):
			body.enter_wind_zone(self)
	else:
		print("❌ NO ES PLAYER")

func _on_body_exited(body: Node2D):
	"""Cuando un cuerpo sale del área del ventilador"""
	print("📤 BODY EXITED: ", body.name)
	
	if is_player(body):
		players_in_area.erase(body)
		if body.has_method("exit_wind_zone"):
			body.exit_wind_zone(self)

func is_player(body: Node) -> bool:
	"""Verificar si el cuerpo es el jugador - VERSIÓN EXTENDIDA"""
	var checks = []
	
	# Check 1: Método is_player()
	var has_method = body.has_method("is_player")
	checks.append("has_method: " + str(has_method))
	
	# Check 2: Grupo "player"
	var in_group = body.is_in_group("player")
	checks.append("in_group: " + str(in_group))
	
	# Check 3: Nombre contiene "player"
	var name_check = body.name.to_lower().contains("player")
	checks.append("name_check: " + str(name_check))
	
	# Check 4: Es CharacterBody2D
	var is_character = body is CharacterBody2D
	checks.append("is_CharacterBody2D: " + str(is_character))
	
	print("🔍 Checks para ", body.name, ": ", checks)
	
	var result = has_method or in_group or name_check or is_character
	print("🔍 Resultado final: ", result)
	
	return result

func apply_wind_to_player(player: CharacterBody2D, delta: float):
	"""Aplicar fuerza de viento al jugador usando el nuevo sistema"""
	print("💨 APLICANDO VIENTO A: ", player.name)
	
	# Calcular fuerza de viento
	var wind_push = wind_direction.normalized() * wind_force * delta
	
	# Usar el nuevo sistema de viento del player
	if player.has_method("add_wind_force"):
		player.add_wind_force(wind_push)
		print("💨 Usando nuevo sistema de viento")
	else:
		# Fallback al método anterior
		player.velocity += wind_push
		player.velocity.x = clamp(player.velocity.x, -600, 600)
		player.velocity.y = clamp(player.velocity.y, -600, 600)
		print("💨 Usando método directo")
	
	print("💨 Fuerza aplicada: ", wind_push)

func debug_ventilador_extendido():
	"""Debug completo del ventilador"""
	print("🔧 ========== DEBUG VENTILADOR ==========")
	print("🔧 Activo: ", is_active)
	print("🔧 Mi posición: ", global_position)
	print("🔧 Mi Layer: ", collision_layer)
	print("🔧 Mi Mask: ", collision_mask)
	print("🔧 Monitoring: ", monitoring)
	
	var all_bodies = get_overlapping_bodies()
	print("🔧 Bodies detectados por área: ", all_bodies.size())
	
	for body in all_bodies:
		print("  📦 ", body.name, " (", body.get_class(), ")")
		if "collision_layer" in body:
			print("      Layer: ", body.collision_layer)
		if "collision_mask" in body:
			print("      Mask: ", body.collision_mask)
		print("      Grupos: ", body.get_groups())
		print("      Es player: ", is_player(body))
	
	print("🔧 Players en mi lista: ", players_in_area.size())
	for p in players_in_area:
		print("  🎮 ", p.name, " pos: ", p.global_position)
	
	# Buscar players en toda la escena
	var scene_players = get_tree().get_nodes_in_group("player")
	print("🔧 Players en escena: ", scene_players.size())
	for sp in scene_players:
		var dist = global_position.distance_to(sp.global_position)
		print("  🎮 ", sp.name, " dist: ", dist, " layer: ", sp.collision_layer)
	
	print("🔧 =====================================")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Enter
		debug_ventilador_extendido()
	
	if event.is_action_pressed("ui_select"):  # Tab - Forzar detección
		print("🔄 FORZANDO DETECCIÓN MANUAL...")
		var players = get_tree().get_nodes_in_group("player")
		for player in players:
			var distance = global_position.distance_to(player.global_position)
			print("🔄 Player ", player.name, " a distancia: ", distance)
			if distance < 300:  # Si está cerca
				print("🔄 Forzando entrada de ", player.name)
				_on_body_entered(player)
