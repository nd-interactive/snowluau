export type ANSIFormats = "Underline" | "Bold" | "Green" | "Yellow" | "Cyan" | "Blue" | "Italic" | "Grey"

local RESET_CODE = "0"
local FORMAT_MAP = table.freeze({
	Bold = "1",
	Underline = "4",
	Italic = "3",
	Grey = "90",

	Green = "32",
	Yellow = "33",
	Cyan = "36",
	Blue = "34",
})

return function(format: ANSIFormats, content: string): string
	local codes = {}

	for formatName in string.gmatch(format, "[^%s]+") do
		local code = FORMAT_MAP[formatName]

		if code then
			table.insert(codes, code)
		else
			print(`Unknown ANSI format requested: '{formatName}'`)
		end
	end

	if #codes == 0 then
		return content
	end

	local startCode = table.concat(codes, ";")

	return `\27[{startCode}m{content}\27[{RESET_CODE}m`
end
