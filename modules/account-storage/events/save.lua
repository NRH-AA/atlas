local event = Event()

event.onGameSave = function()
	local success = Game.saveAccountsStorage()
	if not success then
		print("Failed to save account-level storage values.")
	end
end

event:register()
