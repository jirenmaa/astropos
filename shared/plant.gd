extends Node

export var rows: Array = ["a", "b", "c", "d"]
export var tiles: Dictionary = {}
export var cols: int = rows.size()

export var stages: Array = ["dry", "seeded", "seedling", "budding", "flowering", "ripening"]
export var status: Dictionary = {
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

export var interactions: Array = [
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
		"exit to main menu, with auto saving"
	]
]
