local Bed = {}

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

function Bed.getPartnerDirection(self)
    return self._bed.partnerDirection
end

function Bed.getPartnerId(self)
    return self._bed.partnerId
end

function Bed.getTransformTo(self, sex)
    return self._bed.transformTo[sex]
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

function Bed.removeSleeper(self, player)
    local sleeper = self:getSleeper()
    if sleeper ~= player:getId() then
        return
    end

    self:removeCustomAttribute(ITEM_ATTRIBUTE_DESCRIPTION)
	self:removeCustomAttribute(Beds.SleeperGuidKey)

    local targetId = self:getTransformTo(player:getSex())
    if type(targetId) == "number" and targetId > 0 then
        self:transform(targetId)
    end
end

function Bed.setSleeper(self, player)
    self:setCustomAttribute(ITEM_ATTRIBUTE_DESCRIPTION, string.format("%s is sleeping there.", player:getName()))
    self:setCustomAttribute(Beds.SleeperGuidKey, player:getId())

    local targetId = self:getTransformTo(player:getSex())
    if type(targetId) == "number" and targetId > 0 then
        self:transform(targetId)
    end
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
