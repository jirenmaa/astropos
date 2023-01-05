extends Node2D

var config: String = "res://config.cfg"
var roots: String = "res://saved_world"
var key_size: int = 32  # filename size


func _ready():
	if not Global.DEVELOPMENT:
		roots = Global.PRODUCTION_SAVED


func save(total_harvest: int) -> String:
	var _z
	var config_file: ConfigFile = ConfigFile.new()
	_z = config_file.load(config)

	var generator: RandomNumberGenerator = RandomNumberGenerator.new()
	generator.randomize()

	var file: File = File.new()
	var filename: String = generate_random_key(false, key_size, generator)
	var password: String = generate_random_key(false, key_size, generator)

	# bucket for storing the sliced password and filename,
	# because the filename may be change if the Global.NEWGAME is true
	var response: Dictionary
	var saved_count: int = config_file.get_value("Config", "saved_count")

	if Global.NEWGAME and not Global.SAVE_ON_NEWGAME:
		response = save_from_new_world(
			filename, password, {"config_file": config_file, "saved_count": saved_count}
		)

	if not Global.NEWGAME or Global.SAVE_ON_NEWGAME:
		response = save_from_existed_world()

	# target directory for the file to be saved
	var target: String = "{root}/{name}.dat".format({"root": roots, "name": response.filename})
	var temp_tiles: Dictionary = generate_save_tiles()

	var datas = {
		"total_harvest": int(total_harvest),
		"tiles": temp_tiles,
	}

	if int(saved_count) < 10:
		# create a new saved with with password
		_z = file.open_encrypted_with_pass(target, File.WRITE, response.password)

		# write the datas to the file
		file.store_var(datas)
		file.close()

		# update config file
		_z = config_file.save(config)

		return "Your game data have been saved."
	return "Maximum saved file have been reached 'max 10'"


func load_saved_world(instance: Node) -> bool:
	var _z
	var latest: String = Global.LOADFILE
	var target: String = "%s/%s" % [roots, latest]

	# if the statement is true, then the player are not
	# load a saved game data (new game)
	if typeof(latest) == TYPE_STRING and latest == "":
		return false

	var file: File = File.new()

	# bucket for storing the sliced password from filenames
	var sliced_pass: String = ""
	# loop through the filename, and retrive the password
	for index in range(key_size):
		if not index & 1 == 0:
			continue

		# add the character for password if the index is odd
		sliced_pass += latest[index]

	_z = file.open_encrypted_with_pass(target, File.READ, sliced_pass)

	# retrive the datas from files
	var data = file.get_var()

	Plant.tiles = data.tiles

	generate_load_tiles()
	# update total harvest counter
	instance.text = str(data.total_harvest)

	return true


func generate_load_tiles():
	"""Update the default tiles with the loaded saved game"""
	var tiles = Plant.tiles

	for coord in tiles:
		# check if the plant has been 'watered' or 'fed'
		if tiles[coord].timer == 0:
			continue

		tiles[coord].timer = OS.get_unix_time() + tiles[coord].timer


func generate_save_tiles():
	"""
	Generate a custom tiles to be saved in file, the saved tiles will be have a fixed timer, if
	the current tile (plant) status are being 'watered' or 'feeded'
	"""

	# make sure the temporary tiles are not a shallow
	# so it will not affect the original
	var temp: Dictionary = Plant.tiles.duplicate(true)  # deepcopy: true

	for coord in temp:
		# check if the plant is being 'watered' or 'fed'
		if temp[coord].timer == 0:
			continue

		temp[coord].timer = temp[coord].timer - OS.get_unix_time()

	return temp


func save_from_new_world(filename: String, password: String, params: Dictionary) -> Dictionary:
	var sliced_pass: String = ""

	# iterate through the filename, and insert
	# the password between the character with given index
	for index in range(len(filename)):
		if not index & 1 == 0:
			continue

		# insert character if the index is odd
		sliced_pass += password[index]
		filename = filename.insert(index, password[index])

		params.config_file.set_value("Config", "saved_count", params.saved_count + 1)

	# this varaible will used to check if the user is playing a new game,
	# and using a command 'save' then when the user is exit, the autosave
	# will use this varaible to save the latest data instead of creating
	# a new saves
	Global.SAVE_ON_NEWGAME = true
	Global.SAVE_ON_NEWGAME_FILENAME = filename

	return {"filename": filename, "password": sliced_pass}


func save_from_existed_world() -> Dictionary:
	var filename: String = Global.SAVE_ON_NEWGAME_FILENAME

	if filename.empty():
		# make sure to get the basename only and not the extension
		filename = Global.LOADFILE.split(".")[0]

	var sliced_pass: String = ""

	# loop through the filename, and retrive the
	# password
	for index in range(key_size):
		if not index & 1 == 0:
			continue

		# add the character for password if the index is odd
		sliced_pass += filename[index]

	return {"filename": filename, "password": sliced_pass}


# utilities
func generate_random_key(
	use_special_char: bool, length: int, generator: RandomNumberGenerator
) -> String:
	"Generate a random string with given length"

	# create a string containing all the characters to use in the key
	var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

	if use_special_char:
		characters += "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"

	# initialize an empty key string
	var key = ""

	# generate a random key by choosing 'n' random characters from the character string
	for _i in range(length):
		key += characters[generator.randi_range(0, len(characters) - 1)]

	return key


func get_latest_file(instance, iterator):
	"Get the latest file order by modifed time from directory list"

	# initialize variables to store the latest file and its modification time
	var latest_file = ""
	var latest_time = 0
	var _iterate = ""

	# iterate over the files in the directory
	while true:
		# get the next file in the directory
		_iterate = iterator.get_next()
		var file = _iterate.get_file()

		if file.get_basename() == "":
			break

		# get the modification time of the current file
		var time = instance.get_modified_time("{root}/{file}".format({"root": roots, "file": file}))

		# check if the modification time is greater than the current latest time
		if time > latest_time:
			# update the latest file and time
			latest_file = file
			latest_time = time

	return latest_file
