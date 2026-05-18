export type TableLike = { [any]: any }

return function<T0, T1>(a: TableLike, b: TableLike): T0 & T1
	local newTable = {}

	for _, value in a do
		table.insert(newTable, value)
	end

	for _, value in b do
		table.insert(newTable, value)
	end

	return newTable :: any
end
