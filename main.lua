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

local function readTheBuffer(table)
	local length = 0
	for i, value in ipairs(table) do
		length = length + value
	end
	return length
end

-- append inkommnede data til readbuffer
-- når du har lengde forstett
-- hvis du lesr mer inn i readbuffer enn lengda oprett nytt table, legg til resternede informasjon.
-- sett master bufferent til ponteren til den nye bufferen
-- hvis bufferen er helt tom lag et nytt able og sett master bufferen til dene tomme
--

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
			Timestamp = vim.fn.localtime()

			local packet = vim.fn.json_encode({ REGISTER = register, TIMESTAMP = Timestamp })
			print(packet)

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
--
-- 		local readBufferLength = string.len(table.concat(readBuffer))
-- 		if readBufferLength >= 16 then
-- 			table.insert(readBuffer, chunk)
-- 			local messageLength = string.sub(table.concat(readBuffer), 1, 16)
-- 			-- If message is exactly the same size as the buffer
-- 			readBufferLength = string.len(table.concat(readBuffer))
-- 			if messageLength == readBufferLength then
-- 				local message = string.sub(table.concat(readBuffer), 17, tonumber(messageLength))
-- 				local json = vim.json.decode(message)
-- 				if json["timestamp"] > Timestamp then
-- 				end
-- 				-- else discard output
--
-- 				-- Create new table and assign it to the read buffer
-- 				local newTable = {}
-- 				readBuffer = newTable
--
-- 			-- if the read buffer is larger than the current message we need to handle the overflow
-- 			elseif messageLength < readBufferLength then
-- 				local readBufferString = table.concat(readBuffer)
-- 				local firstMessage = string.sub(readBufferString, 1, tonumber(messageLength))
-- 				local secondMessage = string.sub(readBufferString, messageLength + 1, readBufferLength)
--
-- 				local json = vim.json.decode(firstMessage)
-- 				if json["timestamp"] > Timestamp then
-- 					vim.schedule(function()
-- 						vim.fn.setreg('"0', json["content"])
-- 					end)
-- 					-- else just discard output and create new table
-- 					-- Create new table and assign it to the read buffer
-- 					local newTable = {}
-- 					table.insert(newTable, secondMessage)
-- 					readBuffer = newTable
-- 				elseif messageLength > readBufferLength then
-- 				end
-- 			end
--
-- 		-- handle data
-- 		else
-- 			-- handle disconnect
-- 		end
-- 	end
-- end)
-- --    ________    _________    _   __   __  ______
-- --   / ____/ /   / ____/   |  / | / /  / / / / __ \
-- --  / /   / /   / __/ / /| | /  |/ /  / / / / /_/ /
-- -- / /___/ /___/ /___/ ___ |/ /|  /  / /_/ / ____/
-- \____/_____/_____/_/  |_/_/ |_/   \____/_/
--
-- Remove named pipe from tmp diretory
-- vim.api.nvim_create_autocmd("VimLeavePre", {
-- 	group = clipboardGroup,
-- 	callback = function()
-- 		print("leaving neovim cleaning up")
--
-- 		if type(Pipe) == "uv_pipe_t" then
-- 			Pipe:close()
-- 			local result = vim.system({ "rm", TMP_DIR .. PipeName })
-- 		else
-- 			print("pipe was not type uv_pipe_t it was instead: ", type(Pipe))
-- 		end
-- 	end,
-- })
