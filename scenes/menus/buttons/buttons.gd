extends Button

onready var PanelSettings = get_parent().get_parent().get_node("PanelSettings")
onready var PanelLoadSave = get_parent().get_parent().get_node("PanelLoadGame")


func _on_NewGame_pressed():
	Global.NEWGAME = true
	get_tree().change_scene("res://scenes/main.tscn")


func _on_LoadGame_pressed():
	PanelLoadSave.visible = true


func _on_Settings_pressed():
	PanelSettings.visible = true


func _on_ExitGame_pressed():
	get_tree().quit()
