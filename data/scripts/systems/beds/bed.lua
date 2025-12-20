-- Shared bed helpers (constants, lookups, and behaviors)
-- Global table: Bed

Bed = Bed or {}

Bed.HEALTH_MANA_PER_30_SEC = 1
Bed.SOUL_PER_15_MIN = 1
Bed.REQUIRES_PREMIUM = true
Bed.REQUIRES_PROTECTION_ZONE = true
Bed.KICK_DELAY_MS = 1000

Bed.BED_IDS = {
    1754, 1755, 1756, 1757, 1758, 1759, 1760, 1761,
    3832, 3833, 3834, 3835, 3836, 3837, 3838, 3839,
    7811, 7812, 7813, 7814, 7815, 7816, 7817, 7818
}

Bed.PARTNER_DIR = {
    [1754] = DIRECTION_EAST, [1755] = DIRECTION_WEST,
    [1756] = DIRECTION_SOUTH, [1757] = DIRECTION_NORTH,
    [1758] = DIRECTION_EAST, [1759] = DIRECTION_WEST,
    [1760] = DIRECTION_SOUTH, [1761] = DIRECTION_NORTH,
    [3832] = DIRECTION_EAST, [3833] = DIRECTION_WEST,
    [3834] = DIRECTION_SOUTH, [3835] = DIRECTION_NORTH,
    [3836] = DIRECTION_EAST, [3837] = DIRECTION_WEST,
    [3838] = DIRECTION_SOUTH, [3839] = DIRECTION_NORTH,
    [7811] = DIRECTION_EAST, [7812] = DIRECTION_WEST,
    [7813] = DIRECTION_SOUTH, [7814] = DIRECTION_NORTH,
    [7815] = DIRECTION_EAST, [7816] = DIRECTION_WEST,
    [7817] = DIRECTION_SOUTH, [7818] = DIRECTION_NORTH
}

local bedIdSet = {}
for _, id in ipairs(Bed.BED_IDS) do
    bedIdSet[id] = true
end

function Bed.isBed(itemId)
    return bedIdSet[itemId] == true
end

function Bed.getPartnerBed(bed)
    if not bed then
        return nil
    end

    local dir = Bed.PARTNER_DIR[bed:getId()]
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
            return item
        end
    end

    return nil
end
