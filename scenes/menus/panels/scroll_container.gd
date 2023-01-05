extends ScrollContainer


func _ready():
	disable_scrollbars()


func disable_scrollbars() -> void:
	var invisible_scrollbar_theme = Theme.new()
	var empty_stylebox = StyleBoxEmpty.new()
	invisible_scrollbar_theme.set_stylebox("scroll", "VScrollBar", empty_stylebox)
	invisible_scrollbar_theme.set_stylebox("scroll", "HScrollBar", empty_stylebox)

	# change default theme of the TextEdit
	theme = invisible_scrollbar_theme
