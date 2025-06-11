extends Area2D

## Wind Zone Controller
## 
## Creates a wind effect that pushes players when they enter the collision area.
## The wind force is applied continuously while the player remains within the zone.
## 
## @author: Your Name
## @version: 1.0

# ===================================
# EXPORTED PROPERTIES
# ===================================


## Strength of the wind force applied to players
@export var wind_force: float = 64.0

## Direction vector indicating wind flow (normalized automatically)

@export var wind_direction: Vector2 = Vector2.LEFT

## Whether the wind zone is currently active
@export var is_active: bool = true


# ===================================
# PRIVATE VARIABLES
# ===================================

## Timer for debug output throttling
var debug_timer: float = 0.0


# ===================================
# INITIALIZATION
# ===================================

func _ready() -> void:
	_setup_collision_detection()

## Configure collision layers and monitoring settings
func _setup_collision_detection() -> void:
	collision_layer = 0              # Wind zone doesn't need to be on any layer
	collision_mask = 4294967295      # Detect all collision layers
	monitoring = true                # Enable area detection
	monitorable = false             # Other areas don't need to detect this

# ===================================
# MAIN LOOP
# ===================================

func _physics_process(delta: float) -> void:
	# Skip processing if wind zone is disabled
	if not is_active:
		return
	
	# Throttle debug output to prevent console spam
	_update_debug_timer(delta)
	
	# Apply wind force to all players currently in the area
	_process_overlapping_bodies(delta)

## Update debug timer and trigger debug output periodically
func _update_debug_timer(delta: float) -> void:
	debug_timer += delta
	if debug_timer >= 2.0:
		debug_timer = 0.0
		_debug_current_state()

## Check all bodies in the area and apply wind to players
func _process_overlapping_bodies(delta: float) -> void:
	var overlapping_bodies = get_overlapping_bodies()
	
	for body in overlapping_bodies:
		if _is_player_character(body):
			_apply_wind_force(body, delta)

# ===================================
# PLAYER DETECTION
# ===================================

## Determine if a given body is a player character
## @param body: The physics body to check
## @return: True if the body represents a player
func _is_player_character(body: Node) -> bool:
	return body.is_in_group("player")

# ===================================
# WIND PHYSICS
# ===================================

## Apply wind force to a player character
## @param player: The player CharacterBody2D to affect
## @param delta: Frame delta time for smooth movement
func _apply_wind_force(player: CharacterBody2D, delta: float) -> void:
	# Calculate frame-independent wind force
	var wind_impulse = wind_direction.normalized() * wind_force * delta
	
	# Use player's wind system if available, otherwise apply directly
	if player.has_method("add_wind_force"):
		player.add_wind_force(wind_impulse)
	else:
		_apply_direct_velocity_modification(player, wind_impulse)

## Fallback method for players without wind system integration
## @param player: The player to modify
## @param impulse: The velocity change to apply
func _apply_direct_velocity_modification(player: CharacterBody2D, impulse: Vector2) -> void:
	player.velocity += impulse
	
	# Prevent excessive velocity accumulation
	player.velocity.x = clamp(player.velocity.x, -600, 600)
	player.velocity.y = clamp(player.velocity.y, -600, 600)

# ===================================
# DEBUG UTILITIES
# ===================================

## Output current wind zone state for debugging
func _debug_current_state() -> void:
	var overlapping_bodies = get_overlapping_bodies()
	
	if overlapping_bodies.size() == 0:
		return  # Silent when no bodies present
	
	# Log players currently affected by wind
	for body in overlapping_bodies:
		if _is_player_character(body):
			pass  # Player found - wind is being applied

## Manual debug trigger for development
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_debug_current_state()
