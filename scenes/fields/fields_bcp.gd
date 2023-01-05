extends TileMap

onready var TerminalParent = get_parent().get_node("Terminal")
onready var GUIParent = get_parent().get_node("GUI")

onready var HarvestCounter = GUIParent.get_node("FrameCounter").get_node("HarvestCount")
onready var TerminalInput = TerminalParent.get_node("FrameInput").get_node("TerminalInput")
onready var TerminalHistory = TerminalParent.get_node("FrameOutput").get_node("TerminalHistory")

var conf: String = "res://config.cfg"
var roots: String = "res://saved_world"
var nsize: int = 32  # filename size
var loaded: bool = false

var tiles: Dictionary = {}
var rows: Array = ["a", "b", "c", "d"]
var cols: int = rows.size()

const interactions: Array = [
	# commands interaction
	["plant", "water", "feed", "harvest", "clear", "help", "save", "exit"],
	# commands descriptions
	[
		"planting at <coord_1, coord_n>",
		"watering at <coord_1, coord_n>",
		"feeding at <coord_1, coord_n>",
		"harvesting at <coord_1, coord_n>",
		"clears the terminals",
		"it can help you",
		"(saving your game data)",
		"exit to main menu, without saving"
	]
]

const stages: Array = ["dry", "seeded", "seedling", "budding", "flowering", "ripening"]

const status: Dictionary = {
	# other necessary stuff
	"default": ["empty", "planted"],
	"tiles": [],
	# stage status (for tiles)
	# seeded => seedling => budding => flowering => ripening
	"seedling": ["seedling", "seedling-watered", "seedling-feeded"],
	"seeded": ["seeded", "seeded-watered", "seeded-feeded"],
	"ripening": ["ripening"],
	"budding": ["budding", "budding-watered", "budding-feeded"],
	"flowering": ["flowering", "flowering-watered", "flowering-feeded"]
}

var generator = RandomNumberGenerator.new()
var regex = RegEx.new()

# for scaling animation
var scaled: bool = false
var size_x = scale.x
var size_y = scale.y
var counter = 6


func _ready():
	generator.randomize()
	init_farm_tiles()

	if not Global.DEVELOPMENT:
		roots = Global.PRODUCTION_SAVED

	# is making new game
	if not Global.NEWGAME:
		loaded = load_saved_world()

	# is load saved game
	if not loaded and Global.NEWGAME:
		init_farm_coord()

	var _timer = Timer.new()
	add_child(_timer)

	_timer.connect("timeout", self, "_on_Timer_timeout")
	_timer.set_wait_time(0.175)
	_timer.set_one_shot(false)
	_timer.start()

	# escape any special character
	regex.compile("^[\\w&.\\-\\s]*$")


func _process(_delta: float):
	for key in tiles:
		var plant = tiles.get(key)
		var tile_is_dry: bool = plant.stage == "dry"

		if tile_is_dry:
			continue

		# get sum of the interaction (watering and feeding) with the plant
		var watered_times = plant.interactions[0]
		var feeded_times = plant.interactions[1]

		var growth_stage = check_plant_stage(watered_times, feeded_times, plant.stage)
		if growth_stage[1]:
			tiles[key]["stage"] = growth_stage[0]
			# set delay for growth stage, so it'll not looked like static
			tiles[key]["delay"] = OS.get_unix_time() + generator.randi_range(2, 5)

		# check if the delay time already done
		if plant.delay < OS.get_unix_time() and not plant.delay == 0:
			tiles[key]["delay"] = 0
			update_tile_status(plant.coord, plant.stage)

		# remove the status given to the current plant
		var current_timer: int = OS.get_unix_time()
		var not_running: bool = plant.timer == 0
		var time_passed: bool = plant.timer < current_timer

		# check wether the status timer is already passed
		# if not then keep the status until the timer ends,
		# if not then update the status the tile plant
		if not not_running and not time_passed:
			update_tile_status(plant.coord, plant.status)
			continue

		update_tile_status(plant.coord, plant.stage)


