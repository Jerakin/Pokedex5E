local M = {}

M.SNAPSHOT = nil

local conflictId = nil
local use_saved_games = sys.get_config("gpgs.use_saved_games") == "1"
local not_saved_data = nil


local function callback(self, message_id, message)
	if message_id == gpgs.MSG_SILENT_SIGN_IN then
		if message.status == gpgs.STATUS_SUCCESS then
			open_snapshot()
		else
			gpgs.login()
		end
	elseif message_id == gpgs.MSG_SIGN_IN then
		if message.status == gpgs.STATUS_SUCCESS then
			open_snapshot()
		else
			print("can't login")
		end
	elseif message_id == gpgs.MSG_LOAD_SNAPSHOT then
		print("MSG_LOAD_SNAPSHOT")
		if message.status == gpgs.STATUS_SUCCESS then
			print("STATUS_SUCCESS")
			local bytes, error_message = gpgs.snapshot_get_data()
			if not bytes then
				print("snapshot_get_data ERROR:", error_message)
			else
				M.SNAPSHOT = bytes
				print(highscore)
				print("snapshot_get_data", bytes)
				-- if we have the not saved data, let's try to save it
				if self.not_saved_data then
					save_data(self.non_saved_data)
					self.not_saved_data = nil
				end
			end
		end
	end
end

function M.init()
	gpgs.set_callback(callback)
	gpgs.silent_login()
end

function M.logout()
	if gpgs then
		gpgs.logout()
	end
end

function M.get_data()
	if gpgs then
		local bytes, error_message = gpgs.snapshot_get_data()
		if not bytes then
			print("snapshot_get_data ERROR:", error_message)
		else
			print("snapshot_get_data",bytes)
		end
	end
end

function M.is_logged_in()
	if gpgs then
		gpgs.is_logged_in()
	end
end

function M.attempt_sign_in()
	if gpgs then
		gpgs.login()
	end
end

function M.open_data(user)
	gpgs.snapshot_open(user, true, gpgs.RESOLUTION_POLICY_MANUAL)
end

local function save_data(data)
	local success, error_message = gpgs.snapshot_set_data(data)
	if success then
		print("COMMIT IS SUCCESSFULL")
		gpgs.snapshot_commit_and_close() --would be better to set data for the automatic conflict solver
	else
		print("snapshot_set_data ERROR:", error_message)
	end
end

function M.set_data(data)
	if gpgs then
		if gpgs.snapshot_is_opened() then
			print("snapshot is opened and trying to save highscore")
			save_data(highscore)
		else
			print("snapshot isn't opened")
			-- your snapshot has already closed (or wasn't open)
			-- let's save your data locally in `self` and try to save it when the snapshot will be opened again
			not_saved_data = data
			open_snapshot()
		end
		
		local success, error_message = gpgs.snapshot_set_data(data)
		if not success then
			print("snapshot_set_data ERROR:", error_message)
		end
	end
end


function M.save_data(data)
	if gpgs then
		gpgs.snapshot_commit_and_close()
	end
end


return M