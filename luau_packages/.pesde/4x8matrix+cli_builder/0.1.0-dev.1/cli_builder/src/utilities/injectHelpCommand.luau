local Command = require("../builders/command")
local Option = require("../builders/option")

local function injectCommands(command: Command.Command, commands: { Command.Command })
	for _, targetCommand in commands do
		injectCommands(command, targetCommand.subcommands)
	end

	table.insert(commands, command)
end

local function injectOptions(option: Option.Option, commands: { Command.Command })
	for _, command in commands do
		injectOptions(option, command.subcommands)

		table.insert(command.options, option)
	end
end

return function(commands: { Command.Command }, options: { Option.Option }, callback: (Command.CommandContext) -> ())
	local helpCommand = {
		name = "help",
		description = "Show available commands and usage information.",
		callback = function(context)
			callback(context)
		end,

		subcommands = {},
		options = {},
		arguments = {},
	} :: Command.Command

	local helpOption = {
		name = "help",
		aliases = { "h" },
		type = "boolean",
		description = "Show available commands and usage information.",
	} :: Option.Option

	injectOptions(helpOption, commands)
	injectCommands(helpCommand, commands)

	table.insert(options, helpOption)
end
