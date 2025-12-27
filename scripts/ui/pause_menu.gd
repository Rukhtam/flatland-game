extends CanvasLayer
## PauseMenu - In-game pause overlay
##
## Displayed when game is paused. Provides options to resume, restart, or quit.

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton


func _ready() -> void:
	# Start hidden
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect signals
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# Connect to game state changes
	GameManager.game_state_changed.connect(_on_game_state_changed)


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.PAUSED:
		_show_pause_menu()
	else:
		_hide_pause_menu()


func _show_pause_menu() -> void:
	visible = true
	resume_button.grab_focus()


func _hide_pause_menu() -> void:
	visible = false


func _on_resume_pressed() -> void:
	GameManager.resume_game()


func _on_restart_pressed() -> void:
	GameManager.resume_game()  # Unpause first
	GameManager.restart_level()


func _on_settings_pressed() -> void:
	# TODO: Show settings overlay instead of navigating away
	pass


func _on_main_menu_pressed() -> void:
	GameManager.resume_game()  # Unpause first
	GameManager.go_to_main_menu()
