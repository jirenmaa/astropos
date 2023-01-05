extends TextEdit

var commands = [
	{"keyword": ["plant", "planting", "planted"], "rgb": [232, 96, 70]},
	{"keyword": ["water", "watering", "watered"], "rgb": [94, 94, 170]},
	{"keyword": ["feed", "feeding", "feeded"], "rgb": [167, 107, 167]},
	{"keyword": ["harvest", "harvesting", "harvested"], "rgb": [96, 172, 114]},
	{"keyword": ["save", "(saving your game data)", "saved"], "rgb": [255, 246, 137]},
	{"keyword": ["error", "(error when attempting to save game data)"], "rgb": [214, 36, 57]},
]


func _ready() -> void:
	disable_scrollbars()
	apply_custom_color()


func disable_scrollbars() -> void:
	var invisible_scrollbar_theme = Theme.new()
	var empty_stylebox = StyleBoxEmpty.new()
	invisible_scrollbar_theme.set_stylebox("scroll", "VScrollBar", empty_stylebox)
	invisible_scrollbar_theme.set_stylebox("scroll", "HScrollBar", empty_stylebox)

	# change default theme of the TextEdit
	theme = invisible_scrollbar_theme


func apply_custom_color():
	"""Highlighting some specific text for terminal commands"""

	# coloring the text starting with '(' and endswith ' data)'
	add_color_region("(", " data)", Color(1.0, 0.964705, 0.537254))

	for command in commands:
		var f_rgba = callv("rgb_to_float_rgb", command.rgb)
		var colors = Color(f_rgba[0], f_rgba[1], f_rgba[2])

		for keyword in command.keyword:
			if "(" in keyword or ")" in keyword:
				continue

			add_keyword_color(keyword, colors)

	text = "astropos $ type 'help' to help you\n"


func rgb_to_float_rgb(r: int, g: int, b: int) -> Array:
	# convert rgb to float rgb, because godot is using float rgb for the Color
	# https://www.reddit.com/r/godot/comments/dxgbn9/how_do_i_use_0255_instead_of_01_rgb_when_using/
	return [r / 255.0, g / 255.0, b / 255.0]
