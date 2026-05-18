local Option = require("./option")
local Argument = require("./argument")

--[=[
	@class Command
	@__index Prototype
]=]
local Command = {}

Command.Interface = {}
Command.Prototype = {}

--[=[
	@method
	@within Command
]=]
function Command.Prototype.setName(self: CommandBuilder, name: string): CommandBuilder
	self.name = name

	return self
end

--[=[
	@method
	@within Command
]=]
function Command.Prototype.setDescription(self: CommandBuilder, description: string): CommandBuilder
	self.description = description

	return self
end

--[=[
	@method
	@within Command
]=]
function Command.Prototype.setCallback(self: CommandBuilder, callback: CommandCallback): CommandBuilder
	self.callback = callback

	return self
end

--[=[
	@method
	@within Command
]=]
function Command.Prototype.addOption(self: CommandBuilder, option: Option.Option): CommandBuilder
	table.insert(self.options, option)

	return self
end

--[=[
	@method
	@within Command
]=]
function Command.Prototype.addArgument(self: CommandBuilder, argument: Argument.Argument): CommandBuilder
	table.insert(self.arguments, argument)

	return self
end

--[=[
	@method
	@within Command
]=]
function Command.Prototype.addSubCommand(self: CommandBuilder, command: Command): CommandBuilder
	table.insert(self.subcommands, command)

	return self
end

--[=[
	@method
	@within Command
]=]
function Command.Prototype.build(self: CommandBuilder): Command
	assert(typeof(self.name) == "string", `Expected name to be a string, got '{typeof(self.name)}'`)
	assert(typeof(self.callback) == "function", `Expected name to be a function, got '{typeof(self.callback)}'`)

	return {
		name = self.name,
		description = self.description or "No description set for this Command!",
		callback = self.callback,
		options = self.options,
		arguments = self.arguments,
		subcommands = self.subcommands,
	}
end

--[=[
	@within Command
]=]
function Command.Interface.new(resource: {
	name: string?,
	description: string?,
	callback: CommandCallback?,
	options: { Option.Option }?,
	arguments: { Argument.Argument }?,
	subcommands: { Command }?,
}?): CommandBuilder
	local self = (
		setmetatable({
			subcommands = {},
			options = {},
			arguments = {},
		}, { __index = Command.Prototype }) :: any
	) :: CommandBuilder

	if resource then
		if resource.name then
			self:setName(resource.name)
		end

		if resource.description then
			self:setDescription(resource.description)
		end

		if resource.callback then
			self:setCallback(resource.callback)
		end

		if resource.options then
			for _, option in resource.options do
				self:addOption(option)
			end
		end

		if resource.arguments then
			for _, argument in resource.arguments do
				self:addArgument(argument)
			end
		end

		if resource.subcommands then
			for _, subcommand in resource.subcommands do
				self:addSubCommand(subcommand)
			end
		end
	end

	return self
end

export type CommandContext = {
	commandTree: { Command },

	commandOptions: { [string]: Option.OptionType },
	commandArguments: { [string]: string },
	globalOptions: { [string]: Option.OptionType },
}
export type CommandCallback = (context: CommandContext) -> ()
export type CommandBuilder = {
	name: string?,
	description: string?,
	callback: CommandCallback?,

	subcommands: { Command },
	options: { Option.Option },
	arguments: { Argument.Argument },
} & typeof(Command.Prototype)

export type Command = {
	name: string,
	description: string,
	callback: CommandCallback,

	subcommands: { Command },
	options: { Option.Option },
	arguments: { Argument.Argument },
}

return Command.Interface
