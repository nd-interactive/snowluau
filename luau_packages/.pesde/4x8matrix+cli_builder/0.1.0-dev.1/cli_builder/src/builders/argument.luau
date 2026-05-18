--[=[
	@class Argument
	@__index Prototype
]=]
local Argument = {}

Argument.Interface = {}
Argument.Prototype = {}

--[=[
	@method
	@within Argument
]=]
function Argument.Prototype.setName(self: ArgumentBuilder, name: string): ArgumentBuilder
	self.name = name

	return self
end

--[=[
	@method
	@within Argument
]=]
function Argument.Prototype.setDescription(self: ArgumentBuilder, description: string): ArgumentBuilder
	self.description = description

	return self
end

--[=[
	@method
	@within Argument
]=]
function Argument.Prototype.setType(self: ArgumentBuilder, type: ArgumentTypeString): ArgumentBuilder
	self.type = type

	return self
end

--[=[
	@method
	@within Argument
]=]
function Argument.Prototype.setRequired(self: ArgumentBuilder, required: boolean): ArgumentBuilder
	self.required = required

	return self
end

--[=[
	@method
	@within Argument
]=]
function Argument.Prototype.build(self: ArgumentBuilder): Argument
	assert(typeof(self.name) == "string", `Expected name to be a string, got '{typeof(self.name)}'`)
	assert(
		table.find({ "string", "number" }, typeof(self.type)) ~= nil,
		`Expected type to be either string or number, got '{typeof(self.type)}'`
	)

	return {
		name = self.name,
		type = self.type :: ArgumentTypeString,
		description = self.description or "No description set for this Argument!",
		required = self.required or false,
	}
end

--[=[
	@within CLI
]=]
function Argument.Interface.new(resource: {
	name: string?,
	description: string?,
	type: ArgumentTypeString?,
	required: boolean,
}?): ArgumentBuilder
	local self = (setmetatable({}, { __index = Argument.Prototype }) :: any) :: ArgumentBuilder

	if resource then
		if resource.name then
			self:setName(resource.name)
		end

		if resource.description then
			self:setDescription(resource.description)
		end

		if resource.type then
			self:setType(resource.type)
		end

		if resource.required then
			self:setRequired(resource.required)
		end
	end

	return self
end

export type ArgumentBuilder = {
	name: string?,
	description: string?,
	type: ArgumentTypeString?,
	required: boolean?,
} & typeof(Argument.Prototype)

export type ArgumentTypeString = "string" | "number"
export type Argument = {
	name: string,
	type: ArgumentTypeString,
	required: boolean,
	description: string,
}

return Argument.Interface
