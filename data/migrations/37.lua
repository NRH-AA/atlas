local BATCH_SIZE = 10000

-- must match PlayerStorageKeys in storages.lua, change accordingly if modified
local CURRENT_MOUNT = 60000
local RANDOMIZE_MOUNT = 60001
local OUTFITS_BASE = 600000
local MOUNTS_BASE = 610000

function onUpdateDatabase()
    print("> Updating database to version 38 (revert outfits/mounts to storages)")

    local tx = DBTransaction()
    if not tx.begin() then
        return false
    end

    local rows = {}

    do
        local resultId = db.storeQuery("SELECT `player_id`, `outfit_id`, `addons` FROM `player_outfits`")
        if resultId then
            repeat
                local playerId = result.getNumber(resultId, "player_id")
                local outfitId = result.getNumber(resultId, "outfit_id")
                local addons = result.getNumber(resultId, "addons")

                local storageKey = OUTFITS_BASE + outfitId
                table.insert(rows, {
                    playerId = playerId,
                    key = storageKey,
                    value = addons
                })
            until not result.next(resultId)
            result.free(resultId)
        end
    end

    do
        local resultId = db.storeQuery("SELECT `player_id`, `mount_id` FROM `player_mounts`")
        if resultId then
            repeat
                local playerId = result.getNumber(resultId, "player_id")
                local mountId = result.getNumber(resultId, "mount_id")

                local storageKey = MOUNTS_BASE + mountId
                table.insert(rows, {
                    playerId = playerId,
                    key = storageKey,
                    value = 1
                })
            until not result.next(resultId)
            result.free(resultId)
        end
    end

    -- Migrate currentmount and randomizemount from players table
    do
        local resultId = db.storeQuery(
            "SELECT `id`, `currentmount`, `randomizemount` FROM `players` WHERE `currentmount` IS NOT NULL OR `randomizemount` IS NOT NULL")
        if resultId then
            repeat
                local playerId = result.getNumber(resultId, "id")
                local currentMount = result.getNumber(resultId, "currentmount")
                local randomizeMount = result.getNumber(resultId, "randomizemount")

                if currentMount > 0 then
                    table.insert(rows, {
                        playerId = playerId,
                        key = CURRENT_MOUNT,
                        value = currentMount
                    })
                end

                if randomizeMount > 0 then
                    table.insert(rows, {
                        playerId = playerId,
                        key = RANDOMIZE_MOUNT,
                        value = randomizeMount
                    })
                end
            until not result.next(resultId)
            result.free(resultId)
        end
    end

    if #rows > 0 then
        for start = 1, #rows, BATCH_SIZE do
            local end_ = math.min(start + BATCH_SIZE - 1, #rows)

            local query = DBInsert("INSERT INTO `player_storage` (`player_id`, `key`, `value`) VALUES ")
            for i = start, end_ do
                local row = rows[i]
                query:addRow(string.format("%d, %d, %d", row.playerId, row.key, row.value))
            end

            if not query:execute() then
                return false
            end
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

    return tx.commit()
end
