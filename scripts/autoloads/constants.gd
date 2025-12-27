extends Node
## Constants - Global constants for Flatland
##
## Contains color definitions, physics values, and other shared constants.
## This is an autoload but could also be used as a static class.

## --- COLORS ---
## Background color - dark theme base
const COLOR_BACKGROUND := Color("#0D1117")

## Grid line color for background
const COLOR_GRID := Color("#1F2937")

## Shape hierarchy colors (from lowest to highest status)
const COLOR_LINES := Color("#FF006E")       # Pink - lowest class
const COLOR_TRIANGLES := Color("#FB5607")   # Orange - soldiers/workers
const COLOR_SQUARES := Color("#3A86FF")     # Blue - professional class (player)
const COLOR_PENTAGONS := Color("#8338EC")   # Purple - nobility
const COLOR_CIRCLES := Color("#FFB703")     # Gold - priests (highest class)

## UI accent color
const COLOR_UI_ACCENT := Color("#3A86FF")

## Dimension indicator colors
const COLOR_EDGE_VIEW := Color("#8338EC")
const COLOR_TOP_VIEW := Color("#FFB703")

## --- PHYSICS ---
## Default player physics values (can be overridden via exports)
const PLAYER_SPEED := 200.0
const PLAYER_JUMP_VELOCITY := -350.0
const PLAYER_GRAVITY := 980.0

## --- GRID ---
## Background grid spacing
const GRID_SIZE := 50

## --- LAYER BITS ---
## Pre-calculated layer bit values for convenience
const LAYER_BIT_EDGE := 1       # Layer 1
const LAYER_BIT_TOP := 2        # Layer 2
const LAYER_BIT_ALWAYS := 4     # Layer 3
const LAYER_BIT_PLAYER := 8     # Layer 4
const LAYER_BIT_INTERACT := 16  # Layer 5
const LAYER_BIT_TRIGGER := 32   # Layer 6


## Get color for a specific shape type
static func get_shape_color(shape_type: String) -> Color:
	match shape_type.to_lower():
		"line":
			return COLOR_LINES
		"triangle":
			return COLOR_TRIANGLES
		"square":
			return COLOR_SQUARES
		"pentagon":
			return COLOR_PENTAGONS
		"hexagon", "circle":
			return COLOR_CIRCLES
		_:
			return Color.WHITE
