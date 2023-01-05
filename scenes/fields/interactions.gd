extends "res://scenes/fields/fields.gd"


func plant(kwargs: Array) -> String:
	var message: String = "skipped planting at coordinate"
	var skipped_coordinate: Array = []

	# create a copy from plant tiles, it will also
	# make changes to the original tiles (IT'S OK)
	var tiles = Plant.tiles

	for coordinate in kwargs:
		var plant = tiles.get(coordinate, null)

		# check if the plant stage is 'dry'. If not, insttead updating the stage
		# the current action will be skipped, so it will not be replacing the
		# 'staged' plant to the default plant wich is 'seeded'.
		if not plant or not "dry" in plant.stage:
			skipped_coordinate.append(coordinate)
			continue

		tiles[coordinate] = {
			"interactions": plant.interactions,
			"coord": plant.coord,
			"stage": Plant.stages[1],
			"status": Plant.status.default[1],
			"timer": 0,
			"delay": plant.delay
		}
		plant = tiles.get(coordinate, null)

		# update the plant stage with the correspond stage
		update_tile_status(plant.coord, plant.stage)

	if skipped_coordinate.size():
		var coords = PoolStringArray(skipped_coordinate).join(", ")
		return "%s <%s>" % [message, coords]

	return ""


func water(kwargs: Array) -> String:
	var message: String = "skipped watering at coordinate"
	var skipped_coordinate: Array = []

	# create a copy from plant tiles, it will also
	# make changes to the original tiles (IT'S OK)
	var tiles = Plant.tiles

	for coordinate in kwargs:
		var plant = tiles.get(coordinate, null)

		# if the current plant status is empty (not planted) then
		# skip this action, and player can't stack a status
		if not plant or "empty" in plant.status or "water" in plant.stage:
			skipped_coordinate.append(coordinate)
			continue

		# skip this action if the current plant already ripening
		if "ripening" in plant.stage:
			continue

		# get current stage from a plant, only the stage an not the status
		# beacuse the naming looked like this : 'seeded-watered'
		var current_stage: String = plant.stage.split("-")[0]
		var current_status = Plant.status.get(current_stage, null)

		var actions: Array = plant.interactions[2]
		# compare the plant status timer with current time
		var is_status_paseed: bool = plant.timer < OS.get_unix_time()

		if not is_status_paseed and actions[0] == "feed":
			continue

		# insert new interactions to the actions
		actions.insert(0, "water")
		# delete the earliest action if the actions already
		# reach the maximum of 2
		if actions.size() > 2:
			actions.pop_back()

		plant.interactions[2] = actions
		# increment the number of 'watered' times
		plant.interactions[0] = plant.interactions[0] + 1

		var status_timer: int = OS.get_unix_time() + generator.randi_range(15, 25)
		# get the timer remainder from the last action,
		# it to prevent any messed up timer when player
		# are playing from loaded save game
		var remainder: int = int(max(0, plant.timer - OS.get_unix_time()))

		tiles[coordinate].status = current_status[1]
		tiles[coordinate].timer = remainder + status_timer
		plant = tiles.get(coordinate, null)

		# update the plant stage with the correspond stage
		update_tile_status(plant.coord, plant.stage)

	if skipped_coordinate.size():
		var coords = PoolStringArray(skipped_coordinate).join(", ")
		return "%s <%s>" % [message, coords]

	return ""


func feed(kwargs: Array) -> String:
	var message: String = "skipped feeding at coordinate"
	var skipped_coordinate: Array = []

	# create a copy from plant tiles, it will also
	# make changes to the original tiles (IT'S OK)
	var tiles = Plant.tiles

	for coordinate in kwargs:
		var plant = tiles.get(coordinate, null)

		# if the current plant status is empty (not planted) then
		# skip this action, and player can't stack a status
		if not plant or "empty" in plant.status or "feed" in plant.stage:
			skipped_coordinate.append(coordinate)
			continue

		# skip this action if the current plant already ripening
		if "ripening" in plant.stage:
			continue

		# get current stage from a plant, only the stage an not the status
		# beacuse the naming looked like this : 'seeded-watered'
		var current_stage: String = plant.stage.split("-")[0]
		var current_status = Plant.status.get(current_stage, null)

		var actions: Array = plant.interactions[2]
		# compare the plant status timer with current time
		var is_status_paseed: bool = plant.timer < OS.get_unix_time()

		if not is_status_paseed and actions[0] == "feed":
			continue

		# insert new interactions to the actions
		actions.insert(0, "feed")
		# delete the earliest action if the actions already
		# reach the maximum of 2
		if actions.size() > 2:
			actions.pop_back()

		plant.interactions[2] = actions
		# increment the number of 'watered' times
		plant.interactions[1] = plant.interactions[1] + 1

		var status_timer: int = OS.get_unix_time() + generator.randi_range(15, 25)
		# get the timer remainder from the last action,
		# it to prevent any messed up timer when player
		# are playing from loaded save game
		var remainder: int = int(max(0, plant.timer - OS.get_unix_time()))

		tiles[coordinate].status = current_status[2]
		tiles[coordinate].timer = remainder + status_timer
		plant = tiles.get(coordinate, null)

		# update the plant stage with the correspond stage
		update_tile_status(plant.coord, plant.stage)

	if skipped_coordinate.size():
		var coords = PoolStringArray(skipped_coordinate).join(", ")
		return "%s <%s>" % [message, coords]

	return ""


func harvest(kwargs: Array) -> String:
	var message: String = "skipped harvesting at coordinate"
	var skipped_coordinate: Array = []

	# create a copy from plant tiles, it will also
	# make changes to the original tiles (IT'S OK)
	var tiles = Plant.tiles

	for coordinate in kwargs:
		var plant = tiles.get(coordinate, null)

		# if the current plant status is empty (not planted) or
		# plant are not ripen yet then skip this action
		if not plant or "empty" in plant.status or not plant.stage == "ripening":
			skipped_coordinate.append(coordinate)
			continue

		# update the plant actions and interaction to the default
		# after the plant is been ahrevested
		var actions: Array = [null, null]
		var interaction: Array = [0, 0, actions]

		tiles[coordinate] = {
			"interactions": interaction,
			"coord": plant.coord,
			"timer": 0,
			"delay": 0,
			"stage": Plant.stages[0],
			"status": Plant.status.default[0]
		}
		plant = tiles[coordinate]

		var totalHarvest: int = (HarvestCounter.text as int) + 1
		HarvestCounter.text = totalHarvest as String

		# update the plant stage with the correspond stage
		update_tile_status(plant.coord, plant.stage)

	if skipped_coordinate.size():
		var coords = PoolStringArray(skipped_coordinate).join(", ")
		return "%s <%s>" % [message, coords]

	return ""
