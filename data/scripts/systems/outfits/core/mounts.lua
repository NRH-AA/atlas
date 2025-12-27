do
    local lastMountToggle = {}
    function Player.getLastMountToggle(self)
        return lastMountToggle[self:getId()] or 0
    end

    function Player.setLastMountToggle(self, time)
        lastMountToggle[self:getId()] = time
    end
end

do
    local wasMounted = {}
    function Player.getWasMounted(self)
        return wasMounted[self:getId()] or false
    end

    function Player.setWasMounted(self, mounted)
        wasMounted[self:getId()] = mounted or nil
    end
end

function Player.addMount(self, mountId)
    return self:setStorageValue(PlayerStorageKeys.mountsBase + mountId, 1)
end

function Player.addAllMounts(self)
	local mounts = Game.getMounts()
	for _, mount in ipairs(mounts) do
		self:addMount(mount.lookType)
	end
end

function Player.hasMount(self, mountId)
    local value = self:getStorageValue(PlayerStorageKeys.mountsBase + mountId)
    return value and value ~= -1
end

function Player.removeMount(self, mountId)
    local value = self:removeStorageValue(PlayerStorageKeys.mountsBase + mountId)
    if self:getCurrentMount() == mountId and self:isMounted() then
        self:dismount()
    end
    return value
end

function Player.removeAllMounts(self)
    local mounts = Game.getMounts()
    for _, mount in ipairs(mounts) do
        self:removeMount(mount.lookType)
    end

    if self:isMounted() then
        self:dismount()
    end
end

function Player.getCurrentMount(self)
    local value = self:getStorageValue(PlayerStorageKeys.currentMount)
    if not value or value == -1 then
        return nil
    end
    return value
end

function Player.setCurrentMount(self, mountId)
    if not mountId then
        return self:removeStorageValue(PlayerStorageKeys.currentMount)
    end
    
    if not self:getGroup():getAccess() and not self:hasMount(mountId) then
        return false
    end
    return self:setStorageValue(PlayerStorageKeys.currentMount, mountId)
end

function Player.getRandomizeMount(self)
    local randomizeMount = self:getStorageValue(PlayerStorageKeys.randomizeMount)
    return randomizeMount and randomizeMount ~= -1
end

function Player.setRandomizeMount(self, randomize)
    if randomize then
        return self:setStorageValue(PlayerStorageKeys.randomizeMount, 1)
    end
    return self:removeStorageValue(PlayerStorageKeys.randomizeMount)
end

function Player.canRideMount(self, mountId)
    if self:getGroup():getAccess() then
        return true
    end

    local mount = Game.getMountByLookType(mountId)
    if not mount then
        return false
    end

    if mount.premium and not self:isPremium() then
        return false
    end
    return self:hasMount(mount.lookType)
end

function Player.isMounted(self)
    return self:getOutfit().lookMount ~= 0
end

function Player.mount(self, mount)
    if not mount or not mount.lookType or not mount.speed then
        return false
    end

    local outfit = self:getDefaultOutfit()
    outfit.lookMount = mount.lookType
    self:setOutfit(outfit)
    self:changeSpeed(mount.speed)
    return true
end

function Player.dismount(self)
    local outfit = self:getDefaultOutfit()
    local lookMount = outfit.lookMount
    outfit.lookMount = 0
    self:setOutfit(outfit)

    local mount = Game.getMountByLookType(lookMount)
    if mount then
        self:changeSpeed(-mount.speed)
    end
end

local function getRandomMount(player)
    local mounts = Game.getMounts()

    local availableMounts = {}
    for _, mount in ipairs(mounts) do
        if player:hasMount(mount.lookType) then
            table.insert(availableMounts, mount.lookType)
        end
    end

    if #availableMounts == 0 then
        return nil
    end

    local idx = math.random(1, #availableMounts)
    return availableMounts[idx]
end

function Player.toggleMount(self, mounted)
    if not self:getGroup():getAccess() then
        local lastMountToggle = self:getLastMountToggle()
        if lastMountToggle and lastMountToggle > 0 then
            if os.mtime() - lastMountToggle < Outfits.ToggleMountCooldown and not self:getWasMounted() then
                return false
            end
        end
    end

    if mounted then
        if self:isMounted() then
            return false
        end

        local tile = self:getTile()
        if not self:getGroup():getAccess() and tile:hasFlag(TILESTATE_PROTECTIONZONE) then
            self:sendCancelMessage(RETURNVALUE_ACTIONNOTPERMITTEDINPROTECTIONZONE)
            return false
        end

        local lookMount = self:getCurrentMount()
        if not lookMount then
            self:sendOutfitWindow()
            return false
        end

        if self:getRandomizeMount() then
            lookMount = getRandomMount(self)
            if not lookMount then
                self:sendOutfitWindow()
                return false
            end
        end

        local currentMount = Game.getMountByLookType(lookMount)
        if not currentMount then
            return false
        end

        if not self:getGroup():getAccess() and currentMount.premium and not self:isPremium() then
            self:sendCancelMessage(RETURNVALUE_YOUNEEDPREMIUMACCOUNT)
            return false
        end

        if self:hasCondition(CONDITION_OUTFIT) then
            self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
            return false
        end

        self:mount(currentMount)
    else
        if not self:isMounted() then
            return false
        end

        self:dismount()
    end

    self:setOutfit(self:getDefaultOutfit())
    self:setLastMountToggle(os.mtime())
    return true
end

function Game.getMountIdByLookType(lookType)
    print("Warning: Game.getMountIdByLookType is deprecated. Mounts are now identified by client ID.")
    return lookType
end
