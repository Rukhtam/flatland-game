extends CanvasLayer
## TouchControls - On-screen touch controls for mobile devices
##
## Provides large, accessible touch buttons for movement, jump, and dimension shift.
## Automatically shows/hides based on platform and settings.

## Size of touch buttons
@export var button_size: float = 80.0

## Margin from screen edges
@export var margin: float = 20.0

## Button opacity
@export var button_opacity: float = 0.5

## Emitted when a touch action changes state
signal touch_action_changed(action: String, pressed: bool)

var _left_pressed: bool = false
var _right_pressed: bool = false
var _jump_pressed: bool = false
var _shift_pressed: bool = false

@onready var left_button: TouchScreenButton = $LeftButton
@onready var right_button: TouchScreenButton = $RightButton
@onready var jump_button: TouchScreenButton = $JumpButton
@onready var shift_button: TouchScreenButton = $ShiftButton


func _ready() -> void:
	# Check if we should show touch controls
	if not GameManager.should_show_touch_controls():
		visible = false
		return

	visible = true
	_setup_buttons()


func _setup_buttons() -> void:
	# Position buttons relative to screen corners
	# Left/Right on bottom-left, Jump/Shift on bottom-right
	var screen_size = get_viewport().get_visible_rect().size

	if left_button:
		left_button.position = Vector2(margin, screen_size.y - margin - button_size)

	if right_button:
		right_button.position = Vector2(margin + button_size + 10, screen_size.y - margin - button_size)

	if jump_button:
		jump_button.position = Vector2(screen_size.x - margin - button_size, screen_size.y - margin - button_size)

	if shift_button:
		shift_button.position = Vector2(screen_size.x - margin - button_size * 2 - 10, screen_size.y - margin - button_size)


func _process(_delta: float) -> void:
	if not visible:
		return

	# Simulate input actions based on touch button states
	_update_input_action("move_left", _left_pressed)
	_update_input_action("move_right", _right_pressed)
	_update_input_action("jump", _jump_pressed)
	_update_input_action("shift_dimension", _shift_pressed)


func _update_input_action(action: String, pressed: bool) -> void:
	# This approach directly manipulates the Input singleton
	# to make touch buttons work like regular input
	if pressed:
		if not Input.is_action_pressed(action):
			Input.action_press(action)
	else:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _on_left_pressed() -> void:
	_left_pressed = true


func _on_left_released() -> void:
	_left_pressed = false


func _on_right_pressed() -> void:
	_right_pressed = true


func _on_right_released() -> void:
	_right_pressed = false


func _on_jump_pressed() -> void:
	_jump_pressed = true


func _on_jump_released() -> void:
	_jump_pressed = false


func _on_shift_pressed() -> void:
	_shift_pressed = true


func _on_shift_released() -> void:
	_shift_pressed = false
