local function copyDeep(dictionary: any): any
	local new = table.clone(dictionary)

	for key, value in dictionary do
		if type(value) == "table" then
			new[key] = copyDeep(value)
		end
	end

	return new
end

return copyDeep
