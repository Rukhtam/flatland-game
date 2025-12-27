@icon("res://assets/sprites/icons/dimensional_static.svg")
class_name DimensionalStaticBody
extends StaticBody2D
## DimensionalStaticBody - A StaticBody2D that responds to dimension changes
##
## Use this for platforms, walls, and obstacles that need physics collision
## and change behavior between edge-view and top-view.
##
## This is a convenience class that combines the physics body and dimensional
## behavior into a single node, simplifying scene structure.

## Whether this object is visible in edge view
@export var visible_in_edge_view: bool = true

## Whether this object is visible in top view
@export var visible_in_top_view: bool = true

## Whether this object has collision in edge view
@export var solid_in_edge_view: bool = true

## Whether this object has collision in top view
@export var solid_in_top_view: bool = true

## Transition effect duration
@export var transition_duration: float = 0.2

## Sprite for edge view (optional - will show/hide based on dimension)
@export var edge_view_sprite: Sprite2D

## Sprite for top view (optional - will show/hide based on dimension)
@export var top_view_sprite: Sprite2D

## Visual tween reference
var _visual_tween: Tween


func _ready() -> void:
	# Connect to dimension signals
	DimensionManager.dimension_changed.connect(_on_dimension_changed)

	# Initial state
	_apply_dimension_state(DimensionManager.current_dimension, true)


func _exit_tree() -> void:
	if DimensionManager.dimension_changed.is_connected(_on_dimension_changed):
		DimensionManager.dimension_changed.disconnect(_on_dimension_changed)


func _on_dimension_changed(new_dimension: DimensionManager.Dimension) -> void:
	_apply_dimension_state(new_dimension, false)


func _apply_dimension_state(dimension: DimensionManager.Dimension, instant: bool) -> void:
	var is_edge = dimension == DimensionManager.Dimension.EDGE_VIEW
	var should_be_visible = visible_in_edge_view if is_edge else visible_in_top_view
	var should_be_solid = solid_in_edge_view if is_edge else solid_in_top_view

	# Handle visibility
	_apply_visibility(should_be_visible, instant)

	# Handle sprites if configured
	_apply_sprite_state(is_edge)

	# Handle collision
	_apply_collision(should_be_solid)


func _apply_visibility(target_visible: bool, instant: bool) -> void:
	if instant or transition_duration <= 0:
		visible = target_visible
		modulate.a = 1.0 if target_visible else 0.0
	else:
		if _visual_tween and _visual_tween.is_valid():
			_visual_tween.kill()

		_visual_tween = create_tween()
		_visual_tween.set_ease(Tween.EASE_IN_OUT)
		_visual_tween.set_trans(Tween.TRANS_SINE)

		if target_visible:
			visible = true
			_visual_tween.tween_property(self, "modulate:a", 1.0, transition_duration)
		else:
			_visual_tween.tween_property(self, "modulate:a", 0.0, transition_duration)
			_visual_tween.tween_callback(func(): visible = false)


func _apply_sprite_state(is_edge_view: bool) -> void:
	if edge_view_sprite:
		edge_view_sprite.visible = is_edge_view
	if top_view_sprite:
		top_view_sprite.visible = not is_edge_view


func _apply_collision(should_be_solid: bool) -> void:
	# Disable all collision if not solid
	if not should_be_solid:
		collision_layer = 0
		collision_mask = 0
		return

	# Set collision layer based on which dimensions this is solid in
	collision_layer = 0
	if solid_in_edge_view and solid_in_top_view:
		collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_ALWAYS_SOLID)
	elif solid_in_edge_view:
		collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_EDGE_VIEW_SOLID)
	elif solid_in_top_view:
		collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_TOP_VIEW_SOLID)

	# Always interact with player
	collision_mask = DimensionManager.get_layer_bit(DimensionManager.LAYER_PLAYER)
