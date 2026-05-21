local Writer = {}
Writer.__index = Writer

local TAB_WIDTH = 4

export type Writer = typeof(setmetatable(
	{} :: {
		content: string,
		indentation: number,
	},
	Writer
))

function Writer.new()
	local self = setmetatable({
		content = "",
		indentation = 0,
	}, Writer)

	return self
end

function Writer.indent(self: Writer)
	self.indentation += 1
end

function Writer.dedent(self: Writer)
	self.indentation -= 1
end

function Writer.append(self: Writer, str: string)
	self.content ..= str
end

function Writer.append_indent(self: Writer)
	self:append(string.rep(" ", self.indentation * TAB_WIDTH))
end

function Writer.append_line(self: Writer, str: string)
	self:append_indent()
	self:append(str)
	self:append("\n")
end

function Writer.append_lines(self: Writer, lines: { string })
	for _, line in lines do
		self:append_line(line)
	end
end

function Writer.finalize(self: Writer)
	return self.content
end

return Writer
