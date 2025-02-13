--    _____ ______________  ______
--   / ___// ____/_  __/ / / / __ \
--   \__ \/ __/   / / / / / / /_/ /
--  ___/ / /___  / / / /_/ / ____/
-- /____/_____/ /_/  \____/_/
--
--
local clipboardGroup = vim.api.nvim_create_augroup("clipboardGroup", { clear = true })
local uv = vim.uv
local TMP_DIR = "/tmp/com.sebastianmusic.nvimclipboardsync"
local pipeNameLength = 40

local function directoryExists(path)
	return vim.fn.isdirectory(path) == 1
end

-- Check if tmp directory exits
if directoryExists(TMP_DIR) ~= true then
	vim.api.nvim_err_write("Error tmp directory does not exists, make sure daemon is running")
	os.exit(1)
end

-- function to generate random string
local function randomString(length)
	local result = {}
	for _ = 1, length do
		table.insert(result, string.char(math.random(97, 122)))
	end
	return table.concat(result)
end

local pipeName = randomString(pipeNameLength)
local establishingPipe = true
while establishingPipe do
	if vim.fn.filereadable(TMP_DIR .. pipeName) == 0 then
		pipeName = randomString(pipeNameLength)
	else
		vim.system({ "mkfifo", TMP_DIR .. pipeName }, { text = true }, function(result)
			if result.code == 0 then
				print("pipe created succsefully")
			else
				print("error: ", result.stderr)
			end
		end)
		Pipe = uv.new_pipe(false)
		Pipe:bind(TMP_DIR .. pipeName)
		establishingPipe = false
		break
	end
end

Pipe:read_start(function(err, chunk)
	if err then
		print("Read error:", err)
	-- handle read error
	elseif chunk then
		-- TODO: Deconstruct lua table into data and timestamp and discard if timestamp is too old

		vim.schedule(function()
			vim.fn.setreg('"0', chunk)
		end)
	-- handle data
	else
		-- handle disconnect
	end
end)

-- check if uuid exists in tmp directory
-- if it does then try again
-- create a pipe with a name of the uuid
-- store it in some variable

--    ____  _   __   __  _____    _   ____ __
--   / __ \/ | / /   \ \/ /   |  / | / / //_/
--  / / / /  |/ /     \  / /| | /  |/ / ,<
-- / /_/ / /|  /      / / ___ |/ /|  / /| |
-- \____/_/ |_/      /_/_/  |_/_/ |_/_/ |_|

vim.api.nvim_create_autocmd("TextYankPost", {
	group = clipboardGroup,
	callback = function()
		print("callback triggered")
		vim.schedule(function()
			local register = vim.fn.getreg('"0')
			local timestamp = vim.fn.localtime()

			local packet = vim.fn.json_encode({ register = register, timestamp = timestamp })

			Pipe:write(packet .. "\n")
		end)
	end,
})
-- get current time
-- save time on yank
-- Create Json structure with time and clipboard contents
-- send to daemon
--    ____  _   __   ____  _________    ____
--   / __ \/ | / /  / __ \/ ____/   |  / __ \
--  / / / /  |/ /  / /_/ / __/ / /| | / / / /
-- / /_/ / /|  /  / _, _/ /___/ ___ |/ /_/ /
-- \____/_/ |_/  /_/ |_/_____/_/  |_/_____/

-- check if timestamp
-- check if the contents are newer thank last yank
-- if they are newer set the clipboard register to the contents if not discard them
--
--
--    ________    _________    _   __   __  ______
--   / ____/ /   / ____/   |  / | / /  / / / / __ \
--  / /   / /   / __/ / /| | /  |/ /  / / / / /_/ /
-- / /___/ /___/ /___/ ___ |/ /|  /  / /_/ / ____/
-- \____/_____/_____/_/  |_/_/ |_/   \____/_/
--
-- Remove named pipe from tmp diretory
