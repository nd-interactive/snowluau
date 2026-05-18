--[=[
	@class Option
	@__index Prototype
]=]
local Option = {}

Option.Interface = {}
Option.Prototype = {}

--[=[
	@method
	@within Option
]=]
function Option.Prototype.setName(self: OptionBuilder, name: string): OptionBuilder
	self.name = name

	return self
end

--[=[
	@method
	@within Option
]=]
function Option.Prototype.setDescription(self: OptionBuilder, description: string): OptionBuilder
	self.description = description

	return self
end

--[=[
	@method
	@within Option
]=]
function Option.Prototype.setType(self: OptionBuilder, type: OptionTypeString): OptionBuilder
	self.type = type

	return self
end

--[=[
	@method
	@within Option
]=]
function Option.Prototype.setDefaultValue(self: OptionBuilder, default: OptionType): OptionBuilder
	self.defaultValue = default

	return self
end

--[=[
	@method
	@within Option
]=]
function Option.Prototype.setValueName(self: OptionBuilder, valueName: string): OptionBuilder
	self.valueName = valueName

	return self
end

--[=[
	@method
	@within Option
]=]
function Option.Prototype.addAlias(self: OptionBuilder, alias: string): OptionBuilder
	table.insert(self.aliases, alias)

	return self
end

--[=[
	@method
	@within Option
]=]
function Option.Prototype.build(self: OptionBuilder): Option
	assert(typeof(self.name) == "string", `Expected name to be a string, got '{typeof(self.name)}'`)
	assert(
		table.find({ "string", "boolean", "number" }, typeof(self.type)) ~= nil,
		`Expected type to be either string, boolean or number, got '{typeof(self.type)}'`
	)

	return {
		name = self.name,
		type = self.type :: OptionTypeString,
		defaultValue = self.defaultValue,
		description = self.description or "No description set for this Option!",
		valueName = self.valueName,
		aliases = self.aliases,
	}
end

--[=[
	@within CLI
]=]
function Option.Interface.new(resource: {
	name: string?,
	description: string?,
	type: OptionTypeString?,
	defaultValue: OptionType?,
	valueName: string?,
	aliases: { string }?,
}?): OptionBuilder
	local self = (setmetatable({
		aliases = {},
	}, { __index = Option.Prototype }) :: any) :: OptionBuilder

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

		if resource.defaultValue then
			self:setDefaultValue(resource.defaultValue)
		end

		if resource.valueName then
			self:setValueName(resource.valueName)
		end

		if resource.aliases then
			for _, alias in resource.aliases do
				self:addAlias(alias)
			end
		end
	end

	return self
end

export type OptionBuilder = {
	name: string?,
	description: string?,
	type: OptionTypeString?,
	defaultValue: OptionType?,
	valueName: string?,
	aliases: { string },
} & typeof(Option.Prototype)

export type OptionTypeString = "string" | "boolean" | "number"
export type OptionType = string | boolean | number

export type Option = {
	name: string,
	type: OptionTypeString,
	defaultValue: OptionType?,
	description: string,
	valueName: string?,
	aliases: { string },
}

return Option.Interface
