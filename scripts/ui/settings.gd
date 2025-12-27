extends Control
## Settings - Game settings screen
##
## Allows players to adjust audio, display, and control options.

@onready var back_button: Button = $BackButton
@onready var music_slider: HSlider = $SettingsContainer/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $SettingsContainer/SFXContainer/SFXSlider
@onready var fullscreen_check: CheckBox = $SettingsContainer/FullscreenCheck
@onready var touch_controls_check: CheckBox = $SettingsContainer/TouchControlsCheck


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	# Load current settings
	music_slider.value = GameManager.get_setting("music_volume", 1.0)
	sfx_slider.value = GameManager.get_setting("sfx_volume", 1.0)
	fullscreen_check.button_pressed = GameManager.get_setting("fullscreen", false)
	touch_controls_check.button_pressed = GameManager.get_setting("touch_controls", false)

	# Connect signals
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	touch_controls_check.toggled.connect(_on_touch_controls_toggled)

	# Hide touch controls option on mobile (always enabled there)
	if GameManager.is_mobile():
		touch_controls_check.visible = false

	back_button.grab_focus()


func _on_music_changed(value: float) -> void:
	GameManager.set_setting("music_volume", value)
	# TODO: Apply to audio bus


func _on_sfx_changed(value: float) -> void:
	GameManager.set_setting("sfx_volume", value)
	# TODO: Apply to audio bus


func _on_fullscreen_toggled(pressed: bool) -> void:
	GameManager.set_setting("fullscreen", pressed)
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_touch_controls_toggled(pressed: bool) -> void:
	GameManager.set_setting("touch_controls", pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
