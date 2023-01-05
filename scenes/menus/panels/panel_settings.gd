extends Control


func _input(ev: InputEvent) -> void:
	"""Close panel settings when user press 'esc' button"""

	if ev is InputEventKey and ev.scancode == KEY_ESCAPE and not ev.echo:
		visible = false
