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


func _ready() -> void:
	## Initialize the dimension manager
	process_mode = Node.PROCESS_MODE_ALWAYS  # Continue processing even when paused
	print("[DimensionManager] Initialized in EDGE_VIEW")


func _unhandled_input(event: InputEvent) -> void:
	## Handle dimension shift input
	if event.is_action_pressed("shift_dimension"):
		request_dimension_shift()


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

	# Create transition tween
	var tween = create_tween()
	tween.tween_interval(transition_duration)
	tween.tween_callback(_complete_shift.bind(to_dimension))


## Complete the dimension shift after transition
func _complete_shift(new_dimension: Dimension) -> void:
	current_dimension = new_dimension
	is_transitioning = false
	dimension_shift_completed.emit(new_dimension)
	print("[DimensionManager] Shifted to: ", get_dimension_name(new_dimension))


## Set dimension directly without transition (for level initialization)
func set_dimension_immediate(dimension: Dimension) -> void:
	current_dimension = dimension
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
