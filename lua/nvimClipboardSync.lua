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
local M = {}

M.config = {
	TMP_DIR = "/tmp/com.sebastianmusic.nvimclipboardsync/",
	debug = true,
}

--
--    _____ ______________  ______
--   / ___// ____/_  __/ / / / __ \
--   \__ \/ __/   / / / / / / /_/ /
--  ___/ / /___  / / / /_/ / ____/
-- /____/_____/ /_/  \____/_/
--
--

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	local uv = vim.uv

	local function debugPrint(message, isError)
		if type(M.config.debug) ~= "boolean" then
			vim.schedule(function()
				vim.api.nvim_err_write(
					"debug parameter in nvimClipboardSync has invalid value in configuration, it must be either 'true' or 'false'"
				)
			end)
			return
		elseif M.config.debug == true and isError == true then
			vim.schedule(function()
				vim.api.nvim_err_write(message)
			end)
		elseif M.config.debug == true and isError == false then
			print(message)
		end
	end

	local function directoryExists(path)
		return vim.fn.isdirectory(path) == 1
	end

	-- Check if tmp directory exits
	if directoryExists(M.config.TMP_DIR) ~= true then
		if M.config.debug == true then
			debugPrint("Error TMP directory does not exist, make sure daemon is running", true)
		end
	end

	local Pipe = uv.new_pipe(false)

	Pipe:connect(M.config.TMP_DIR .. "listeningPipe", function(err)
		if err then
			debugPrint("Failed to connect: " .. err, true)
		else
			debugPrint("Connection succesfull", false)
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
		callback = function()
			debugPrint("Callback triggered", false)
			vim.schedule(function()
				local register = vim.fn.getreg('"0')
				local sec, usec = vim.loop.gettimeofday()
				local Timestamp = sec * 1000000 + usec -- Ensure it remains an integer

				local packet = vim.fn.json_encode({ REGISTER = register, TIMESTAMP = Timestamp })
				debugPrint(packet, false)

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
	Pipe:read_start(function(err, chunk)
		if err then
			debugPrint("Read error: " .. err, true)
		-- handle read error
		-- 16 bit length prefixed message in bytes
		elseif chunk then
			debugPrint(chunk, false)
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
end

return M
