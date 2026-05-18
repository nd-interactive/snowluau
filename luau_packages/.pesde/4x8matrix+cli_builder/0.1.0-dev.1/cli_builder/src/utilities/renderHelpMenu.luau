local Command = require("../builders/command")
local Option = require("../builders/option")

local ansiFormat = require("./ansiFormat")

local function formatWithAnsi(information: Information, formats: { ansiFormat.ANSIFormats }, content: string)
	if not information.colorEnabled then
		return content
	end

	local updatedContent = content

	for _, format in formats do
		updatedContent = ansiFormat(format :: ansiFormat.ANSIFormats, updatedContent)
	end

	return updatedContent
end

local function formatSection(
	information: Information,
	title: string,
	items: { { name: string, description: string } },
	longestName: number
)
	if not items or #items == 0 then
		return ""
	end

	local lines = { `\n{title}` }

	for _, item in items do
		local padding = string.rep(" ", longestName - #item.name + 4)
		table.insert(
			lines,
			`  {formatWithAnsi(information, {
				"Green",
				"Bold",
			}, item.name)}{padding}{item.description}`
		)
	end

	return table.concat(lines, "\n")
end

local function formatSections(
	information: Information,
	items: {
		{
			title: string,
			content: { { name: string, description: string } },
		}
	}
): string
	local longestName = 0
	local parts = {}

	for _, item in items do
		for _, content in item.content do
			if #content.name > longestName then
				longestName = #content.name
			end
		end
	end

	for _, item in items do
		table.insert(parts, formatSection(information, item.title, item.content, longestName))
	end

	return table.concat(parts, "\n")
end

local function generateCommandHelp(information: Information, commandTree: { Command.Command })
	local command = commandTree[#commandTree]
	local parts = {}

	local commandPathComponents = {}
	local argumentComponents = {}

	for _, command in commandTree do
		table.insert(commandPathComponents, command.name)
	end

	for _, argument in command.arguments do
		table.insert(argumentComponents, `<{argument.name}>`)
	end

	table.insert(parts, `{command.description}`)
	table.insert(
		parts,
		`\n{formatWithAnsi(information, { "Yellow", "Underline" }, `Usage:`)}\n  {information.name} {table.concat(
			commandPathComponents,
			" "
		)} [options] {table.concat(argumentComponents, " ")}`
	)

	local argumentsList = {}
	local optionsList = {}
	local subcommandList = {}

	for _, argument in command.arguments do
		table.insert(argumentsList, {
			description = argument.description,
			name = argument.name,
		})
	end

	for _, option in information.options do
		local names = {}

		for _, alias in option.aliases do
			table.insert(names, `-{alias}`)
		end

		if option.valueName then
			table.insert(names, `--{option.name}={option.valueName}`)
		else
			table.insert(names, `--{option.name}`)
		end

		table.insert(optionsList, {
			description = `{option.description}`,
			name = `{table.concat(names, ", ")}`,
		})
	end

	for _, subcommand in command.subcommands do
		table.insert(subcommandList, {
			description = subcommand.description,
			name = subcommand.name,
		})
	end

	table.insert(
		parts,
		formatSections(information, {
			{
				title = formatWithAnsi(information, { "Yellow", "Underline" }, `Arguments:`),
				content = argumentsList,
			},
			{
				title = formatWithAnsi(information, { "Yellow", "Underline" }, `Options:`),
				content = optionsList,
			},
			{
				title = formatWithAnsi(information, { "Yellow", "Underline" }, `Commands:`),
				content = subcommandList,
			},
		})
	)

	print(table.concat(parts, "\n"))
end

local function generateGlobalHelp(information: Information)
	local parts = {}

	table.insert(parts, `{information.name} {information.version or ""}`)
	table.insert(parts, `{information.description}`)
	table.insert(parts, `\n{formatWithAnsi(information, { "Yellow", "Underline" }, `Usage:`)}\n  {information.name}`)

	local commandsList = {}
	local optionsList = {}

	for _, command in information.commands do
		table.insert(commandsList, {
			description = `{command.description}`,
			name = `{command.name}`,
		})
	end

	for _, option in information.options do
		local names = {}

		for _, alias in option.aliases do
			table.insert(names, `-{alias}`)
		end

		table.insert(names, `--{option.name}`)

		table.insert(optionsList, {
			description = `{option.description}`,
			name = `{table.concat(names, ", ")}`,
		})
	end

	table.insert(
		parts,
		formatSections(information, {
			{
				title = formatWithAnsi(information, { "Yellow", "Underline" }, `Commands:`),
				content = commandsList,
			},
			{
				title = formatWithAnsi(information, { "Yellow", "Underline" }, `Options:`),
				content = optionsList,
			},
		})
	)

	if information.homepageLink then
		table.insert(
			parts,
			formatWithAnsi(
				information,
				{},
				`\nFor more information, visit {formatWithAnsi(information, {
					"Bold",
				}, information.homepageLink)}`
			)
		)
	end

	if information.gitRepoLink then
		table.insert(
			parts,
			formatWithAnsi(
				information,
				{},
				`Source code can be found at {formatWithAnsi(information, {
					"Bold",
				}, information.gitRepoLink)}`
			)
		)
	end

	if information.bugReportLink then
		table.insert(
			parts,
			formatWithAnsi(
				information,
				{},
				`Found a bug? Report it at {formatWithAnsi(information, {
					"Bold",
				}, information.bugReportLink)}`
			)
		)
	end

	if information.epilog then
		table.insert(parts, `\n{information.epilog}`)
	end

	table.insert(parts, "")

	if #information.authors ~= 0 then
		table.insert(
			parts,
			formatWithAnsi(information, { "Grey", "Italic" }, `Authors: {table.concat(information.authors, ", ")}`)
		)
	end

	if information.license then
		table.insert(parts, formatWithAnsi(information, { "Grey", "Italic" }, `License: {information.license}`))
	end

	if information.copyright then
		table.insert(parts, formatWithAnsi(information, { "Grey", "Italic" }, `\n{information.copyright}`))
	end

	print(table.concat(parts, "\n"))
end

type Information = {
	name: string,
	description: string,
	version: string?,
	license: string?,
	gitRepoLink: string?,
	bugReportLink: string?,
	homepageLink: string?,
	copyright: string?,
	epilog: string?,

	colorEnabled: boolean,

	authors: { string },
	commands: { Command.Command },
	options: { Option.Option },
}

return function(information: Information, commandTree: { Command.Command }?)
	if commandTree then
		local latestCommand = commandTree[#commandTree]

		if #commandTree == 1 and latestCommand.name == "help" then
			generateGlobalHelp(information)
		else
			table.remove(commandTree, #commandTree)

			generateCommandHelp(information, commandTree)
		end
	else
		generateGlobalHelp(information)
	end
end
