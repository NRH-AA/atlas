local action = Action()

local skillChoices = {
	{ text = "Sword Fighting and Shielding", skill = SKILL_SWORD },
	{ text = "Axe Fighting and Shielding", skill = SKILL_AXE },
	{ text = "Club Fighting and Shielding", skill = SKILL_CLUB },
	{ text = "Distance Fighting and Shielding", skill = SKILL_DISTANCE },
	{ text = "Magic Level and Shielding", skill = SKILL_MAGLEVEL },
}

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

local function sleep(player, bed)
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
end

local function abortOfflineTraining(player)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Offline training aborted.")
end

local function sendOfflineTrainingModal(player, bed)
    local offlineTrainingModal = ModalWindow{
        title = "Choose a Skill",
        message = "Please choose a skill:",
        priority = true
    }

    offlineTrainingModal:setDefaultEnterButton("Okay")
    offlineTrainingModal:setDefaultEscapeButton("Cancel")

    local choiceSkillById = {}
    for _, entry in ipairs(skillChoices) do
        local choice = offlineTrainingModal:addChoice(entry.text)
        choiceSkillById[choice.id] = entry.skill
    end

    offlineTrainingModal:addButton("Okay", function(player, button, choice)
        local selectedSkill = choiceSkillById[choice.id]
        if not selectedSkill then
            abortOfflineTraining(player)
            return true
        end

        player:setOfflineTrainingSkill(selectedSkill)
        sleep(player, bed)
        return true
    end)

    offlineTrainingModal:addButton("Cancel", function(player, button, choice)
        abortOfflineTraining(player)
        return true
    end)

    offlineTrainingModal:sendToPlayer(player)
end

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not canUse(player, item) then
        item:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    if Bed.OFFLINE_TRAINING_ENABLED then
        sendOfflineTrainingModal(player, item)
        return true
    end

    sleep(player, item)
    return true
end

action:id(table.unpack(Bed.BED_IDS))
action:register()
