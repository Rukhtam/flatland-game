extends Node
## GameManager - Global singleton for game state and progression
##
## Manages overall game state including level progression, save/load,
## pause functionality, and game-wide settings.

## Game states
enum GameState {
	MENU,       ## In main menu or sub-menus
	PLAYING,    ## Active gameplay
	PAUSED,     ## Game paused
	CUTSCENE,   ## Watching a cutscene (input limited)
	LOADING     ## Loading a level
}

## Emitted when game state changes
signal game_state_changed(new_state: GameState)

## Emitted when a level is completed
signal level_completed(world: int, level: int)

## Emitted when player dies/restarts
signal player_died()

## Current game state
var current_state: GameState = GameState.MENU:
	set(value):
		if current_state != value:
			current_state = value
			game_state_changed.emit(current_state)
			_handle_state_change(value)

## Current world (1-3)
var current_world: int = 1

## Current level within the world
var current_level: int = 1

## Player save data
var save_data: Dictionary = {
	"unlocked_worlds": [1],
	"unlocked_levels": {1: [1], 2: [], 3: []},
	"completed_levels": {1: [], 2: [], 3: []},
	"settings": {
		"music_volume": 1.0,
		"sfx_volume": 1.0,
		"fullscreen": false,
		"touch_controls": false
	}
}

## Path to save file
const SAVE_PATH: String = "user://flatland_save.dat"

## Level counts per world
const LEVELS_PER_WORLD: Dictionary = {
	1: 3,  # World 1: Lineland - 3 levels
	2: 4,  # World 2: Flatland Society - 4 levels
	3: 3   # World 3: Sphere's Visit - 3 levels
}

## World names for UI
const WORLD_NAMES: Dictionary = {
	1: "Lineland",
	2: "Flatland Society",
	3: "Sphere's Visit"
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()
	print("[GameManager] Initialized")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_state == GameState.PLAYING:
			pause_game()
		elif current_state == GameState.PAUSED:
			resume_game()


## Handle state change side effects
func _handle_state_change(new_state: GameState) -> void:
	match new_state:
		GameState.PLAYING:
			get_tree().paused = false
			DimensionManager.set_shift_enabled(true)
		GameState.PAUSED:
			get_tree().paused = true
			DimensionManager.set_shift_enabled(false)
		GameState.CUTSCENE:
			DimensionManager.set_shift_enabled(false)
		GameState.MENU:
			get_tree().paused = false
		GameState.LOADING:
			get_tree().paused = false


## Pause the game
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		print("[GameManager] Game paused")


## Resume the game
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		print("[GameManager] Game resumed")


## Start playing from a specific level
func start_level(world: int, level: int) -> void:
	current_world = world
	current_level = level
	current_state = GameState.LOADING

	var level_path = "res://scenes/levels/world_%d/level_%d_%d.tscn" % [world, world, level]
	print("[GameManager] Loading level: ", level_path)

	# Reset dimension to edge view for level start
	DimensionManager.set_dimension_immediate(DimensionManager.Dimension.EDGE_VIEW)

	var error = get_tree().change_scene_to_file(level_path)
	if error != OK:
		push_error("[GameManager] Failed to load level: " + level_path)
		return

	# Wait a frame then set to playing
	await get_tree().process_frame
	current_state = GameState.PLAYING


## Complete current level and unlock next
func complete_current_level() -> void:
	# Mark level as completed
	if current_level not in save_data["completed_levels"][current_world]:
		save_data["completed_levels"][current_world].append(current_level)

	# Unlock next level
	var next_level = current_level + 1
	if next_level <= LEVELS_PER_WORLD[current_world]:
		# Unlock next level in same world
		if next_level not in save_data["unlocked_levels"][current_world]:
			save_data["unlocked_levels"][current_world].append(next_level)
	else:
		# Unlock next world if exists
		var next_world = current_world + 1
		if next_world <= 3 and next_world not in save_data["unlocked_worlds"]:
			save_data["unlocked_worlds"].append(next_world)
			save_data["unlocked_levels"][next_world].append(1)

	level_completed.emit(current_world, current_level)
	save_game()
	print("[GameManager] Level %d-%d completed" % [current_world, current_level])


## Restart current level
func restart_level() -> void:
	player_died.emit()
	start_level(current_world, current_level)


## Go to main menu
func go_to_main_menu() -> void:
	current_state = GameState.MENU
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


## Check if a level is unlocked
func is_level_unlocked(world: int, level: int) -> bool:
	if world not in save_data["unlocked_worlds"]:
		return false
	return level in save_data["unlocked_levels"][world]


## Check if a level is completed
func is_level_completed(world: int, level: int) -> bool:
	return level in save_data["completed_levels"][world]


## Get completion percentage for a world
func get_world_completion(world: int) -> float:
	var completed = save_data["completed_levels"][world].size()
	var total = LEVELS_PER_WORLD[world]
	return float(completed) / float(total)


## Save game to file
func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("[GameManager] Game saved")
	else:
		push_error("[GameManager] Failed to save game")


## Load game from file
func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var loaded_data = file.get_var()
			if loaded_data is Dictionary:
				# Merge loaded data with defaults (in case of version updates)
				_merge_save_data(loaded_data)
			file.close()
			print("[GameManager] Game loaded")
	else:
		print("[GameManager] No save file found, using defaults")


## Merge loaded save data with defaults
func _merge_save_data(loaded: Dictionary) -> void:
	for key in loaded:
		if key in save_data:
			if loaded[key] is Dictionary and save_data[key] is Dictionary:
				for subkey in loaded[key]:
					save_data[key][subkey] = loaded[key][subkey]
			else:
				save_data[key] = loaded[key]


## Reset all progress
func reset_progress() -> void:
	save_data = {
		"unlocked_worlds": [1],
		"unlocked_levels": {1: [1], 2: [], 3: []},
		"completed_levels": {1: [], 2: [], 3: []},
		"settings": save_data["settings"]  # Keep settings
	}
	save_game()
	print("[GameManager] Progress reset")


## Update a setting
func set_setting(key: String, value: Variant) -> void:
	save_data["settings"][key] = value
	save_game()


## Get a setting
func get_setting(key: String, default: Variant = null) -> Variant:
	return save_data["settings"].get(key, default)


## Check if running on mobile
func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


## Check if touch controls should be shown
func should_show_touch_controls() -> bool:
	return is_mobile() or get_setting("touch_controls", false)
