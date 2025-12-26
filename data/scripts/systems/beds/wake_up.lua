local event = CreatureEvent("BedLogin")

local function findHeadboardOnTile(tile)
    if not tile then
        return nil
    end

    local items = tile:getItems()
    if not items then
        return nil
    end

    for _, item in ipairs(items) do
		local bed = item:getBed()
        if bed ~= nil and bed:isHeadboard() then
            return bed
        end
    end

    return nil
end

local function findRelevantBed(player)
	local pos = player:getPosition()
	local tile = Tile(pos)
	if tile then
		local headboard = findHeadboardOnTile(tile)
		if headboard then
			local footboard = headboard:getPartnerBed()
			if footboard then
				return headboard, footboard
			end
		end
	end

	local directions = {DIRECTION_NORTH, DIRECTION_EAST, DIRECTION_SOUTH, DIRECTION_WEST}
	for _, dir in ipairs(directions) do
		local checkPos = Position(pos)
		checkPos:getNextPosition(dir)
		local tile = Tile(checkPos)
		if tile then
			local headboard = findHeadboardOnTile(tile)
			if headboard then
				local footboard = headboard:getPartnerBed()
				if footboard then
					return headboard, footboard
				end
			end
		end
	end

	return nil, nil
end

local function regeneratePlayer(player, sleptSeconds)
	if sleptSeconds <= 0 then
		return
	end

	local regenWindow = math.min(sleptSeconds, Beds.HealthManaMaxSeconds)
	local regenTicks = math.floor(regenWindow / Beds.HealthManaTickSeconds) * Beds.HealthManaPerTick
	if regenTicks > 0 then
		player:addHealth(regenTicks)
		player:addMana(regenTicks)
	end

	local soulTicks = math.floor(sleptSeconds / Beds.SoulTickSeconds) * Beds.SoulPerTick
	if soulTicks > 0 then
		player:addSoul(soulTicks)
	end
end

function event.onLogin(player)
	local headboard, footboard = findRelevantBed(player)
	if not headboard or not footboard or not headboard:getSleeper() ~= player:getId() then
		return true
	end

	local lastLogout = player:getLastLogout()
	local sleptSeconds = 0
	if lastLogout > 0 then
		sleptSeconds = math.max(0, os.time() - lastLogout)
	end

	regeneratePlayer(player, sleptSeconds)

	headboard:removeSleeper(player)
	footboard:removeSleeper(player)

	return true
end

event:register()
