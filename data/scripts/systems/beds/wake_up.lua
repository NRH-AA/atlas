local bedLogin = CreatureEvent("BedLogin")

local function findBedOnTile(tile)
    if not tile then
        return nil
    end
    local items = tile:getItems()
    if not items then
        return nil
    end
    for _, item in ipairs(items) do
        if Bed.isBed(item:getId()) then
            return item
        end
    end
    return nil
end

local function findRelevantBed(player)
	local pos = player:getPosition()
	local tile = Tile(pos)
	if tile then
		local bed = findBedOnTile(tile)
		if bed then
			return bed, Bed.getPartnerBed(bed)
		end
	end

	local directions = {DIRECTION_NORTH, DIRECTION_EAST, DIRECTION_SOUTH, DIRECTION_WEST}
	for _, dir in ipairs(directions) do
		local checkPos = Position(pos)
		checkPos:getNextPosition(dir)
		local checkTile = Tile(checkPos)
		if checkTile then
			local candidate = findBedOnTile(checkTile)
			if candidate then
				local partnerDir = Bed.getPartnerDir(candidate)
				if partnerDir then
					local candidatePos = Position(candidate:getPosition())
					candidatePos:getNextPosition(partnerDir)
					if candidatePos == pos then
						return candidate, Bed.getPartnerBed(candidate)
					end
				end
			end
		end
	end

	return nil, nil
end

local function applyRegeneration(player, sleptSeconds)
    if sleptSeconds <= 0 then
        return
    end

    local regenTicks = math.floor(sleptSeconds / 30) * Bed.HEALTH_MANA_PER_30_SEC
    if regenTicks > 0 then
        player:addHealth(regenTicks)
        player:addMana(regenTicks)
    end

    local soulTicks = math.floor(sleptSeconds / (15 * 60)) * Bed.SOUL_PER_15_MIN
    if soulTicks > 0 then
        player:addSoul(soulTicks)
    end
end

local function clearSleeper(bed)
    bed:removeCustomAttribute(ITEM_ATTRIBUTE_DESCRIPTION)

    local targetId = bed:getAttribute("transformToFree")
    if type(targetId) == "number" and targetId > 0 then
        bed:transform(targetId)
    end
end

function bedLogin.onLogin(player)
	local bed, partner = findRelevantBed(player)
	if not bed then
		return true
	end

	local lastLogout = player:getLastLogout()
	local sleptSeconds = 0
	if lastLogout > 0 then
		sleptSeconds = math.max(0, os.time() - lastLogout)
	end

	applyRegeneration(player, sleptSeconds)
	player:addHealth(0)

	clearSleeper(bed)
	if partner then
		clearSleeper(partner)
	end

	return true
end

bedLogin:register()
