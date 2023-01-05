extends Control

onready var PanelSavesButton = get_node("Panel").get_node("Container").get_node("VBox")
onready var DefaultSaveButton = PanelSavesButton.get_node("DefaultLoad")

var conf: String = "res://config.cfg"
var roots: String = "res://saved_world"
var save_datas = []


func _ready():
	if not Global.DEVELOPMENT:
		roots = Global.PRODUCTION_SAVED

	load_saved_game_panel()


func _input(ev):
	# close panel when user press 'esc' button
	if ev is InputEventKey and ev.scancode == KEY_ESCAPE and not ev.echo:
		visible = false


func _on_ButtonLoad_pressed(file: String) -> void:
	Global.LOADFILE = file
	Global.NEWGAME = false

	Global.SAVE_ON_NEWGAME = false
	Global.SAVE_ON_NEWGAME_FILENAME = ""

	var _v = get_tree().change_scene("res://scenes/main.tscn")


func _on_ButtonDelete_pressed(file: String):
	var configFile = ConfigFile.new()
	configFile.load(conf)

	var saved_count = configFile.get_value("Config", "saved_count")

	# delete the save data inside directory
	var dir = Directory.new()
	dir.remove("%s/%s" % [roots, file])

	for child in PanelSavesButton.get_children():
		# delete child other thah the 'DefaultLoad'
		if child.name == "DefaultLoad":
			continue

		PanelSavesButton.remove_child(child)

	configFile.set_value("Config", "saved_count", int(saved_count) - 1)
	configFile.save(conf)

	# generate new nodes after deleting the old nodes,
	# so it looked like the UI is updating
	load_saved_game_panel()


func load_saved_game_panel() -> void:
	var directory: Directory = Directory.new()
	var file: File = File.new()

	if not directory.dir_exists(roots):
		directory.make_dir(roots)

	directory.open(roots)
	directory.list_dir_begin(true, true)

	var files = get_files_order_by_modified_time(file, directory)
	var space = 0
	var file_size = files.size()

	if file_size < 1:
		return

	for save_file in files:
		# create a duplicate of the original button
		var dupe_btn: Button = DefaultSaveButton.duplicate()
		# add to the node tree
		PanelSavesButton.add_child(dupe_btn)

		# get the child node (delete button) from the duplicated node,
		# it will be used to create signal to each of the button
		var dupe_del: Button = dupe_btn.get_node("Delete")

		# change their visibility to true, because the visibility
		# of the original buttons is false
		dupe_btn.visible = true
		dupe_del.visible = true

		# create a label text for the load button e.g 'Farm 1', 'Farm n'
		dupe_btn.text = "Farm %s" % [str(file_size)]

		# change the position each of the duplicate children
		# so it will not be in the same place as the original

		# since the button got duplicated, the position also be same each of the button,
		# to fix that, the position itself need to be change, so it won't get stacked
		# if not file_size == 0:
		# 	dupe_btn.rect_position = Vector2(0, 80 * space)

		# create the signals for each of the button
		dupe_btn.connect("pressed", self, "_on_ButtonLoad_pressed", [save_file])
		dupe_del.connect("pressed", self, "_on_ButtonDelete_pressed", [save_file])

		space += 1
		file_size -= 1


func lambda(current: Dictionary, comparison: Dictionary) -> bool:
	return current.time > comparison.time


func get_files_order_by_modified_time(instance, iterator) -> Array:
	var files: Array = []
	var obj = ""
	var filenames = []

	# iterate over the files in the directory
	while true:
		# Get the next file in the directory
		obj = iterator.get_next()
		var file = obj.get_file()

		if file.get_basename() == "":
			break

		# get the modification time of the current file
		var time = instance.get_modified_time("{root}/{file}".format({"root": roots, "file": file}))

		files.append({"name": file, "time": time})

	# sort by the latest modified time
	files.sort_custom(self, "lambda")

	# get filename only and store it to filenames
	for file in files:
		filenames.append(file.name)

	return filenames
