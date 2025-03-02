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
local M = {}

M.config = {
	TMP_DIR = "/tmp/com.sebastianmusic.nvimclipboardsync/",
	debug = 1,
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

	local function directoryExists(path)
		return vim.fn.isdirectory(path) == 1
	end

	-- Check if tmp directory exits
	if directoryExists(M.config.TMP_DIR) ~= true then
		if M.config.debug == 1 then
			vim.api.nvim_err_write("Error tmp directory does not exists, make sure daemon is running")
		end
	end

	local Pipe = uv.new_pipe(false)

	Pipe:connect(M.config.TMP_DIR .. "listeningPipe", function(err)
		if err then
			if M.config.debug == 1 then
				print("failed to connect: ", err)
			end
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
end

return M
