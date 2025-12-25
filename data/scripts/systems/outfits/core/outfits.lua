function Player.addOutfit(self, lookType, addons)
    return self:setStorageValue(PlayerStorageKeys.outfitsBase + lookType, addons or 0)
end

function Player.addOutfitAddon(self, lookType, addon)
    local addons = self:getOutfitAddons(lookType)
    addons = addons | (1 << (addon - 1))
    return self:setStorageValue(PlayerStorageKeys.outfitsBase + lookType, addons)
end

function Player.getOutfitAddons(self, lookType)
    return self:getStorageValue(PlayerStorageKeys.outfitsBase + lookType) or 0
end

function Player.hasOutfit(self, lookType, addons)
    return self:hasStorageValue(PlayerStorageKeys.outfitsBase + lookType)
end

function Player.hasOutfitAddon(self, lookType, addon)
    local addons = self:getOutfitAddons(lookType)
    return (addons & (1 << (addon - 1))) ~= 0
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
    if outfit == nil then
        return false
    end

    if outfit.premium and not self:isPremium() then
        return false
    end

    if not outfit.unlocked and not self:hasOutfit(lookType) then
        return false
    end

    if addons ~= nil and addons ~= 0 and not self:hasOutfitAddon(lookType, addons) then
        return false
    end

    return true
end
