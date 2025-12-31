extends Node
## DimensionManager - Global singleton managing dimensional state
##
## This autoload manages the core dimension-shifting mechanic of Flatland.
## All DimensionalObjects subscribe to the dimension_changed signal to
## update their visibility and collision states.
##
## Usage:
##   DimensionManager.shift_dimension()  # Toggle between views
##   DimensionManager.current_dimension  # Get current state
##   DimensionManager.dimension_changed.connect(_on_dimension_changed)

## Enum defining the two dimensional views in the game
enum Dimension {
	EDGE_VIEW,  ## Side-scrolling perspective - shapes appear as lines
	TOP_VIEW    ## Bird's eye perspective - reveals true geometric shapes
}

## Emitted when the dimension changes. Passes the new dimension state.
signal dimension_changed(new_dimension: Dimension)

## Emitted just before dimension shift begins (for transition effects)
signal dimension_shift_started(from_dimension: Dimension, to_dimension: Dimension)

## Emitted when dimension shift transition completes
signal dimension_shift_completed(new_dimension: Dimension)

## The current dimensional view state
var current_dimension: Dimension = Dimension.EDGE_VIEW:
	set(value):
		if current_dimension != value:
			var old_dimension = current_dimension
			current_dimension = value
			dimension_changed.emit(current_dimension)
	get:
		return current_dimension

## Whether dimension shifting is currently allowed
var shift_enabled: bool = true

## Whether a dimension shift transition is in progress
var is_transitioning: bool = false

## Duration of the dimension shift transition effect (in seconds)
@export var transition_duration: float = 0.3

## Collision layer constants for easy reference
const LAYER_EDGE_VIEW_SOLID: int = 1
const LAYER_TOP_VIEW_SOLID: int = 2
const LAYER_ALWAYS_SOLID: int = 3
const LAYER_PLAYER: int = 4
const LAYER_INTERACTABLES: int = 5
const LAYER_TRIGGERS: int = 6

## Visual effect colors for dimensions
## Edge View: Dark blue-grey (the default Flatland color)
const COLOR_EDGE_VIEW: Color = Color(0.051, 0.067, 0.090, 1.0)  # #0D1117
## Top View: Dark purple-magenta tint (reveals hidden geometry)
const COLOR_TOP_VIEW: Color = Color(0.12, 0.05, 0.15, 1.0)  # Deep purple

## Visual overlay for transition effects
var _transition_overlay: ColorRect
var _transition_canvas: CanvasLayer


func _ready() -> void:
	## Initialize the dimension manager
	process_mode = Node.PROCESS_MODE_ALWAYS  # Continue processing even when paused

	# Create visual transition overlay
	_create_transition_overlay()

	# Set initial background color
	_update_background_color(current_dimension, true)

	print("[DimensionManager] Initialized in EDGE_VIEW")


## Create the visual overlay used for dimension shift transitions
func _create_transition_overlay() -> void:
	# Create a canvas layer that sits above everything
	_transition_canvas = CanvasLayer.new()
	_transition_canvas.layer = 100  # Above all game layers
	_transition_canvas.name = "DimensionTransitionCanvas"
	add_child(_transition_canvas)

	# Create the overlay ColorRect
	_transition_overlay = ColorRect.new()
	_transition_overlay.name = "TransitionOverlay"
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.color = Color(1, 1, 1, 0)  # Start fully transparent
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	_transition_canvas.add_child(_transition_overlay)


# Note: Dimension shift input is handled by the Player script
# to enforce the "must be grounded" rule. The player calls
# request_dimension_shift() when appropriate.


## Request a dimension shift. Can be called externally or via input.
## Returns true if shift was initiated, false if blocked.
func request_dimension_shift() -> bool:
	if not shift_enabled:
		print("[DimensionManager] Shift blocked - shifting disabled")
		return false

	if is_transitioning:
		print("[DimensionManager] Shift blocked - transition in progress")
		return false

	shift_dimension()
	return true


