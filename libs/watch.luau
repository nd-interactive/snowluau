local Fs = require("@std/fs")
local Path = require("@std/path")
local Task = require("@std/task")

type Snapshot = { [string]: Fs.FileMetadata }
type Change = {
	created: boolean,
	removed: boolean,
	changed: boolean,
}
type OnChange = (path: Path.Path, change: Change) -> ()

local POLL_INTERVAL = 0.1
local CREATED: Change = {
	created = true,
	removed = false,
	changed = false,
}
local REMOVED: Change = {
	created = false,
	removed = true,
	changed = false,
}
local CHANGED: Change = {
	created = false,
	removed = false,
	changed = true,
}

local Watch = {}

local function createSnapshot(directory: Path.Path): Snapshot
	local snapshot: Snapshot = {}
	local walker = Fs.walk(directory, { recursive = true })

	local path = walker() -- root 제외

	while path do
		local succeeded, metadata = pcall(Fs.metadata, path)
		if succeeded then
			snapshot[Path.format(path)] = metadata
		end

		path = walker()
	end

	return snapshot
end

local function compareSnapshots(previous: Snapshot, current: Snapshot, onChange: OnChange)
	for path, state in current do
		local pathObject = Path.resolve(path)
		local oldState = previous[path]

		if not oldState then
			onChange(pathObject, CREATED)
		elseif state.type ~= oldState.type then
			onChange(pathObject, CHANGED)
		elseif
			state.type ~= "dir"
			and (state.size ~= oldState.size or state.modified:toNanoseconds() ~= oldState.modified:toNanoseconds())
		then
			onChange(pathObject, CHANGED)
		end
	end

	for path in previous do
		if not current[path] then
			local pathObject = Path.resolve(path)
			onChange(pathObject, REMOVED)
		end
	end
end

function Watch.watch(root: Path.Path, onChange: OnChange)
	local previous = createSnapshot(root)

	while Task.wait(POLL_INTERVAL) do
		local current = createSnapshot(root)

		compareSnapshots(previous, current, onChange)
		previous = current
	end
end

return Watch
