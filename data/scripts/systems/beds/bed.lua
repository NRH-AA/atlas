-- Shared bed helpers (constants, lookups, and behaviors)
-- Global table: Bed

Bed = Bed or {}

Bed.HEALTH_MANA_PER_30_SEC = 1
Bed.SOUL_PER_15_MIN = 1
Bed.REQUIRES_PREMIUM = true
Bed.REQUIRES_PROTECTION_ZONE = true

Bed.BED_IDS = {
    1754, 1755, 1756, 1757, 1758, 1759, 1760, 1761,
    3832, 3833, 3834, 3835, 3836, 3837, 3838, 3839,
    7811, 7812, 7813, 7814, 7815, 7816, 7817, 7818
}

local bedIdSet = {}
for _, id in ipairs(Bed.BED_IDS) do
    bedIdSet[id] = true
end

function Bed.isBed(itemId)
    return bedIdSet[itemId] == true
end

local oppositeDir = {
    [DIRECTION_NORTH] = DIRECTION_SOUTH,
    [DIRECTION_SOUTH] = DIRECTION_NORTH,
    [DIRECTION_EAST] = DIRECTION_WEST,
    [DIRECTION_WEST] = DIRECTION_EAST,
}

local function getPartnerDirFromType(bed)
    if not bed then
        return nil
    end

    local it = ItemType(bed:getId())
    if not it:isBed() then
        return nil
    end

    return it:getBedPartnerDirection()
end

function Bed.getPartnerBed(bed)
    if not bed then
        return nil
    end

    local dir = getPartnerDirFromType(bed)
    if not dir then
        return nil
    end

    local pos = Position(bed:getPosition())
    pos:getNextPosition(dir)

    local tile = Tile(pos)
    if not tile then
        return nil
    end

    local items = tile:getItems()
    if not items then
        return nil
    end

    for _, item in ipairs(items) do
        if Bed.isBed(item:getId()) then
            local partnerDir = getPartnerDirFromType(item)
            if partnerDir == oppositeDir[dir] and bed:getId() < item:getId() then
                return item
            end
        end
    end

    return nil
end

function Bed.getPartnerDir(bed)
    return getPartnerDirFromType(bed)
end
