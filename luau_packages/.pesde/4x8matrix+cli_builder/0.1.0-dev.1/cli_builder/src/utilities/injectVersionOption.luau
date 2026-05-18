local Option = require("../builders/option")

return function(options: { Option.Option })
	table.insert(options, {
		name = "version",
		type = "boolean",
		description = "Display the current version of the application.",
		aliases = { "v" },
	})
end
