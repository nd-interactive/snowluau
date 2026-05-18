local Command = require("../builders/command")
local Option = require("../builders/option")

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

	authors: { string }?,
	commands: { Command.Command },
	options: { Option.Option },
}

return function(information: Information)
	print(`{information.name} {information.version}`)
end
