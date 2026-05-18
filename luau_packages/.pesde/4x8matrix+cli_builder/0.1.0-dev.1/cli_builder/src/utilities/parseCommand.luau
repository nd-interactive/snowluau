local Command = require("../builders/command")

local function getCommandFromArray(commandName: string, commands: { Command.Command }): Command.Command?
	for _, command in commands do
		if command.name == commandName then
			return command
		end
	end

	return nil
end

return function(commands: { Command.Command }, args: { string }): { Command.Command }
	local commandTree = {}
	local commandsToSearch = commands

	while #args > 0 do
		local commandName = args[1]
		local command = getCommandFromArray(commandName, commandsToSearch)

		if not command then
			break
		end

		commandsToSearch = command.subcommands

		table.insert(commandTree, command)
		table.remove(args, 1)
	end

	return commandTree
end
