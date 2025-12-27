class_name LevelExit
extends Area2D
## LevelExit - Trigger zone that completes the level when player enters
##
## Place this at the end of each level. When the player enters the zone,
## the level is marked as complete and the next level unlocks.

## Whether this exit is currently active
@export var is_active: bool = true

## Whether exit only works in a specific dimension
@export var dimension_locked: bool = false
@export var required_dimension: DimensionManager.Dimension = DimensionManager.Dimension.EDGE_VIEW

## Visual feedback node (optional)
@export var exit_sprite: Sprite2D

## Emitted when player triggers the exit
signal exit_triggered()


func _ready() -> void:
	# Connect body entered signal
	body_entered.connect(_on_body_entered)

	# Set collision layer to triggers
	collision_layer = DimensionManager.get_layer_bit(DimensionManager.LAYER_TRIGGERS)
	collision_mask = DimensionManager.get_layer_bit(DimensionManager.LAYER_PLAYER)

	# Optional: pulse animation for visual feedback
	if exit_sprite:
		_start_pulse_animation()


func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return

	if not body is Player:
		return

	# Check dimension requirement if locked
	if dimension_locked:
		if DimensionManager.current_dimension != required_dimension:
			_show_wrong_dimension_feedback()
			return

	# Trigger exit
	_complete_exit()


func _complete_exit() -> void:
	is_active = false
	exit_triggered.emit()

	# Notify the level (if using base_level)
	var level = get_tree().current_scene
	if level.has_method("complete_level"):
		level.complete_level()
	else:
		# Fallback to GameManager
		GameManager.complete_current_level()


func _show_wrong_dimension_feedback() -> void:
	# Visual feedback that player needs to shift dimension
	if exit_sprite:
		var tween = create_tween()
		tween.tween_property(exit_sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(exit_sprite, "modulate", Color.WHITE, 0.1)


func _start_pulse_animation() -> void:
	if not exit_sprite:
		return

	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(exit_sprite, "modulate:a", 0.5, 0.8)
	tween.tween_property(exit_sprite, "modulate:a", 1.0, 0.8)
