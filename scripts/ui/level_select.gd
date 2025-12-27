extends Control
## LevelSelect - Level selection screen
##
## Displays available worlds and levels with their unlock/completion status.

@onready var back_button: Button = $BackButton
@onready var world_container: VBoxContainer = $WorldContainer


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_levels()
	back_button.grab_focus()


func _populate_levels() -> void:
	# Clear existing children (except template)
	for child in world_container.get_children():
		child.queue_free()

	# Create world sections
	for world in range(1, 4):
		var world_section = _create_world_section(world)
		world_container.add_child(world_section)


func _create_world_section(world: int) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.name = "World%d" % world

	# World title
	var title = Label.new()
	title.text = "World %d: %s" % [world, GameManager.WORLD_NAMES[world]]
	title.add_theme_font_size_override("font_size", 24)

	var is_unlocked = world in GameManager.save_data["unlocked_worlds"]
	title.add_theme_color_override("font_color",
		Color(0.227, 0.525, 1.0) if is_unlocked else Color(0.3, 0.3, 0.3))

	section.add_child(title)

	# Level buttons container
	var level_container = HBoxContainer.new()
	level_container.add_theme_constant_override("separation", 10)

	for level in range(1, GameManager.LEVELS_PER_WORLD[world] + 1):
		var button = _create_level_button(world, level)
		level_container.add_child(button)

	section.add_child(level_container)
	section.add_theme_constant_override("separation", 10)

	return section


func _create_level_button(world: int, level: int) -> Button:
	var button = Button.new()
	button.text = "%d-%d" % [world, level]
	button.custom_minimum_size = Vector2(60, 60)
	button.add_theme_font_size_override("font_size", 18)

	var is_unlocked = GameManager.is_level_unlocked(world, level)
	var is_completed = GameManager.is_level_completed(world, level)

	button.disabled = not is_unlocked

	if is_completed:
		button.add_theme_color_override("font_color", Color(0.996, 0.718, 0.012))  # Gold
	elif is_unlocked:
		button.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		button.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

	button.pressed.connect(_on_level_pressed.bind(world, level))
	return button


func _on_level_pressed(world: int, level: int) -> void:
	GameManager.start_level(world, level)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
