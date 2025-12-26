function Player.addOutfit(self, lookType, addons)
    return self:setStorageValue(PlayerStorageKeys.outfitsBase + lookType, addons or 0)
end

function Player.addOutfitAddon(self, lookType, addon)
    local addons = self:getOutfitAddons(lookType)
    addons = addons | (1 << (addon - 1))
    return self:setStorageValue(PlayerStorageKeys.outfitsBase + lookType, addons)
end

function Player.getOutfitAddons(self, lookType)
    local outfitAddons = self:getStorageValue(PlayerStorageKeys.outfitsBase + lookType)
    if outfitAddons == nil or outfitAddons == -1 then
        return 0
    end
    return outfitAddons
end

function Player.hasOutfit(self, lookType, addons)
    local outfitAddons = self:getStorageValue(PlayerStorageKeys.outfitsBase + lookType)
    if outfitAddons == nil or outfitAddons == -1 then
        return false
    end

    if addons == nil or addons == 0 then
        return true
    end

    return (outfitAddons & addons) == addons
end

function Player.hasOutfitAddon(self, lookType, addon)
    return self:getOutfitAddons(lookType) & addon ~= 0
end

function Player.removeOutfit(self, lookType)
    return self:removeStorageValue(PlayerStorageKeys.outfitsBase + lookType)
end

function Player.removeOutfitAddon(self, lookType, addon)
    local addons = self:getOutfitAddons(lookType)
    addons = addons & ~(1 << (addon - 1))
    return self:setStorageValue(PlayerStorageKeys.outfitsBase + lookType, addons)
end

function Player.canWearOutfit(self, lookType, addons)
    if self:getGroup():getAccess() then
        return true
    end

    local outfit = Game.getOutfitByLookType(lookType)
    if not outfit then
        return false
    end

    if outfit.premium and not self:isPremium() then
        return false
    end

    if not outfit.unlocked and not self:hasOutfit(lookType) then
        return false
    end

    return addons == nil or addons == 0 or self:hasOutfitAddon(lookType, addons)
end