## Immediately shift to the opposite dimension
func shift_dimension() -> void:
	var from_dimension = current_dimension
	var to_dimension = Dimension.TOP_VIEW if current_dimension == Dimension.EDGE_VIEW else Dimension.EDGE_VIEW

	is_transitioning = true
	dimension_shift_started.emit(from_dimension, to_dimension)

	# Play visual transition effect
	_play_transition_effect(from_dimension, to_dimension)


## Play the visual transition effect between dimensions
func _play_transition_effect(from_dim: Dimension, to_dim: Dimension) -> void:
	# Determine flash color based on target dimension
	var flash_color: Color
	if to_dim == Dimension.TOP_VIEW:
		# Shifting to top view - purple flash
		flash_color = Color(0.514, 0.224, 0.925, 0.6)  # Purple (#8338EC with alpha)
	else:
		# Shifting to edge view - blue flash
		flash_color = Color(0.227, 0.525, 1.0, 0.6)  # Blue (#3A86FF with alpha)

	# Create transition tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)

	# Phase 1: Flash in (quick)
	tween.tween_property(_transition_overlay, "color", flash_color, transition_duration * 0.3)

	# Phase 2: Change dimension at peak of flash
	tween.tween_callback(func():
		current_dimension = to_dim
		_update_background_color(to_dim, false)
	)

	# Phase 3: Flash out (slower fade)
	tween.tween_property(_transition_overlay, "color", Color(1, 1, 1, 0), transition_duration * 0.7)

	# Phase 4: Complete transition
	tween.tween_callback(_complete_shift.bind(to_dim))


## Update the game background color for the dimension
func _update_background_color(dimension: Dimension, instant: bool) -> void:
	var target_color = COLOR_EDGE_VIEW if dimension == Dimension.EDGE_VIEW else COLOR_TOP_VIEW

	if instant:
		RenderingServer.set_default_clear_color(target_color)
	else:
		# Animate background color change
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)

		# We need to manually tween the clear color since it's not a property
		var from_color = RenderingServer.get_default_clear_color()
		tween.tween_method(
			func(c: Color): RenderingServer.set_default_clear_color(c),
			from_color,
			target_color,
			transition_duration * 0.5
		)


## Complete the dimension shift after transition
func _complete_shift(new_dimension: Dimension) -> void:
	is_transitioning = false
	dimension_shift_completed.emit(new_dimension)
	print("[DimensionManager] Shifted to: ", get_dimension_name(new_dimension))


## Set dimension directly without transition (for level initialization)
func set_dimension_immediate(dimension: Dimension) -> void:
	current_dimension = dimension
	_update_background_color(dimension, true)
	print("[DimensionManager] Set immediate to: ", get_dimension_name(dimension))


## Enable or disable dimension shifting (for tutorials, cutscenes, etc.)
func set_shift_enabled(enabled: bool) -> void:
	shift_enabled = enabled
	print("[DimensionManager] Shifting ", "enabled" if enabled else "disabled")


## Check if currently in edge view
func is_edge_view() -> bool:
	return current_dimension == Dimension.EDGE_VIEW


## Check if currently in top view
func is_top_view() -> bool:
	return current_dimension == Dimension.TOP_VIEW


## Get human-readable name for a dimension
func get_dimension_name(dimension: Dimension) -> String:
	match dimension:
		Dimension.EDGE_VIEW:
			return "Edge View"
		Dimension.TOP_VIEW:
			return "Top View"
		_:
			return "Unknown"


## Get the collision mask for the current dimension
## Objects should use this to determine what they collide with
func get_current_collision_mask() -> int:
	var mask: int = 0
	# Always include the always-solid layer
	mask |= (1 << (LAYER_ALWAYS_SOLID - 1))

	# Add dimension-specific layer
	if current_dimension == Dimension.EDGE_VIEW:
		mask |= (1 << (LAYER_EDGE_VIEW_SOLID - 1))
	else:
		mask |= (1 << (LAYER_TOP_VIEW_SOLID - 1))

	return mask


## Get the collision layer bit for a specific layer number
static func get_layer_bit(layer: int) -> int:
	return 1 << (layer - 1)
