local action = Action()

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local headboard = item:getBed()
    if not headboard then
        return false
    end

    local tile = Tile(headboard:getPosition())
    if not tile then
        return false
    end

    local house = tile:getHouse()
    if not house or (house:getOwnerGuid() ~= player:getId() and not player:getGroup():getAccess()) then
        return false
    end

    local footboard = headboard:getPartnerBed()
    return footboard ~= nil and headboard:removeSleeper() and footboard:removeSleeper()
end

local function getOccupiedHeadboardIds()
    local headboards = {}
    for id, bed in pairs(Game.getBeds()) do
        if bed.occupied and (bed.partnerDirection == DIRECTION_SOUTH or bed.partnerDirection == DIRECTION_EAST) then
            table.insert(headboards, id)
        end
    end
    return headboards
end

action:id(table.unpack(getOccupiedHeadboardIds()))
action:register()