# INIT
func init_farm_coord() -> void:
	var coordinates: Array = []

	# get all the coordinates of the tile that have been used
	for coord in get_used_cells():
		coordinates.append(coord)

	# generate the coordinates basaed on the key row, e.g ('a', 'b', ...)
	for character in rows:
		for index in cols:
			var key: String = "{char}{index}".format({"char": character, "index": index + 1})

			# since it need the first element from the array
			# it need to be removed after the coord used
			var coord: Vector2 = coordinates.pop_front()
			# this hold the number of interaction of the plantey make
			var actions: Array = [null, null]
			var interaction: Array = [0, 0, actions]

			tiles[key] = {
				"interactions": interaction,
				"coord": coord,
				"stage": stages[0],  # dry
				"status": status.default[0],  # empty
				"timer": 0,
				"delay": 0
			}


func init_farm_tiles() -> void:
	# get all available tile names from tileset

	var tile_names: Array = []

	# store all the tile names
	for tile in tile_set.get_tiles_ids():
		# get tile name only instead of the whole name
		# example: "name.png 0" => "name"
		var tile_name: String = tile_set.tile_get_name(tile)
		var name_only: String = tile_name.split(".")[0]

		tile_names.append(name_only)

	status.tiles = tile_names


# DONE INIT


# PROCESS
func _on_Timer_timeout():
	if scaled and counter < 6:
		size_x += 0.01
		size_y += 0.01
		counter += 1
		scaled = true
		scale = Vector2(size_x, size_y)
	else:
		scaled = false

	if not scaled and counter >= 0:
		size_x -= 0.01
		size_y -= 0.01
		counter -= 1
		scaled = false
		scale = Vector2(size_x, size_y)
	else:
		scaled = true


func update_tile_status(coord: Vector2, condition: String) -> void:
	var tile_index = status["tiles"].find(condition)
	var tile_names = tile_set.tile_get_name(tile_index)
	var tile_index_from_name = tile_set.find_tile_by_name(tile_names)

	set_cell(int(coord.x), int(coord.y), tile_index_from_name)


func check_plant_stage(water_count: int, feed_count: int, current_stage: String) -> Array:
	var total: Dictionary = {
		"seeded": [2, 3],  # need this much count to get the next stage
		"seedling": [4, 4],
		"budding": [7, 5],
		"flowering": [8, 7],
		"ripening": [null, null]
	}
	var count = total.get(current_stage, null)
	var keys: Array = total.keys()

	if typeof(count) == 0 or current_stage == "ripening":
		return [current_stage, false]

	if (water_count >= count[0]) and (feed_count >= count[1]):
		var next_stage = keys.find(current_stage) + 1
		return [keys[next_stage], true]

	return [current_stage, false]


# DONE PROCESS


# INTERACTIONS
func plant(kwargs: Array) -> String:
	var response = "skipped planting at coordinate "
	var error = false
	var skip_coord = []

	for coord in kwargs:
		var tile = tiles.get(coord, null)

		if not tile:
			continue

		# check wether the plant is "dry". If not, instead of updating the stage
		# the current action will be skipped. So it will not be replacing the
		# "staged" plant to the default plant "seeded".
		if not tile.stage == "dry":
			error = true
			skip_coord.append(coord)
			continue

		# var temp = [8, 7, tile.interactions[2]]
		tiles[coord] = {
			# "interactions": temp,
			"interactions": tile.interactions,
			"coord": tile.coord,
			"stage": stages[1],
			"status": status.default[1],
			"timer": 0,
			"delay": tile.delay
		}
		tile = tiles[coord]

		# update the tiles with the correspond plant default stage
		update_tile_status(tile.coord, tile.stage)

	if error:
		return response + "<" + PoolStringArray(skip_coord).join(", ") + ">"
	return ""


