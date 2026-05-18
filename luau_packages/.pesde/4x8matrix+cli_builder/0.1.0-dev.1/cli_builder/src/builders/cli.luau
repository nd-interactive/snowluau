local Command = require("./command")
local Option = require("./option")

local mergeArrays = require("../utilities/mergeArrays")
local parseOptions = require("../utilities/parseOptions")
local parseCommand = require("../utilities/parseCommand")
local parseArguments = require("../utilities/parseArguments")
local injectHelpCommand = require("../utilities/injectHelpCommand")
local renderHelpMenu = require("../utilities/renderHelpMenu")
local renderVersionMenu = require("../utilities/renderVersionMenu")
local deepCopy = require("../utilities/deepCopy")

--[=[
	@class CLI
	@__index Prototype
]=]
local CLI = {}

CLI.Interface = {}
CLI.Prototype = {}

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setName(self: CLI, name: string): CLI
	self.name = name

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setDescription(self: CLI, description: string): CLI
	self.description = description

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setVersion(self: CLI, version: string): CLI
	self.version = version

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setLicense(self: CLI, license: string): CLI
	self.license = license

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setGitRepository(self: CLI, repoLink: string): CLI
	self.gitRepoLink = repoLink

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setBugReportUrl(self: CLI, reportLink: string): CLI
	self.bugReportLink = reportLink

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setHomepage(self: CLI, homepageLink: string): CLI
	self.homepageLink = homepageLink

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setCopyright(self: CLI, copyright: string): CLI
	self.copyright = copyright

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setEpilog(self: CLI, epilog: string): CLI
	self.epilog = epilog

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.addAuthor(self: CLI, author: string): CLI
	table.insert(self.authors, author)

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.addCommand(self: CLI, command: Command.Command): CLI
	table.insert(self.commands, command)

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.addOption(self: CLI, option: Option.Option): CLI
	table.insert(self.options, option)

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setCallback(self: CLI, callback: CLICallback): CLI
	self.callback = callback

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.setBeforeRunHook(self: CLI, callback: CLIBeforeHookCallback): CLI
	self.beforeRunCallback = callback

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.configure(
	self: CLI,
	configuration: {
		ansiColorEnabled: boolean?,
	}
): CLI
	if configuration.ansiColorEnabled ~= nil then
		self.configuration.ansiColorEnabled = configuration.ansiColorEnabled
	end

	return self
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.showHelp(
	self: CLI,
	commands: { Command.Command },
	options: { Option.Option },
	commandTree: { Command.Command }?
)
	renderHelpMenu({
		name = self.name,
		description = self.description,
		version = self.version,
		license = self.license,
		gitRepoLink = self.gitRepoLink,
		bugReportLink = self.bugReportLink,
		homepageLink = self.homepageLink,
		copyright = self.copyright,
		epilog = self.epilog,

		colorEnabled = self.configuration.ansiColorEnabled,

		authors = self.authors,
		commands = commands,
		options = options,
	}, commandTree)
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.showVersion(self: CLI, commands: { Command.Command }, options: { Option.Option })
	renderVersionMenu({
		name = self.name,
		description = self.description,
		version = self.version,
		license = self.license,
		gitRepoLink = self.gitRepoLink,
		bugReportLink = self.bugReportLink,
		homepageLink = self.homepageLink,
		copyright = self.copyright,
		epilog = self.epilog,

		authors = self.authors,
		commands = commands,
		options = options,
	})
end

--[=[
	@method
	@within CLI
]=]
function CLI.Prototype.run(self: CLI, args: { string })
	local mutableArgs = table.clone(args)
	local mutableCommands = deepCopy(self.commands) :: { Command.Command }
	local mutableOptions = deepCopy(self.options) :: { Option.Option }

	injectHelpCommand(mutableCommands, mutableOptions, function(context)
		self:showHelp(mutableCommands, mutableOptions, context.commandTree)
	end)

	local globalOptions = parseOptions(mutableOptions, mutableArgs)
	local commandTree = parseCommand(mutableCommands, mutableArgs)
	local command = commandTree[#commandTree]

	if not command then
		if globalOptions.version then
			self:showVersion(mutableCommands, mutableOptions)
		elseif globalOptions.help then
			self:showHelp(mutableCommands, mutableOptions)
		else
			if self.callback then
				if self.beforeRunCallback then
					self.beforeRunCallback({
						globalOptions = globalOptions,
					})
				end

				self.callback(globalOptions)
			else
				self:showHelp(mutableCommands, mutableOptions)
			end
		end

		return
	end

	local options = parseOptions(command.options, mutableArgs)
	local arguments = parseArguments(command, mutableArgs)

	local context = {
		commandTree = commandTree,
		commandOptions = options,
		commandArguments = arguments,

		globalOptions = globalOptions,
	}

	if self.beforeRunCallback then
		self.beforeRunCallback(context)
	end

	if options.help then
		self:showHelp(mutableCommands, mutableOptions, commandTree)

		return
	end

	local callback = command.callback

	callback(context)
end

--[=[
	@within CLI
]=]
function CLI.Interface.new(resource: {
	name: string?,
	description: string?,

	commands: { Command.Command }?,
}?): CLI
	local self = (
		setmetatable({
			name = "Unknown App",
			description = "No description has been set for this CLI App!",

			authors = {},
			commands = {},
			options = {},
			configuration = {
				ansiColorEnabled = true,
			},
		}, { __index = CLI.Prototype }) :: any
	) :: CLI

	if resource then
		if resource.name then
			self:setName(resource.name)
		end

		if resource.description then
			self:setDescription(resource.description)
		end

		if resource.commands then
			for _, command in resource.commands do
				self:addCommand(command)
			end
		end
	end

	return self
end

export type CLICallback = (options: { [string]: Option.OptionType }) -> ()
export type CLIBeforeHookCallback = (
	options: {
		commandTree: { Command.Command }?,
		commandOptions: { [string]: Option.OptionType }?,
		commandArguments: { [string]: string }?,

		globalOptions: { [string]: Option.OptionType },
	}
) -> ()
export type CLI = {
	name: string,
	description: string,
	callback: CLICallback,
	beforeRunCallback: CLIBeforeHookCallback,

	version: string?,
	license: string?,
	gitRepoLink: string?,
	bugReportLink: string?,
	homepageLink: string?,
	copyright: string?,
	epilog: string?,

	authors: { string },
	commands: { Command.Command },
	options: { Option.Option },
	configuration: {
		ansiColorEnabled: boolean,
	},
} & typeof(CLI.Prototype)

return CLI.Interface
