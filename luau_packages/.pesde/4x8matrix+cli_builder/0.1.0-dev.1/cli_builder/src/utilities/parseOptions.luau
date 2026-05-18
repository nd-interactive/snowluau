local Option = require("../builders/option")

return function(optionsDefinitions: { Option.Option }, args: { string })
	local parsedOptions: { [string]: Option.OptionType } = {}
	local optionMap = {}

	for _, optionsDefinition in optionsDefinitions do
		optionMap["--" .. optionsDefinition.name] = optionsDefinition

		for _, alias in optionsDefinition.aliases do
			optionMap["-" .. alias] = optionsDefinition
		end
	end

	local argPosition = 1
	while argPosition <= #args do
		local arg = args[argPosition]
		local consumed = false

		if string.sub(arg, 1, 1) ~= "-" then
			break
		end

		if arg == "--" then
			table.remove(args, argPosition)

			break
		end

		local optName, optValue = arg, nil
		local hasEquals = string.find(arg, "=", 2, true)

		if hasEquals then
			optName, optValue = string.match(arg, "([^=]+)=(.*)") :: string
		end

		local optionDefinition = optionMap[optName]

		if optionDefinition then
			table.remove(args, argPosition)

			consumed = true

			if optionDefinition.type == "boolean" then
				parsedOptions[optionDefinition.name] = true
			else
				local value = optValue

				if value == nil then
					value = args[argPosition]

					if not value or string.sub(value, 1, 1) == "-" then
						error(`Option '{optName}' missing value!`)
					end

					table.remove(args, argPosition)
				end

				parsedOptions[optionDefinition.name] = value
			end
		elseif string.sub(arg, 1, 2) ~= "--" and not hasEquals then
			local firstAlias = string.sub(arg, 1, 2)
			local firstOptDefinition = optionMap[firstAlias]

			if firstOptDefinition and firstOptDefinition.type ~= "boolean" then
				local value = string.sub(arg, 3)

				parsedOptions[firstOptDefinition.name] = value

				table.remove(args, argPosition)

				consumed = true
			else
				local allFlagsAreBooleans = true

				for j = 2, #arg do
					local alias = "-" .. string.sub(arg, j, j)
					local optionDefinition = optionMap[alias]

					if not optionDefinition or optionDefinition.type ~= "boolean" then
						allFlagsAreBooleans = false

						break
					end
				end

				if allFlagsAreBooleans then
					for j = 2, #arg do
						local alias = "-" .. string.sub(arg, j, j)
						local flagDef = optionMap[alias]

						parsedOptions[flagDef.name] = true
					end

					table.remove(args, argPosition)
					consumed = true
				end
			end
		end

		if not consumed then
			argPosition += 1
		end
	end

	for _, optDef in optionsDefinitions do
		if parsedOptions[optDef.name] == nil and optDef.defaultValue ~= nil then
			parsedOptions[optDef.name] = optDef.defaultValue
		end
	end

	return parsedOptions
end
