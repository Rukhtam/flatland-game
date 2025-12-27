@icon("res://assets/sprites/icons/dimensional_object.svg")
class_name DimensionalObject
extends Node2D
## DimensionalObject - Base class for all dimension-aware objects
##
## This class provides the foundation for objects that change behavior
## based on the current dimensional view. Extend this class for platforms,
## obstacles, collectibles, and any geometry that responds to dimension shifts.
##
## Usage:
##   1. Create a scene with this script attached to a Node2D
##   2. Add child nodes: Sprite2D, CollisionShape2D (inside StaticBody2D/Area2D)
##   3. Configure visibility and solidity for each dimension
##   4. The object will automatically update when dimension changes

## Whether this object is visible in edge view (side-scrolling)
@export var visible_in_edge_view: bool = true

## Whether this object is visible in top view (bird's eye)
@export var visible_in_top_view: bool = true

## Whether this object has collision in edge view
@export var solid_in_edge_view: bool = true

## Whether this object has collision in top view
@export var solid_in_top_view: bool = true

## Optional transition effect duration (0 = instant)
@export var transition_duration: float = 0.2

## Visual tween for smooth transitions
var _visual_tween: Tween

## Reference to physics body if present
@onready var _physics_body: PhysicsBody2D = _find_physics_body()


func _ready() -> void:
	# Connect to dimension manager
	DimensionManager.dimension_changed.connect(_on_dimension_changed)
	DimensionManager.dimension_shift_started.connect(_on_dimension_shift_started)

	# Apply initial state
	_apply_dimension_state(DimensionManager.current_dimension, true)


func _exit_tree() -> void:
	# Clean up signal connections
	if DimensionManager.dimension_changed.is_connected(_on_dimension_changed):
		DimensionManager.dimension_changed.disconnect(_on_dimension_changed)
	if DimensionManager.dimension_shift_started.is_connected(_on_dimension_shift_started):
		DimensionManager.dimension_shift_started.disconnect(_on_dimension_shift_started)


## Find the physics body child (if any)
func _find_physics_body() -> PhysicsBody2D:
	for child in get_children():
		if child is PhysicsBody2D:
			return child
	return null


## Called when dimension shift starts (for pre-transition effects)
func _on_dimension_shift_started(from_dim: DimensionManager.Dimension, to_dim: DimensionManager.Dimension) -> void:
	# Override in subclasses for custom pre-transition behavior
	pass


## Called when dimension changes
func _on_dimension_changed(new_dimension: DimensionManager.Dimension) -> void:
	_apply_dimension_state(new_dimension, false)


## Apply the appropriate state for the given dimension
func _apply_dimension_state(dimension: DimensionManager.Dimension, instant: bool) -> void:
	var should_be_visible: bool
	var should_be_solid: bool

	if dimension == DimensionManager.Dimension.EDGE_VIEW:
		should_be_visible = visible_in_edge_view
		should_be_solid = solid_in_edge_view
	else:
		should_be_visible = visible_in_top_view
		should_be_solid = solid_in_top_view

	# Apply visibility
	_set_visibility(should_be_visible, instant)

	# Apply collision
	_set_collision(should_be_solid, dimension)


## Set visibility with optional transition
func _set_visibility(is_visible: bool, instant: bool) -> void:
	if instant or transition_duration <= 0:
		visible = is_visible
		modulate.a = 1.0 if is_visible else 0.0
	else:
		# Cancel existing tween
		if _visual_tween and _visual_tween.is_valid():
			_visual_tween.kill()

		_visual_tween = create_tween()
		_visual_tween.set_ease(Tween.EASE_IN_OUT)
		_visual_tween.set_trans(Tween.TRANS_SINE)

		if is_visible:
			visible = true
			_visual_tween.tween_property(self, "modulate:a", 1.0, transition_duration)
		else:
			_visual_tween.tween_property(self, "modulate:a", 0.0, transition_duration)
			_visual_tween.tween_callback(func(): visible = false)


## Set collision layers based on solidity and dimension
func _set_collision(is_solid: bool, dimension: DimensionManager.Dimension) -> void:
	if not _physics_body:
		return

	# Reset collision layer
	_physics_body.collision_layer = 0
	_physics_body.collision_mask = 0

	if not is_solid:
		return

	# Set appropriate collision layer based on which dimension this is solid in
	if solid_in_edge_view and solid_in_top_view:
		# Solid in both - use always solid layer
		_physics_body.collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_ALWAYS_SOLID)
	elif solid_in_edge_view:
		_physics_body.collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_EDGE_VIEW_SOLID)
	elif solid_in_top_view:
		_physics_body.collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_TOP_VIEW_SOLID)

	# Set mask to interact with player
	_physics_body.collision_mask = DimensionManager.get_layer_bit(DimensionManager.LAYER_PLAYER)


## Check if object is currently visible in the active dimension
func is_visible_in_current_dimension() -> bool:
	if DimensionManager.is_edge_view():
		return visible_in_edge_view
	else:
		return visible_in_top_view


## Check if object is currently solid in the active dimension
func is_solid_in_current_dimension() -> bool:
	if DimensionManager.is_edge_view():
		return solid_in_edge_view
	else:
		return solid_in_top_view
