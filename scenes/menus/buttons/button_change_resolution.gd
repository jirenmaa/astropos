extends Button

onready var MainMenuScene = get_parent().get_parent().get_parent()


func _on_DefaultResButton_pressed():
	# change the viewport display window
	OS.window_size = Vector2(1366, 768)


func _on_SmallResButton_pressed():
	# change the viewport display window
	OS.window_size = Vector2(1024, 576)
