local function canWearOutfit(player, outfit)
	if not outfit.unlocked then
		return player:hasOutfit(outfit.lookType)
	end

	return not outfit.premium or player:isPremium()
end

local function getAvailableOutfits(player)
	local availableOutfits = {}

	local isAccessPlayer = player:getGroup():getAccess()
	if isAccessPlayer then
		-- add GM outfit for staff members
		local gamemaster = { name = "Gamemaster", lookType = 75, addons = 0 }
		table.insert(availableOutfits, gamemaster)
	end

	local outfits = Game.getOutfits(player:getSex())
	for _, outfit in ipairs(outfits) do
		if isAccessPlayer then
			table.insert(availableOutfits, { name = outfit.name, lookType = outfit.lookType, addons = 3 })
		elseif canWearOutfit(player, outfit) then
			local addons = player:getOutfitAddons(outfit.lookType)
			table.insert(availableOutfits, { name = outfit.name, lookType = outfit.lookType, addons = addons })
		end
	end

	return availableOutfits
end

local function getAvailableMounts(player)
	local mounts = Game.getMounts()

	local availableMounts = {}
	for _, mount in ipairs(mounts) do
		if player:hasMount(mount.id) then
			table.insert(availableMounts, { id = mount.id, name = mount.name })
		end
	end
	return availableMounts
end

local function getAvailableFamiliars(player)
	return {}
end

function Player.sendOutfitWindow(self)
	local availableOutfits = getAvailableOutfits(self)
	if #availableOutfits == 0 then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return
	end

	local currentOutfit = self:getDefaultOutfit()
	if currentOutfit.lookType == 0 then
		currentOutfit.lookType = availableOutfits[1].lookType
	end

	local mounted = self:isMounted()
	if self:getWasMounted() then
		mounted = currentOutfit.lookMount ~= 0
	end

	local availableMounts = getAvailableMounts(self)
	local availableFamiliars = getAvailableFamiliars(self)

	local msg = NetworkMessage()
	msg:addByte(0xC8)

	msg:addOutfit(currentOutfit)
	if currentOutfit.lookMount == 0 then
		msg:addByte(currentOutfit.lookMountHead)
		msg:addByte(currentOutfit.lookMountBody)
		msg:addByte(currentOutfit.lookMountLegs)
		msg:addByte(currentOutfit.lookMountFeet)
	end

	msg:addU16(0) -- current familiar looktype

	msg:addU16(#availableOutfits)
	for _, outfit in ipairs(availableOutfits) do
		msg:addU16(outfit.lookType)
		msg:addString(outfit.name)
		msg:addByte(outfit.addons)
		msg:addByte(0) -- mode: 0x00 - available, 0x01 store (requires U32 store offerId), 0x02 golden outfit tooltip (hardcoded)
	end

	msg:addU16(#availableMounts)
	for _, mount in ipairs(availableMounts) do
		msg:addU16(mount.id)
		msg:addString(mount.name)
		msg:addByte(0) -- mode: 0x00 - available, 0x01 store (requires U32 store offerId)
	end

	msg:addU16(#availableFamiliars)
	for _, familiar in ipairs(availableFamiliars) do
		msg:addU16(familiar.lookType)
		msg:addString(familiar.name)
		msg:addByte(0) -- mode: 0x00 - available, 0x01 store (requires U32 store offerId)
	end

	msg:addByte(0x00) -- try outfit mode (?)
	msg:addBool(mounted)
	msg:addBool(self:getRandomizeMount())
	msg:sendToPlayer(self)
end

function Player.sendPodiumWindow(self, item)
    local podium = item:getPodium()
    if podium == nil then
        return
    end

    local tile = item:getTile()
    if tile == nil then
        return
    end

	local it = ItemType(item:getId())
	if not it then
		return
	end

	local availableOutfits = getAvailableOutfits(self)
    if #availableOutfits == 0 then
        self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
        return
    end

    local stackpos = tile:getThingIndex(item)

    local podiumOutfit = podium:getOutfit()
    local playerOutfit = self:getDefaultOutfit()
    local isEmpty = podiumOutfit.lookType == 0 and podiumOutfit.lookMount == 0

    if podiumOutfit.lookType == 0 then
        -- copy player outfit
        podiumOutfit.lookType = playerOutfit.lookType
        podiumOutfit.lookHead = playerOutfit.lookHead
        podiumOutfit.lookBody = playerOutfit.lookBody
        podiumOutfit.lookLegs = playerOutfit.lookLegs
        podiumOutfit.lookFeet = playerOutfit.lookFeet
        podiumOutfit.lookAddons = playerOutfit.lookAddons
    end

    if podiumOutfit.lookMount == 0 then
        -- copy player mount
        podiumOutfit.lookMount = playerOutfit.lookMount
        podiumOutfit.lookMountHead = playerOutfit.lookMountHead
        podiumOutfit.lookMountBody = playerOutfit.lookMountBody
        podiumOutfit.lookMountLegs = playerOutfit.lookMountLegs
        podiumOutfit.lookMountFeet = playerOutfit.lookMountFeet
    end

	if not self:canWearOutfit(podiumOutfit.lookType) then
		-- select first outfit available when the one from podium is not unlocked
		podiumOutfit.lookType = availableOutfits[1].lookType
	end

	local availableMounts = getAvailableMounts(self)

	local msg = NetworkMessage()
	msg:addByte(0xD8)

	-- current outfit
	msg:addOutfit(podiumOutfit)

	-- current mount
	msg:addU16(podiumOutfit.lookMount)
	msg:addByte(podiumOutfit.lookMountHead)
	msg:addByte(podiumOutfit.lookMountBody)
	msg:addByte(podiumOutfit.lookMountLegs)
	msg:addByte(podiumOutfit.lookMountFeet)

	-- current familiar (not used in podium)
	msg:addU16(0)

	-- available outfits
	msg:addU16(#availableOutfits)
	for _, outfit in ipairs(availableOutfits) do
		msg:addU16(outfit.lookType)
		msg:addString(outfit.name)
		msg:addByte(outfit.addons)
		msg:addByte(0) -- mode: 0x00 - available, 0x01 store (requires U32 store offerId), 0x02 golden outfit tooltip (hardcoded)
	end

	-- available mounts
	msg:addU16(#availableMounts)
	for _, mount in ipairs(availableMounts) do
		msg:addU16(mount.id)
		msg:addString(mount.name)
		msg:addByte(0) -- mode: 0x00 - available, 0x01 store (requires U32 store offerId)
	end

	-- available familiars (not used in podium)
	msg:addU16(0)

	msg:addByte(0x05) -- "set outfit" window mode (5 = podium)
	msg:addBool((isEmpty and playerOutfit.lookType ~= 0) or podium:hasFlag(PODIUM_SHOW_MOUNT)) -- "mount" checkbox
	msg:addU16(0) -- unknown
	msg:addPosition(item:getPosition())
	msg:addU16(it:getClientId())
	msg:addByte(stackpos)

	msg:addBool(podium:hasFlag(PODIUM_SHOW_PLATFORM)) -- is platform visible
	msg:addBool(true) -- "outfit" checkbox, ignored by the client
	msg:addByte(podium:getDirection())
	msg:sendToPlayer(self)
end

function Player.sendEditPodium(self, item) return self:sendPodiumWindow(item) end
