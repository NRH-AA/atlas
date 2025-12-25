function onUpdateDatabase()
	print("> Updating database to version 38 (revert outfits/mounts to storages)")

	local rows = {}

	local resultId = db.storeQuery("SELECT `player_id`, `outfit_id`, `addons` FROM `player_outfits`")
	if resultId then
		repeat
			local playerId = result.getNumber(resultId, "player_id")
			local outfitId = result.getNumber(resultId, "outfit_id")
			local addons = result.getNumber(resultId, "addons")

			local storageKey = PlayerStorageKeys.outfitsBase + outfitId
			table.insert(rows, {playerId = playerId, key = storageKey, value = addons})
		until not result.next(resultId)
		result.free(resultId)
	end

	local resultId = db.storeQuery("SELECT `player_id`, `mount_id` FROM `player_mounts`")
	if resultId then
		repeat
			local playerId = result.getNumber(resultId, "player_id")
			local mountId = result.getNumber(resultId, "mount_id")

			local storageKey = PlayerStorageKeys.mountsBase + mountId
			table.insert(rows, {playerId = playerId, key = storageKey, value = 1})
		until not result.next(resultId)
		result.free(resultId)
	end

	if #rows > 0 then
		local query = "INSERT INTO `player_storage` (`player_id`, `key`, `value`) VALUES "
		for i, row in ipairs(rows) do
			query = query .. string.format("(%d, %d, %d)", row.playerId, row.key, row.value)
			if i < #rows then
				query = query .. ","
			end
		end
		if not db.query(query) then
			return false
		end
	end

	if not db.query("DROP TABLE IF EXISTS `player_outfits`") then
		return false
	end
	if not db.query("DROP TABLE IF EXISTS `player_mounts`") then
		return false
	end
	if not db.query("ALTER TABLE `players` DROP COLUMN `currentmount`, DROP COLUMN `randomizemount`") then
		return false
	end

	return true
end
