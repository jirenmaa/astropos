extends TileMap

const Main = preload("res://scenes/main.gd")

onready var GUIParent = get_parent().get_node("GUI")
onready var HarvestCounter = GUIParent.get_node("FrameCounter").get_node("HarvestCount")

onready var TerminalParent = get_parent().get_node("Terminal").get_node("Wrapper")
onready var TerminalInput = TerminalParent.get_node("FrameInput").get_node("TerminalInput")
onready var TerminalHistory = TerminalParent.get_node("FrameOutput").get_node("TerminalHistory")

var generator: RandomNumberGenerator = RandomNumberGenerator.new()
var MainLoader: Node2D
var loaded: bool = false


func _ready():
	# create instance of the main node
	MainLoader = Main.new()

	generator.randomize()
	init_farm_tiles()

	# user are playing a new game
	if not Global.NEWGAME:
		loaded = MainLoader.load_saved_world(HarvestCounter)

	# user are playing from a saved word
	if not loaded and Global.NEWGAME:
		init_farm_coord()


func _process(_delta: float):
	var tiles = Plant.tiles

	for key in tiles:
		var plant: Dictionary = tiles.get(key)
		var tile_is_dry: bool = plant.stage == "dry"

		if tile_is_dry:
			continue

		# get sum of the interaction (watering and feeding) with the plant
		var watered_times: int = plant.interactions[0]
		var feeded_times: int = plant.interactions[1]

		var growth_stage: Array = check_plant_stage(watered_times, feeded_times, plant.stage)
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


func init_farm_coord() -> void:
	"""Set default values for each tiles from coordinates (a1, a2, ..., d4)"""

	var coordinates: Array = []
	var tiles = Plant.tiles

	# get all the coordinates of the tile that have been used
	for coord in get_used_cells():
		coordinates.append(coord)

	# generate the coordinates basaed on the key row, e.g ('a', 'b', ...)
	for character in Plant.rows:
		for index in Plant.cols:
			var key: String = "{char}{index}".format({"char": character, "index": index + 1})

			# since it need the first element from the array
			# it need to be removed after the coord used
			var coord: Vector2 = coordinates.pop_front()
			# this hold the number of interaction of the plant will make
			var actions: Array = [null, null]
			var interaction: Array = [0, 0, actions]

			tiles[key] = {
				"interactions": interaction,
				"coord": coord,
				"stage": Plant.stages[0],  # dry
				"status": Plant.status.default[0],  # empty
				"timer": 0,
				"delay": 0
			}


func init_farm_tiles() -> void:
	"""Get all available tile names from a tileset"""

	var tile_names: Array = []

	# store all the tile names
	for tile in tile_set.get_tiles_ids():
		# get tile name only instead of the whole name
		# example: "name.png 0" => "name"
		var tile_name: String = tile_set.tile_get_name(tile)
		var name_only: String = tile_name.split(".")[0]

		tile_names.append(name_only)

	Plant.status.tiles = tile_names


func update_tile_status(coord: Vector2, condition: String) -> void:
	var tile_index = Plant.status["tiles"].find(condition)
	var tile_names = tile_set.tile_get_name(tile_index)
	var tile_index_from_name = tile_set.find_tile_by_name(tile_names)

	set_cell(int(coord.x), int(coord.y), tile_index_from_name)


func check_plant_stage(water_count: int, feed_count: int, current_stage: String) -> Array:
	# need this much number of watering and feeding to make
	# the plant go into the next stage
	var total: Dictionary = {
		"seeded": [2, 3],
		"seedling": [4, 4],
		"budding": [7, 5],
		"flowering": [8, 7],
		"ripening": [null, null]
	}
	var count: Array = total.get(current_stage, null)

	# if the current plant already in 'ripening' stage then skip this step
	if typeof(count) == 0 or current_stage == "ripening":
		return [current_stage, false]

	var keys: Array = total.keys()
	# if the current plant of water and feed already reach the
	# minimum to reach the next stage, then return the next stage
	# of the current plant
	if (water_count >= count[0]) and (feed_count >= count[1]):
		var next_stage = keys.find(current_stage) + 1
		return [keys[next_stage], true]

	return [current_stage, false]
