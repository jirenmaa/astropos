extends Node2D

var roots: String = "res://saved_world"


func _ready():
	var dir = Directory.new()

	if not Global.DEVELOPMENT:
		roots = Global.PRODUCTION_SAVED

	if not dir.dir_exists(roots):
		dir.make_dir(roots)
