function Player.addMount(self, mountId)
    return self:setStorageValue(PlayerStorageKeys.mountsBase + mountId, 1)
end

function Player.hasMount(self, mountId)
    return self:hasStorageValue(PlayerStorageKeys.mountsBase + mountId)
end

function Player.removeMount(self, mountId)
    local result = self:removeStorageValue(PlayerStorageKeys.mountsBase + mountId)
    if self:getCurrentMount() == mountId and self:isMounted() then
        self:dismount()
    end
    return result
end

function Player.getCurrentMount(self)
    local lookType = self:getOutfit().lookMount
    if lookType == 0 then
        return nil
    end
    return lookType
end

function Player.getRandomizeMount(self)
    return self:hasStorageValue(PlayerStorageKeys.randomizeMount)
end

function Player.setRandomizeMount(self, randomize)
    if not randomize then
        self:removeStorageValue(PlayerStorageKeys.randomizeMount)
    else
        self:setStorageValue(PlayerStorageKeys.randomizeMount, 1)
    end
end

local lastMountToggle = {}
function Player.getLastMountToggle(self)
    return lastMountToggle[self:getId()] or 0
end
function Player.setLastMountToggle(self, time)
    lastMountToggle[self:getId()] = time
end

local wasMounted = {}
function Player.getWasMounted(self)
    return wasMounted[self:getId()] or false
end
function Player.setWasMounted(self, value)
    wasMounted[self:getId()] = value or nil
end

function Player.isMounted(self)
    return self:getOutfit().lookMount ~= 0
end

local function getRandomMount(player)
    local mounts = Game.getMounts()

    local availableMounts = {}
    for _, mount in ipairs(mounts) do
        if player:hasMount(mount.id) then
            table.insert(availableMounts, mount.id)
        end
    end

    if #availableMounts == 0 then
        return nil
    end

    local idx = math.random(1, #availableMounts)
    return availableMounts[idx]
end

function Player.mount(self, mount)
    local outfit = self:getDefaultOutfit()
    outfit.lookMount = mount.id
    self:setOutfit(outfit)

    self:changeSpeed(mount.speed)
end

function Player.dismount(self)
    local outfit = self:getDefaultOutfit()
    local lookMount = outfit.lookMount
    outfit.lookMount = 0
    self:setOutfit(outfit)

    local mount = Game.getMountByLookType(lookMount)
    if mount ~= nil then
        self:changeSpeed(-mount.speed)
    end
end

function Player.toggleMount(self, mounted)
    if os.mtime() - self:getLastMountToggle() < Outfits.ToggleMountCooldown or not self:getWasMounted() then
        return false
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
        if lookMount == nil then
            self:sendOutfitWindow()
            return false
        end

        if self:getRandomizeMount() then
            lookMount = getRandomMount(self)
            if lookMount == nil then
                self:sendOutfitWindow()
                return false
            end
        end

        local currentMount = Game.getMountByLookType(lookMount)
        if currentMount == nil then
            return false
        end

        if currentMount.premium and not self:isPremium() then
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
