local Transform = require("@transform")
local StringExt = require("@std/stringext")

local transformer: Transform.Migration = {
	transform = function(context: Transform.Context<{ [any]: any }>)
        local new_lines = {}
        for index, line in string.split(context.source, "\n") do
            new_lines[index] = StringExt.trim(line)
        end

		return table.concat(new_lines, "\n")
	end,
}

return transformer