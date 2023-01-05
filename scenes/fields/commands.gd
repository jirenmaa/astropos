extends "res://scenes/fields/interactions.gd"

var regex: RegEx


func _ready():
	regex = RegEx.new()
	# escape any special character, except whitespaces
	var _z = regex.compile("^[\\w&.\\-\\s]*$")


func get_command_and_arguments(prompt: String) -> Dictionary:
	# split the prompt into list of an arguments,
	# example: plant <a1, a2> => [plant, a1, a2]
	var argv: Array = prompt.split(" ")

	# get the command name
	var command: String = argv[0]
	# because we already get the command, then we need
	# to remove the that element in list, it will make
	# easier to get all the arguments instead using array slice
	argv.remove(0)
	var arguments: Array = argv

	return {"command": command, "arguments": arguments}


func command_plant_interaction(command: String, arguments: Array) -> String:
	var response: String = ""
	var command_is_exceeded: bool = not arguments.size() <= 3

	var is_valid_command: bool = command.to_lower() in Plant.interactions[0]
	var other_commands: Array = ["clear", "help", "save", "exit"]

	if command.to_lower() in other_commands:
		return response

	if arguments.size() == 0 and not command_is_exceeded and is_valid_command:
		response += "which coordinate you want to %s?\n" % command
		response += "For example, try '%s a1'" % command

	if command_is_exceeded and is_valid_command:
		response += "Maximum of 3 plants may be %sed at once" % command

	if not arguments.size() == 0 and not command_is_exceeded and is_valid_command:
		var coords: String = PoolStringArray(arguments).join(", ")
		response = "%sing at <%s>" % [command, coords]

		var interaction_msg: String = handle_interactions(command, arguments)
		if not interaction_msg == "":
			response = "%s" % interaction_msg

	return response


func command_other_interaction(command: String) -> String:
	command = command.to_lower()
	var response: String = check_command_availability(command)

	match command:
		"help":
			return handle_help()
		"clear":
			TerminalHistory.text = ""
			return ""
		"save":
			var counter: int = int(HarvestCounter.text)
			return MainLoader.save(counter)
		"exit":
			var _z
			var counter: int = int(HarvestCounter.text)

			_z = MainLoader.save(counter)
			_z = get_tree().change_scene("res://scenes/menus/main_menu.tscn")
			return ""

	if command in Global.EASTEREGG:
		response = "This is not UNIX based operating system\n"
		response += "Try type 'help', it can help you!"

	return response


func check_command_availability(command: String) -> String:
	if command == "":
		return ""

	var commands: Array = Plant.interactions[0]

	for index in commands.size():
		if commands[index] == command.to_lower():
			return commands[index]

	return "command not found: {command}".format({"command": command})


func handle_interactions(command: String, arguments: Array) -> String:
	match command:
		"plant":
			return plant(arguments)
		"water":
			return water(arguments)
		"feed":
			return feed(arguments)
		"harvest":
			return harvest(arguments)
	return ""


func handle_help() -> String:
	# the command with the most characters
	var highest_charater: int = 8

	var message: String = ""
	var interaction: Array = Plant.interactions

	var commands: Array = interaction[0]
	var descriptions: Array = interaction[1]

	for index in commands.size():
		var action: String = commands[index]
		var desc: String = descriptions[index]

		var spaces = " ".repeat(highest_charater - len(action))
		var response = "%s%s: %s" % [action, spaces, desc]

		if not index == commands.size() - 1:
			response += "\n"

		message += response

	return message


func _on_TerminalInput_text_entered(prompt: String) -> void:
	# validate the given input that have special character
	if not regex.search(prompt):
		return

	var argv: Dictionary = get_command_and_arguments(prompt)
	var command: String = argv.command
	var arguments: Array = argv.arguments

	var output: String = "astropos $ {prompt}".format({"prompt": prompt})
	var response: String

	TerminalInput.clear()

	var temp: String
	temp = command_plant_interaction(command, arguments)

	# the commands are not an interation command, then
	# change the response to the order comamnd response
	if temp.empty():
		response = command_other_interaction(command)
	else:
		response = temp

	if not response.empty():
		TerminalHistory.text += output + "\n"

	if not response.empty():
		TerminalHistory.text += response + "\n\n"

	# auto scroll to the bottom of the terminal
	TerminalHistory.scroll_vertical = INF
