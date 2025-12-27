extends Control
## MainMenu - The game's main menu screen
##
## Provides navigation to start game, level select, settings, and credits.
## Designed to work with both mouse/keyboard and touch input.

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var level_select_button: Button = $VBoxContainer/LevelSelectButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Set version text
	if version_label:
		version_label.text = "v0.1.0 - Day 1 Build"

	# Hide quit button on web (can't quit web games)
	if OS.has_feature("web"):
		quit_button.visible = false

	# Ensure game state is correct
	GameManager.current_state = GameManager.GameState.MENU

	# Focus first button for keyboard/gamepad navigation
	start_button.grab_focus()


func _on_start_pressed() -> void:
	# Start from the first unlocked level
	GameManager.start_level(1, 1)


func _on_level_select_pressed() -> void:
	# TODO: Navigate to level select screen
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")


func _on_settings_pressed() -> void:
	# TODO: Navigate to settings screen
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
