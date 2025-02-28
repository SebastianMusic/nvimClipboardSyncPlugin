-- TODO: Timer precission is not precise enough leading to yanks being discarded if copied in quick succession
--    ________    ____  ____  ___    __
--   / ____/ /   / __ \/ __ )/   |  / /
--  / / __/ /   / / / / __  / /| | / /
-- / /_/ / /___/ /_/ / /_/ / ___ |/ /___
-- \____/_____/\____/_____/_/  |_/_____/
--
--  _    _____    ____  _______    ____  __    ___________
-- | |  / /   |  / __ \/  _/   |  / __ )/ /   / ____/ ___/
-- | | / / /| | / /_/ // // /| | / __  / /   / __/  \__ \
-- | |/ / ___ |/ _, _// // ___ |/ /_/ / /___/ /___ ___/ /
-- |___/_/  |_/_/ |_/___/_/  |_/_____/_____/_____//____/
--
Timestamp = 0
Pipename = ""
Pipe = {}
TMP_DIR = "/tmp/com.sebastianmusic.nvimclipboardsync/"

--
--    _____ ______________  ______
--   / ___// ____/_  __/ / / / __ \
--   \__ \/ __/   / / / / / / /_/ /
--  ___/ / /___  / / / /_/ / ____/
-- /____/_____/ /_/  \____/_/
--
--
local clipboardGroup = vim.api.nvim_create_augroup("clipboardGroup", { clear = true })
local uv = vim.uv

local function directoryExists(path)
	return vim.fn.isdirectory(path) == 1
end

-- Check if tmp directory exits
if directoryExists(TMP_DIR) ~= true then
	vim.api.nvim_err_write("Error tmp directory does not exists, make sure daemon is running")
	os.exit(1)
end

local Pipe = uv.new_pipe(false)

Pipe:connect(TMP_DIR .. "listeningPipe", function(err)
	if err then
		print("failed to connect: ", err)
	else
		print("connection succesfull")
	end
end)

--    ____  _   __   __  _____    _   ____ __
--   / __ \/ | / /   \ \/ /   |  / | / / //_/
--  / / / /  |/ /     \  / /| | /  |/ / ,<
-- / /_/ / /|  /      / / ___ |/ /|  / /| |
-- \____/_/ |_/      /_/_/  |_/_/ |_/_/ |_|

-- get current time
-- save time on yank
-- Create Json structure with time and clipboard contents
-- send to daemon
vim.api.nvim_create_autocmd("TextYankPost", {
	group = clipboardGroup,
	callback = function()
		print("callback triggered")
		vim.schedule(function()
			local register = vim.fn.getreg('"0')
			Timestamp = vim.fn.localtime()

			local packet = vim.fn.json_encode({ REGISTER = register, TIMESTAMP = Timestamp })
			print(packet)

			Pipe:write(packet .. "\n")
		end)
	end,
})
--    ____  _   __   ____  _________    ____
--   / __ \/ | / /  / __ \/ ____/   |  / __ \
--  / / / /  |/ /  / /_/ / __/ / /| | / / / /
-- / /_/ / /|  /  / _, _/ /___/ ___ |/ /_/ /
-- \____/_/ |_/  /_/ |_/_____/_/  |_/_____/

-- check if timestamp
-- check if the contents are newer thank last yank
-- if they are newer set the clipboard register to the contents if not discard them
--
local readBuffer = {}
Pipe:read_start(function(err, chunk)
	if err then
		print("Read error:", err)
		-- handle read error
		-- 16 bit length prefixed message in bytes
	elseif chunk then
		print(chunk)
		local json = vim.json.decode(chunk)

		vim.schedule(function()
			vim.fn.setreg('"0', json["REGISTER"])
		end)
	end
end)
--     ________    _________    _   __   __  ______
--    / ____/ /   / ____/   |  / | / /  / / / / __ \
--   / /   / /   / __/ / /| | /  |/ /  / / / / /_/ /
--  / /___/ /___/ /___/ ___ |/ /|  /  / /_/ / ____/
--  \____/_____/_____/_/  |_/_/ |_/   \____/_/
--
-- Close pipe automaticly on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		Pipe:read_stop()
		Pipe:close()
	end,
})
