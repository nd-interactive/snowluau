local Fs = require("@std/fs")
local Process = require("@lute/process")
local System = require("@lute/system")

local EXE_NAME = "snowluau"
local RELEASE_DIR = "./release"
local CLI_PATH = "./cli/init.luau"

local function build_executable()
	local is_windows = System.os == "Windows_NT"
	local exe_name = `{EXE_NAME}{is_windows and ".exe" or ""}`
	local exe_path = `{RELEASE_DIR}/{exe_name}`

	local run_result = Process.run({
		"lute",
		"compile",
		CLI_PATH,
		"--output",
		exe_path,
	})

	assert(run_result.ok, run_result.stderr)

	local archive_result: Process.ProcessResult
	if is_windows then
		archive_result = Process.run({
			"tar",
			"-czvf",
			`{RELEASE_DIR}/blink.tar.gz`,
			"-C",
			RELEASE_DIR,
			exe_name,
		})
	else
		archive_result = Process.run({
			"tar",
			"-cJvf",
			`{RELEASE_DIR}/blink.tar.xz`,
			"-C",
			RELEASE_DIR,
			exe_name,
		})
	end

	assert(archive_result.ok, archive_result.stderr)

	Fs.remove(exe_path)
	print(`Built executable to {RELEASE_DIR}/blink.tar.*`)
end

do
	if Fs.exists(RELEASE_DIR) then
		Fs.removeDirectory(RELEASE_DIR, { recursive = true })
	end
	Fs.createDirectory(RELEASE_DIR)
end

local start = os.clock()
build_executable()

local elapsed = (os.clock() - start)
print(string.format("Finished build in %.2f seconds", elapsed))