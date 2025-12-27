local Bed = {}

function Bed.isOccupied(self)
    return self._bed.occupied
end

function Bed.getPartnerDirection(self)
    return self._bed.partnerDirection
end

function Bed.getPartnerId(self)
    return self._bed.partnerId
end

function Bed.getTransformToOccupied(self, sex)
    if self:isOccupied() then
        return nil
    end
    return self._bed.transformToOccupied[sex]
end

function Bed.getTransformToFree(self)
    if not self:isOccupied() then
        return nil
    end
    return self._bed.transformToFree
end

function Bed.getPartnerBed(self)
    local position = self:getPosition()
    local partnerDir = self:getPartnerDirection()
    if not partnerDir then
        return nil
    end

    local partnerPos = Position(position)
    partnerPos:getNextPosition(partnerDir)

    local tile = Tile(partnerPos)
    if not tile then
        return nil
    end

    local items = tile:getItems()
    if not items then
        return nil
    end

    for _, item in ipairs(items) do
        if item:getId() == self:getPartnerId() then
            return item:getBed()
        end
    end
end

function Bed.isHeadboard(self)
    local dir = self:getPartnerDirection()
    return dir == DIRECTION_SOUTH or dir == DIRECTION_EAST
end

function Bed.isFootboard(self)
    local dir = self:getPartnerDirection()
    return dir == DIRECTION_NORTH or dir == DIRECTION_WEST
end

function Bed.getSleeper(self)
    return self:getCustomAttribute(Beds.SleeperGuidKey)
end

function Bed.removeSleeper(self)
    if not self:isOccupied() then
        return false
    end

    self:setSpecialDescription(nil)
	self:removeCustomAttribute(Beds.SleeperGuidKey)

    local targetId = self:getTransformToFree()
    return targetId ~= nil and self:transform(targetId)
end

function Bed.setSleeper(self, player)
    if self:isOccupied() then
        return false
    end

    self:setSpecialDescription(string.format("%s is sleeping there.", player:getName()))
    self:setCustomAttribute(Beds.SleeperGuidKey, player:getId())

    local targetId = self:getTransformToOccupied(player:getSex())
    return targetId ~= nil and self:transform(targetId)
end

function ItemType.isBed(self)
    local beds = Game.getBeds()
    return beds[self:getId()] ~= nil
end

function Item.getBed(self)
    local beds = Game.getBeds()
    local bed = beds[self:getId()]
    if not bed then
        return nil
    end

    local wrapper = { _bed = bed, _item = self }

    setmetatable(wrapper, {
        __index = function(t, k)
            local v = Bed[k]
            if v ~= nil then
                return v
            end

            local inner = t._item[k]
            if type(inner) == "function" then
                return function(_, ...)
                    return inner(t._item, ...)
                end
            end

            return inner
        end,
    })

    return wrapper
end