func water(kwargs: Array) -> String:
	var response = "skipped watering at coordinate "
	var error = false
	var skip_coord = []

	for coord in kwargs:
		var tile = tiles.get(coord, null)

		if not tile:
			continue

		# if the current tile is empty (not planted) the skip this action.
		# And player also cannot watering a tile that already watered.
		if "empty" in tile.status or "water" in tile.stage:
			error = true
			skip_coord.append(coord)
			continue

		# get the current stage for checking the stage of the plant
		var stage: String = tile.stage.split("-")[0]
		var current_status = status.get(stage, null)
		# this will check if the plant already in stage of "ripening"
		# if yes this action will be skipped
		if tile.stage == "ripening":
			continue

		var actions = tile.interactions[2]
		# check wether the last interaction is "feed" or "water".
		# the the action is same as the current action, then skip
		# the current action
		var is_status_passed: bool = tile.timer < OS.get_unix_time()
		if not is_status_passed and actions[0] == "feed":
			continue

		# update the plant interactions, insert the newest interaction
		# in the front of the list, and remove the last element if only
		# the length of the array is larger than two
		actions.insert(0, "water")
		if actions.size() > 2:
			actions.pop_back()

		# (updates) make changes to overall plant status

		# update the interactions of the plant
		tile.interactions[2] = actions
		# increment the number of "watered" times
		tile.interactions[0] = tile.interactions[0] + 1

		# update status timer for the plant actions
		var timer = OS.get_unix_time() + generator.randi_range(15, 25)
		# get the timer remainder of the last action,
		# and the remainder cannot be a negative number
		var remainder: int = int(max(0, tile.timer - OS.get_unix_time()))

		tiles[coord].status = current_status[1]
		tiles[coord].timer = remainder + timer
		tile = tiles[coord]

		# update the tiles with the correspond plant current given status
		update_tile_status(tile.coord, tile.status)

	if error:
		return response + "<" + PoolStringArray(skip_coord).join(", ") + ">"
	return ""


func feed(kwargs: Array) -> String:
	var response = "skipped feeding at coordinate "
	var error = false
	var skip_coord = []

	for coord in kwargs:
		var tile = tiles.get(coord, null)

		if not tile:
			continue

		# if the current tile is empty (not planted) the skip this action.
		# And player also cannot feeding a tile that already feeded.
		if "empty" in tile.status or "feed" in tile.stage:
			error = true
			skip_coord.append(coord)
			continue

		# get the current stage for checking the stage of the plant
		var stage: String = tile.stage.split("-")[0]
		var current_status = status.get(stage, null)
		# this will check if the plant already in stage of "ripening"
		# if yes this action will be skipped
		if tile.stage == "ripening":
			continue

		var actions = tile.interactions[2]
		# check wether the last interaction is "feed" or "water".
		# the the action is same as the current action, then skip
		# the current action
		var is_status_passed: bool = tile.timer < OS.get_unix_time()
		if not is_status_passed and actions[0] == "water":
			continue

		# update the plant interactions, insert the newest interaction
		# in the front of the list, and remove the last element if only
		# the length of the array is larger than two
		actions.insert(0, "feed")
		if actions.size() > 2:
			actions.pop_back()

		# (updates) make changes to overall plant status

		# update the interactions of the plant
		tile.interactions[2] = actions
		# increment the number of "watered" times
		tile.interactions[1] = tile.interactions[1] + 1

		# update status timer for the plant actions
		var timer = OS.get_unix_time() + generator.randi_range(15, 25)
		# get the timer remainder of the last action,
		# and the remainder cannot be a negative number
		var remainder: int = int(max(0, tile.timer - OS.get_unix_time()))

		tiles[coord].status = current_status[2]
		tiles[coord].timer = remainder + timer
		tile = tiles[coord]

		# update the tiles with the correspond plant current given status
		update_tile_status(tile.coord, tile.status)

	if error:
		return response + "<" + PoolStringArray(skip_coord).join(", ") + ">"
	return ""


func harvest(kwargs: Array) -> String:
	var response = "skipped harvesting at coordinate "
	var error = false
	var skip_coord = []

	for coord in kwargs:
		var tile = tiles.get(coord, null)

		if not tile:
			continue

		# if the current tile is empty (not planted) the skip this action.
		if "empty" in tile.status or not tile.stage == "ripening":
			error = true
			skip_coord.append(coord)
			continue

		# this hold the number of interaction of the plantey make
		var actions: Array = [null, null]
		var interaction: Array = [0, 0, actions]

		tiles[coord] = {
			"interactions": interaction,
			"coord": tile.coord,
			"stage": stages[0],  # dry
			"status": status.default[0],  # empty
			"timer": 0,
			"delay": 0
		}
		tile = tiles[coord]

		var increaseTotal = int(HarvestCounter.text) + 1
		HarvestCounter.text = str(increaseTotal)

		# update the tiles with the correspond plant default stage
		update_tile_status(tile.coord, tile.stage)

	if error:
		return response + "<" + PoolStringArray(skip_coord).join(", ") + ">"
	return ""


