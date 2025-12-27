class_name Player
extends CharacterBody2D
## Player - A. Square, the protagonist of Flatland
##
## This is the main player controller handling movement, jumping,
## and dimension-shift restrictions. The player can only shift
## dimensions when grounded to prevent mid-air exploits.

## Movement speed in pixels per second
@export var speed: float = 200.0

## Jump velocity (negative for upward movement)
@export var jump_velocity: float = -350.0

## Gravity acceleration
@export var gravity: float = 980.0

## Coyote time - grace period for jumping after leaving platform (seconds)
@export var coyote_time: float = 0.1

## Jump buffer - how long jump input is remembered before landing (seconds)
@export var jump_buffer_time: float = 0.1

## Whether the player can currently shift dimensions
@export var can_shift_dimension: bool = true

## Emitted when player touches a hazard
signal player_hurt()

## Emitted when player collects an item
signal item_collected(item_type: String)

## Emitted when player enters a trigger zone
signal trigger_entered(trigger_name: String)

## Animation states
enum AnimState { IDLE, WALK, JUMP, FALL }
var current_anim_state: AnimState = AnimState.IDLE

## Internal state
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false
var _is_dimension_shifting: bool = false

## Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null


func _ready() -> void:
	# Set up collision layers
	collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_PLAYER)
	_update_collision_mask()

	# Connect to dimension signals
	DimensionManager.dimension_changed.connect(_on_dimension_changed)
	DimensionManager.dimension_shift_started.connect(_on_dimension_shift_started)
	DimensionManager.dimension_shift_completed.connect(_on_dimension_shift_completed)

	print("[Player] Initialized")


func _exit_tree() -> void:
	# Clean up connections
	if DimensionManager.dimension_changed.is_connected(_on_dimension_changed):
		DimensionManager.dimension_changed.disconnect(_on_dimension_changed)
	if DimensionManager.dimension_shift_started.is_connected(_on_dimension_shift_started):
		DimensionManager.dimension_shift_started.disconnect(_on_dimension_shift_started)
	if DimensionManager.dimension_shift_completed.is_connected(_on_dimension_shift_completed):
		DimensionManager.dimension_shift_completed.disconnect(_on_dimension_shift_completed)


func _physics_process(delta: float) -> void:
	# Skip movement during dimension shift
	if _is_dimension_shifting:
		return

	# Handle coyote time
	_update_coyote_time(delta)

	# Handle jump buffer
	_update_jump_buffer(delta)

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump input
	_handle_jump()

	# Handle horizontal movement
	_handle_movement()

	# Handle dimension shift input
	_handle_dimension_shift()

	# Apply movement
	move_and_slide()

	# Update animation state
	_update_animation()

	# Track floor state for coyote time
	_was_on_floor = is_on_floor()


func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	elif _coyote_timer > 0:
		_coyote_timer -= delta


func _update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	elif _jump_buffer_timer > 0:
		_jump_buffer_timer -= delta


func _handle_jump() -> void:
	# Check for buffered or new jump input
	var wants_jump = _jump_buffer_timer > 0 or Input.is_action_just_pressed("jump")
	var can_jump = is_on_floor() or _coyote_timer > 0

	if wants_jump and can_jump:
		velocity.y = jump_velocity
		_coyote_timer = 0  # Consume coyote time
		_jump_buffer_timer = 0  # Consume jump buffer


func _handle_movement() -> void:
	var direction = Input.get_axis("move_left", "move_right")

	if direction != 0:
		velocity.x = direction * speed
		# Flip sprite based on direction
		if sprite:
			sprite.flip_h = direction < 0
	else:
		# Apply friction/deceleration
		velocity.x = move_toward(velocity.x, 0, speed * 0.2)


func _handle_dimension_shift() -> void:
	# Only check for dimension shift if we can and are grounded
	if not can_shift_dimension:
		return

	if Input.is_action_just_pressed("shift_dimension"):
		if is_on_floor():
			# Let DimensionManager handle the actual shift
			# The input will be caught by its _unhandled_input
			pass
		else:
			# Visual/audio feedback that shift is blocked
			_on_shift_blocked()


func _on_shift_blocked() -> void:
	## Called when player tries to shift mid-air
	# TODO: Add screen shake, sound effect, or visual indicator
	print("[Player] Dimension shift blocked - not grounded")


func _update_animation() -> void:
	var new_state: AnimState

	if not is_on_floor():
		if velocity.y < 0:
			new_state = AnimState.JUMP
		else:
			new_state = AnimState.FALL
	elif abs(velocity.x) > 10:
		new_state = AnimState.WALK
	else:
		new_state = AnimState.IDLE

	if new_state != current_anim_state:
		current_anim_state = new_state
		_play_animation(new_state)


func _play_animation(state: AnimState) -> void:
	if not animation_player:
		return

	var anim_name: String
	match state:
		AnimState.IDLE:
			anim_name = "idle"
		AnimState.WALK:
			anim_name = "walk"
		AnimState.JUMP:
			anim_name = "jump"
		AnimState.FALL:
			anim_name = "fall"

	# Add dimension suffix if we have dimension-specific animations
	var dimension_suffix = "_edge" if DimensionManager.is_edge_view() else "_top"
	var full_anim_name = anim_name + dimension_suffix

	if animation_player.has_animation(full_anim_name):
		animation_player.play(full_anim_name)
	elif animation_player.has_animation(anim_name):
		animation_player.play(anim_name)


func _on_dimension_shift_started(_from: DimensionManager.Dimension, _to: DimensionManager.Dimension) -> void:
	_is_dimension_shifting = true
	# Freeze player during transition
	velocity = Vector2.ZERO


func _on_dimension_shift_completed(_new_dim: DimensionManager.Dimension) -> void:
	_is_dimension_shifting = false
	_update_collision_mask()


func _on_dimension_changed(_new_dimension: DimensionManager.Dimension) -> void:
	# Update collision mask for new dimension
	_update_collision_mask()
	# Update animation
	_play_animation(current_anim_state)


func _update_collision_mask() -> void:
	## Update collision mask based on current dimension
	collision_mask = 0

	# Always collide with always-solid layer
	collision_mask |= DimensionManager.get_layer_bit(DimensionManager.LAYER_ALWAYS_SOLID)

	# Add dimension-specific layer
	if DimensionManager.is_edge_view():
		collision_mask |= DimensionManager.get_layer_bit(DimensionManager.LAYER_EDGE_VIEW_SOLID)
	else:
		collision_mask |= DimensionManager.get_layer_bit(DimensionManager.LAYER_TOP_VIEW_SOLID)

	# Always collide with interactables and triggers
	collision_mask |= DimensionManager.get_layer_bit(DimensionManager.LAYER_INTERACTABLES)
	collision_mask |= DimensionManager.get_layer_bit(DimensionManager.LAYER_TRIGGERS)


## Public API for external control

## Kill the player and trigger restart
func die() -> void:
	player_hurt.emit()
	# Disable input briefly
	set_physics_process(false)
	# Let GameManager handle restart
	GameManager.restart_level()


## Teleport player to a position
func teleport_to(target_position: Vector2) -> void:
	global_position = target_position
	velocity = Vector2.ZERO


## Enable or disable player movement
func set_movement_enabled(enabled: bool) -> void:
	set_physics_process(enabled)


## Enable or disable dimension shifting for this player
func set_dimension_shift_enabled(enabled: bool) -> void:
	can_shift_dimension = enabled
