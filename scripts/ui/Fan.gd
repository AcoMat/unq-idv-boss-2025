extends Area2D

# ===================================
# CONFIGURACIÓN SIMPLE
# ===================================
@export var wind_force: float = 300.0  # 🔧 Aumenté de 100 a 300
@export var wind_direction: Vector2 = Vector2.LEFT
@export var is_active: bool = true
@export var max_push_velocity: float = 250.0
@export var air_force_multiplier: float = 0.4  # 🔧 Aumenté de 0.2 a 0.4

# ===================================
# VARIABLES
# ===================================
var debug_timer: float = 0.0
var players_in_area: Array = []

func _ready():
	# 🔧 CONFIGURACIÓN SEGURA: detectar múltiples capas comunes de player
	collision_layer = 4      # Capa 3 (ventilador)
	collision_mask = 4 + 2   # Detecta capa 2 (bit 4) + capa 1 (bit 2) por si acaso
	monitoring = true
	monitorable = true
	
	# Conectar señales
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _physics_process(delta: float):
	if not is_active:
		return
	
	# Debug extendido cada 2 segundos
	debug_timer += delta
	if debug_timer >= 2.0:
		debug_timer = 0.0
		debug_ventilador_extendido()
	
	# 🔧 SOLO usar detección manual para evitar conflictos
	detect_players_manually_limited()
	
	# Aplicar viento solo a players que están realmente en el área
	for player in players_in_area:
		if is_instance_valid(player):
			apply_wind_to_player(player, delta)

func detect_players_manually_limited():
	"""Detectar players manualmente SOLO dentro del área del CollisionShape2D"""
	var all_bodies = get_tree().get_nodes_in_group("player")
	
	for body in all_bodies:
		if not body is CharacterBody2D:
			continue
		
		# 🔧 Verificar si está realmente dentro del CollisionShape2D con un pequeño buffer
		var collision_shape = $CollisionShape2D
		if collision_shape and collision_shape.shape:
			# Convertir posición del player a coordenadas locales del Area2D
			var local_pos = to_local(body.global_position)
			
			# Verificar si está dentro del shape
			var is_inside = false
			if collision_shape.shape is RectangleShape2D:
				var rect_shape = collision_shape.shape as RectangleShape2D
				var half_size = rect_shape.size / 2
				# 🔧 Agregar buffer de 10 píxeles para evitar flicker
				var buffer = 10.0
				is_inside = (abs(local_pos.x) <= (half_size.x + buffer) and abs(local_pos.y) <= (half_size.y + buffer))
			elif collision_shape.shape is CircleShape2D:
				var circle_shape = collision_shape.shape as CircleShape2D
				# 🔧 Agregar buffer para círculos también
				is_inside = local_pos.length() <= (circle_shape.radius + 10.0)
			
			# Actualizar lista según si está dentro o fuera
			if is_inside and not players_in_area.has(body):
				_on_body_entered(body)
			elif not is_inside and players_in_area.has(body):
				_on_body_exited(body)

func check_area2d_detection():
	"""Verificar que el Area2D esté detectando correctamente"""
	var overlapping = get_overlapping_bodies()
	
	for body in overlapping:
		if is_player(body) and not players_in_area.has(body):
			print("🔧 Area2D detectó player que no estaba en lista: ", body.name)
			_on_body_entered(body)

func _on_body_entered(body: Node2D):
	if is_player(body):
		if not players_in_area.has(body):
			players_in_area.append(body)
			print("💨 Player ENTRÓ al ventilador: ", body.name)
		
		if body.has_method("enter_wind_zone"):
			body.enter_wind_zone(self)

func _on_body_exited(body: Node2D):
	if is_player(body):
		players_in_area.erase(body)
		print("💨 Player SALIÓ del ventilador: ", body.name)
		if body.has_method("exit_wind_zone"):
			body.exit_wind_zone(self)

func is_player(body: Node) -> bool:
	# Simplificar detección - más confiable
	return (
		body.is_in_group("player") or 
		body.has_method("is_player") or
		body.name.to_lower().contains("player")
	)

func apply_wind_to_player(player: CharacterBody2D, delta: float):
	# 🆕 Detectar si está en el suelo
	var is_grounded = player.is_on_floor() if player.has_method("is_on_floor") else true
	
	# 🆕 Aplicar multiplicador diferente según si está en suelo o aire
	var force_multiplier = 1.0 if is_grounded else air_force_multiplier
	
	# Calcular fuerza de viento CON el multiplicador
	var wind_push = wind_direction.normalized() * wind_force * delta * force_multiplier
	
	# Usar el nuevo sistema de viento del player
	if player.has_method("add_wind_force"):
		player.add_wind_force(wind_push)
		print("💨 Viento aplicado (", ("suelo" if is_grounded else "aire"), "): ", wind_push)
	else:
		# Fallback al método anterior
		player.velocity += wind_push
		player.velocity.x = clamp(player.velocity.x, -600, 600)
		player.velocity.y = clamp(player.velocity.y, -600, 600)
		print("💨 Usando método directo")

func debug_ventilador_extendido():
	print("=== DEBUG VENTILADOR ===")
	print("Activo: ", is_active)
	print("Players en área: ", players_in_area.size())
	print("Collision layer: ", collision_layer, " | mask: ", collision_mask)
	print("Monitoring: ", monitoring, " | Monitorable: ", monitorable)
	
	var all_bodies = get_overlapping_bodies()
	print("Bodies detectados por Area2D: ", all_bodies.size())
	
	for body in all_bodies:
		print("  - ", body.name, " (", body.get_class(), ") - Layer: ", body.collision_layer)
		if is_player(body):
			print("    ✅ ES PLAYER")
		else:
			print("    ❌ NO ES PLAYER")
	
	# Buscar players en toda la escena
	var scene_players = get_tree().get_nodes_in_group("player")
	print("Players en escena: ", scene_players.size())
	
	for sp in scene_players:
		var dist = global_position.distance_to(sp.global_position)
		print("  - ", sp.name, " distancia: ", dist, " | Layer: ", sp.collision_layer)
	
	# 🆕 Verificar configuración del CollisionShape2D
	var collision_shape = $CollisionShape2D
	if collision_shape:
		print("CollisionShape2D presente: ", collision_shape.shape != null)
		if collision_shape.shape:
			print("  Tipo: ", collision_shape.shape.get_class())
			if collision_shape.shape is RectangleShape2D:
				print("  Tamaño: ", collision_shape.shape.size)
			elif collision_shape.shape is CircleShape2D:
				print("  Radio: ", collision_shape.shape.radius)
	else:
		print("❌ NO HAY CollisionShape2D")

func force_test_wind():
	"""Función para probar el viento manualmente"""
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		var distance = global_position.distance_to(player.global_position)
		if distance < 300:
			print("🧪 FORZANDO viento en: ", player.name)
			if not players_in_area.has(player):
				players_in_area.append(player)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Enter
		debug_ventilador_extendido()
	
	if event.is_action_pressed("ui_select"):  # Tab - Forzar test
		force_test_wind()