func save() -> String:
	var configFile = ConfigFile.new()
	configFile.load(conf)
	var saved_count = configFile.get_value("Config", "saved_count")

	var file = File.new()
	var filename = generate_key(false, nsize)
	var password = generate_key(false, nsize)

	# bucket for storing the sliced password
	# the size also reduced from 32 -> 16
	var sliced_pass = ""
	if Global.NEWGAME:
		# iterate through the filename, and insert
		# the password between the character with given index
		for index in range(len(filename)):
			if not index & 1 == 0:
				continue

			# insert character if the index is odd
			sliced_pass += password[index]
			filename = filename.insert(index, password[index])

		configFile.set_value("Config", "saved_count", saved_count + 1)

	if not Global.NEWGAME:
		# make sure to get the basename only and not the extension
		filename = Global.LOADFILE.split(".")[0]

		# loop through the filename, and retrive the
		# password
		for index in range(nsize):
			if not index & 1 == 0:
				continue

			# add the character for password if the index is odd
			sliced_pass += filename[index]

	var temp = update_tile_saving()

	# set the target file for file
	var target = "{root}/{name}.dat".format({"root": roots, "name": filename})
	var datas = {
		"total_harvest": int(HarvestCounter.text),
		"tiles": temp,
	}

	if int(saved_count) < 5:
		# create a file with given password
		file.open_encrypted_with_pass(target, File.WRITE, sliced_pass)

		file.store_var(datas)
		file.close()
		configFile.save(conf)

		return "Your game data have been saved."
	return "Maximum saved file have been reached 'max 5'"


func load_saved_world() -> bool:
	var dir = Directory.new()
	var file = File.new()

	dir.open("res://saved_world")
	dir.list_dir_begin(true, true)

	# var latest = get_latest_file(file, dir)
	var latest = Global.LOADFILE
	var target = "%s/%s" % [roots, latest]

	if latest == "":
		return false

	# bucket for storing the sliced password
	var sliced_pass = ""
	# loop through the filename, and retrive the
	# password
	for index in range(nsize):
		if not index & 1 == 0:
			continue

		# add the character for password if the index is odd
		sliced_pass += latest[index]

	file.open_encrypted_with_pass(target, File.READ, sliced_pass)
	var data = file.get_var()

	tiles = data.tiles
	update_tile_load()
	HarvestCounter.text = str(data.total_harvest)

	return true


func update_tile_saving():
	var temp = tiles.duplicate(true)  # deepcopy: true

	for coord in temp:
		if temp[coord].timer == 0:
			continue

		temp[coord].timer = temp[coord].timer - OS.get_unix_time()

	return temp


func update_tile_load():
	for coord in tiles:
		if tiles[coord].timer == 0:
			continue

		tiles[coord].timer = OS.get_unix_time() + tiles[coord].timer


# DONE INTERACTIONS


