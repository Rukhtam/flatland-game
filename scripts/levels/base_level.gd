class_name BaseLevel
extends Node2D
## BaseLevel - Base class for all game levels
##
## Provides common functionality for all levels including player spawning,
## camera setup, dimension indicator UI, and level completion triggers.

## The starting dimension for this level
@export var starting_dimension: DimensionManager.Dimension = DimensionManager.Dimension.EDGE_VIEW

## Whether dimension shifting is allowed in this level (can be disabled for tutorials)
@export var dimension_shifting_enabled: bool = true

## Level completion signal
signal level_completed()

## Reference to player instance
var player: Player

## Reference to spawn point
@onready var spawn_point: Marker2D = $SpawnPoint if has_node("SpawnPoint") else null
@onready var camera: Camera2D = $Camera2D if has_node("Camera2D") else null
@onready var dimension_indicator: Label = $UI/DimensionIndicator if has_node("UI/DimensionIndicator") else null


func _ready() -> void:
	# Set up initial dimension state
	DimensionManager.set_dimension_immediate(starting_dimension)
	DimensionManager.set_shift_enabled(dimension_shifting_enabled)

	# Connect to dimension changes for UI updates
	DimensionManager.dimension_changed.connect(_on_dimension_changed)

	# Find or spawn player
	_setup_player()

	# Update UI
	_update_dimension_indicator()

	# Set game state
	GameManager.current_state = GameManager.GameState.PLAYING


func _exit_tree() -> void:
	if DimensionManager.dimension_changed.is_connected(_on_dimension_changed):
		DimensionManager.dimension_changed.disconnect(_on_dimension_changed)


func _setup_player() -> void:
	## Find existing player or instantiate from scene
	player = get_node_or_null("Player") as Player

	if not player:
		# Load and instantiate player scene
		var player_scene = load("res://scenes/player/player.tscn")
		player = player_scene.instantiate() as Player
		add_child(player)

	# Position at spawn point
	if spawn_point:
		player.global_position = spawn_point.global_position

	# Set up camera to follow player
	if camera:
		camera.reparent(player)
		camera.position = Vector2.ZERO


func _on_dimension_changed(new_dimension: DimensionManager.Dimension) -> void:
	_update_dimension_indicator(new_dimension)


func _update_dimension_indicator(dimension: DimensionManager.Dimension = DimensionManager.current_dimension) -> void:
	if not dimension_indicator:
		return

	dimension_indicator.text = DimensionManager.get_dimension_name(dimension)

	# Update indicator color based on dimension
	var target_color: Color
	if dimension == DimensionManager.Dimension.EDGE_VIEW:
		target_color = Color(0.227, 0.525, 1.0)  # Blue for Edge View (#3A86FF)
	else:
		target_color = Color(0.514, 0.224, 0.925)  # Purple for Top View (#8338EC)

	# Animate the color change
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(dimension_indicator, "theme_override_colors/font_color", target_color, 0.2)

	# Add a subtle scale pulse effect
	tween.parallel().tween_property(dimension_indicator, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(dimension_indicator, "scale", Vector2(1.0, 1.0), 0.15)


## Called when player reaches the level exit
func complete_level() -> void:
	level_completed.emit()
	GameManager.complete_current_level()

	# Show completion UI or transition
	# For now, just go to level select
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")


## Restart the current level
func restart_level() -> void:
	GameManager.restart_level()


## Return player to spawn point without full restart
func respawn_player() -> void:
	if player and spawn_point:
		player.teleport_to(spawn_point.global_position)
		DimensionManager.set_dimension_immediate(starting_dimension)
