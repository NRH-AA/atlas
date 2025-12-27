function Player.addOutfit(self, lookType)
    local addons = self:getStorageValue(PlayerStorageKeys.outfitsBase + lookType)
    if addons ~= nil and addons ~= -1 then
        return true
    end
    return self:setStorageValue(PlayerStorageKeys.outfitsBase + lookType, 0)
end

function Player.addAllOutfits(self)
    local outfits = Game.getOutfits(self:getSex())
    for _, outfit in ipairs(outfits) do
        self:addOutfit(outfit.lookType)
    end
end

function Player.addOutfitAddon(self, lookType, addon)
    local addons = self:getStorageValue(PlayerStorageKeys.outfitsBase + lookType)
    if addons == nil or addons == -1 then
        return false
    end

    addons = addons | (1 << (addon - 1))
    return self:setStorageValue(PlayerStorageKeys.outfitsBase + lookType, addons)
end

function Player.addAddonToAllOutfits(self, addon)
	for sex = 0, 1 do
		local outfits = Game.getOutfits(sex)
		for _, outfit in ipairs(outfits) do
			self:addOutfit(outfit.lookType)
			self:addOutfitAddon(outfit.lookType, addon)
		end
	end
end

function Player.getOutfitAddons(self, lookType)
    local outfitAddons = self:getStorageValue(PlayerStorageKeys.outfitsBase + lookType)
    if outfitAddons == nil or outfitAddons == -1 then
        return 0
    end
    return outfitAddons
end

function Player.hasOutfit(self, lookType)
    local addons = self:getStorageValue(PlayerStorageKeys.outfitsBase + lookType)
    return addons ~= nil and addons ~= -1
end

function Player.hasOutfitAddons(self, lookType, addons)
    local currentAddons = self:getStorageValue(PlayerStorageKeys.outfitsBase + lookType)
    if currentAddons == nil or currentAddons == -1 then
        return false
    end
    return (currentAddons & addons) == addons
end

function Player.hasOutfitAddon(self, lookType, addon)
    local addons = self:getOutfitAddons(lookType)
    return addons & (1 << (addon - 1)) ~= 0
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

    if addons == nil or addons == 0 then
        return true
    end

    return self:getOutfitAddons(lookType) & addons == addons
end
