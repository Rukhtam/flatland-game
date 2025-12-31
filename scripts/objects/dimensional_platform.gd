class_name DimensionalPlatform
extends StaticBody2D
## DimensionalPlatform - A platform that exists only in specific dimensions
##
## This platform becomes solid/visible based on the current dimension.
## Use this for puzzles where the player needs to shift dimensions to
## make platforms appear or disappear.
##
## Collision layers used:
## - Layer 1: Edge View only
## - Layer 2: Top View only
## - Layer 4: Always solid (both dimensions)

## Which dimension(s) this platform is solid in
enum PlatformDimension {
	EDGE_VIEW_ONLY,  ## Only solid in edge view (blue)
	TOP_VIEW_ONLY,   ## Only solid in top view (purple)
	BOTH_DIMENSIONS  ## Always solid (grey)
}

## The dimension behavior of this platform
@export var platform_dimension: PlatformDimension = PlatformDimension.BOTH_DIMENSIONS

## Duration of fade transition
@export var fade_duration: float = 0.2

## Whether to show a ghost outline when not solid
@export var show_ghost_when_inactive: bool = true

## Ghost opacity when platform is not active
@export var ghost_opacity: float = 0.15

## Reference to the visual sprite (auto-detected)
var _sprite: CanvasItem  # Could be ColorRect or Sprite2D
var _active_tween: Tween
var _is_active: bool = true


func _ready() -> void:
	# Find the sprite child
	_find_sprite()

	# Connect to dimension changes
	DimensionManager.dimension_changed.connect(_on_dimension_changed)

	# Set initial state without animation
	_apply_dimension_state(DimensionManager.current_dimension, true)


func _exit_tree() -> void:
	if DimensionManager.dimension_changed.is_connected(_on_dimension_changed):
		DimensionManager.dimension_changed.disconnect(_on_dimension_changed)


func _find_sprite() -> void:
	## Find the visual representation of this platform
	for child in get_children():
		if child is ColorRect or child is Sprite2D:
			_sprite = child as CanvasItem
			return
		# Also search one level deeper (e.g., PlatformSprite inside the StaticBody2D)
		for subchild in child.get_children():
			if subchild is ColorRect or subchild is Sprite2D:
				_sprite = subchild as CanvasItem
				return


func _on_dimension_changed(new_dimension: DimensionManager.Dimension) -> void:
	_apply_dimension_state(new_dimension, false)


func _apply_dimension_state(dimension: DimensionManager.Dimension, instant: bool) -> void:
	## Update platform state based on the current dimension
	var should_be_active: bool

	match platform_dimension:
		PlatformDimension.EDGE_VIEW_ONLY:
			should_be_active = (dimension == DimensionManager.Dimension.EDGE_VIEW)
		PlatformDimension.TOP_VIEW_ONLY:
			should_be_active = (dimension == DimensionManager.Dimension.TOP_VIEW)
		PlatformDimension.BOTH_DIMENSIONS:
			should_be_active = true

	if should_be_active == _is_active and not instant:
		return

	_is_active = should_be_active

	# Update collision
	_update_collision(should_be_active)

	# Update visuals
	_update_visuals(should_be_active, instant)


func _update_collision(is_active: bool) -> void:
	## Enable or disable collision based on active state
	if is_active:
		# Restore collision layer based on platform type
		match platform_dimension:
			PlatformDimension.EDGE_VIEW_ONLY:
				collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_EDGE_VIEW_SOLID)
			PlatformDimension.TOP_VIEW_ONLY:
				collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_TOP_VIEW_SOLID)
			PlatformDimension.BOTH_DIMENSIONS:
				collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_ALWAYS_SOLID)
	else:
		# Remove all collision
		collision_layer = 0


func _update_visuals(is_active: bool, instant: bool) -> void:
	## Update the visual appearance of the platform
	if not _sprite:
		return

	var target_opacity: float
	if is_active:
		target_opacity = 1.0
	elif show_ghost_when_inactive:
		target_opacity = ghost_opacity
	else:
		target_opacity = 0.0

	# Cancel existing tween
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	if instant:
		_sprite.modulate.a = target_opacity
	else:
		_active_tween = create_tween()
		_active_tween.set_ease(Tween.EASE_OUT)
		_active_tween.set_trans(Tween.TRANS_SINE)
		_active_tween.tween_property(_sprite, "modulate:a", target_opacity, fade_duration)


## Check if the platform is currently solid
func is_solid() -> bool:
	return _is_active


## Get the color associated with this platform's dimension
func get_dimension_color() -> Color:
	match platform_dimension:
		PlatformDimension.EDGE_VIEW_ONLY:
			return Color(0.227, 0.525, 1.0)  # Blue
		PlatformDimension.TOP_VIEW_ONLY:
			return Color(0.514, 0.224, 0.925)  # Purple
		_:
			return Color(0.122, 0.161, 0.216)  # Grey