# COMMANDS
func _on_TerminalInput_text_entered(prompt: String) -> void:
	# list of the arguments given by the input
	# example: plant <coord_1, coord_n> => [plant, coord_1, coord_n]
	var commands = prompt.split(" ")
	# get only the first commands, e.g "plant", "feed", "water"
	var command = commands[0]
	# get the rest of the command, exculding the first command,
	# so remove the first element in the commands
	commands.remove(0)
	var arguments = commands

	var output: String = ""
	var response: String = get_command_description(command)
	# check wheter the arguments length lower than one
	# if so, then use the default "command" help message

	# check if the given input is a valid command and does not
	# contain any special character
	var is_valid_commands = regex.search(prompt)
	if not is_valid_commands:
		return

	TerminalInput.clear()  # clear the input terminal
	output = "astropos $ {prompt}".format({"prompt": prompt})

	var valid_command = command.to_lower() in interactions[0]
	var exceeded_comd = not len(arguments) <= 3

	if not command.to_lower() in ["clear", "help", "save"] and valid_command:
		var valid_response = ""

		# the command is valid and the argument is missing
		if len(arguments) == 0 and not exceeded_comd:
			response = "Which coordinate you want to {command}?\n".format({"command": command})
			response += "For example, try '{command} a1'".format({"command": command})

		# the command is valid but the argument exceeded
		if exceeded_comd:
			response = "Maximum of 3 plants may be {command}ed at once.".format(
				{"command": command}
			)

		if not len(arguments) == 0 and not exceeded_comd:
			valid_response = handle_other_commands(command, arguments)
			response = valid_response

		# the command is valid and the argument is present
		if len(arguments) > 0 and not exceeded_comd and valid_response == "":
			response = "{command}ing at <{response}>".format(
				{"command": command, "response": PoolStringArray(arguments).join(", ")}
			)

	if prompt.to_lower() == "clear":
		TerminalHistory.text = ""
		return

	if prompt.to_lower() == "help":
		TerminalHistory.text += output + "\n"
		TerminalHistory.text += help_command()
		TerminalHistory.scroll_vertical = INF
		return

	if prompt.to_lower() == "save":
		response = save()

	if prompt.to_lower() == "exit":
		var _t = get_tree().change_scene("res://scenes/menus/main_menu.tscn")
		return

	if prompt.to_lower() == "ls":
		response = "This is not UNIX based operating system\n"
		response += "Try type 'help', it can help you!"

	TerminalHistory.text += output + "\n"
	# if the given input is empty or just key 'enter'
	# then skip when adding the new linea
	if not response == "":
		TerminalHistory.text += response + "\n\n"

	# auto scroll to the latest text
	TerminalHistory.scroll_vertical = INF


func get_command_description(command: String) -> String:
	# return description for given command
	var commands: Array = interactions[0]

	if command == "":
		return ""

	for index in commands.size():
		if commands[index] == command.to_lower():
			return commands[index]

	return "command not found: {command}".format({"command": command})


func help_command() -> String:
	# return list of command that can be used for player
	var highest_char: int = 8

	var message: String = ""
	var interaction: Array = interactions

	for index in interaction[0].size():
		var action = interaction[0][index]
		var desc = interaction[1][index]

		var space = highest_char - len(action)
		var response = "{action}{space}: {description}\n".format(
			{"action": action, "space": " ".repeat(space), "description": desc}
		)

		if index == interaction[0].size() - 1:
			response += "\n"

		message += response

	return message


func handle_other_commands(command: String, kwargs: Array) -> String:
	match command:
		"plant":
			return plant(kwargs)
		"water":
			return water(kwargs)
		"feed":
			return feed(kwargs)
		"harvest":
			return harvest(kwargs)
		"save":
			return save()
	return ""


# DONE COMMANDS


# UTILS
# Define a function to generate the random key
func generate_key(use_special_char: bool, length: int) -> String:
	# Create a string containing all the characters to use in the key
	var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

	if use_special_char:
		characters += "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"

	# Initialize an empty key string
	var key = ""

	# Generate a random key by choosing 32 random characters from the character string
	for _i in range(length):
		# key += characters[randi() % len(characters)]
		key += characters[generator.randi_range(0, len(characters) - 1)]

	# Return the key
	return key


func get_latest_file(instance, iterator):
	# Initialize variables to store the latest file and its modification time
	var latest_file = ""
	var latest_time = 0
	var _iterate = ""

	# Iterate over the files in the directory
	while true:
		# Get the next file in the directory
		_iterate = iterator.get_next()
		var file = _iterate.get_file()

		if file.get_basename() == "":
			break

		# Get the modification time of the current file
		var time = instance.get_modified_time("{root}/{file}".format({"root": roots, "file": file}))

		# Check if the modification time is greater than the current latest time
		if time > latest_time:
			# Update the latest file and time
			latest_file = file
			latest_time = time

	return latest_file
# END UTILS
