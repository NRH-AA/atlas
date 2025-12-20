local action = Action()

local function canUse(player, bed)
    if Bed.REQUIRES_PROTECTION_ZONE and player:getZone() ~= ZONE_PROTECTION then
        return false
    end

    if Bed.REQUIRES_PREMIUM then
        local premiumEnds = player.getPremiumEndsAt and player:getPremiumEndsAt() or 0
        if premiumEnds <= os.time() then
            return false
        end
    end

    local tile = bed:getTile()
    if not tile then
        return false
    end

    local house = tile:getHouse()
    if not house then
        return false
    end

    return true
end

local function setSleeper(bed, player)
    bed:setCustomAttribute(ITEM_ATTRIBUTE_DESCRIPTION, string.format("%s is sleeping there.", player:getName()))

    local sexAttr = player:getSex() == PLAYERSEX_FEMALE and "femaleSleeper" or "maleSleeper"
    local targetId = bed:getAttribute(sexAttr)
    if type(targetId) == "number" and targetId > 0 then
        bed:transform(targetId)
    end
end

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local ok, reason = canUse(player, item)
    if not ok then
        if reason then
            player:sendCancelMessage(reason)
        end
        item:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    if not canUse(player, bed) then
        bed:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    local partner = Bed.getPartnerBed(bed)

    setSleeper(bed, player)
    if partner then
        setSleeper(partner, player)
    end

    bed:getPosition():sendMagicEffect(CONST_ME_SLEEP)
    player:teleportTo(bed:getPosition(), true)

    addEvent(function(pid)
        local sleeper = Player(pid)
        if sleeper then
            sleeper:remove()
        end
    end, SCHEDULER_MINTICKS, player:getId())

    return true
end

action:id(table.unpack(Bed.BED_IDS))
action:register()
