local event = Event()

function event.onChangeZone(creature, fromZone, toZone)
    if not creature:isPlayer() then
        return
    end

    local player = creature:getPlayer()
    if toZone == ZONE_PROTECTION then
        if not player:getGroup():getAccess() and player:isMounted() then
            player:toggleMount(false)
            player:setWasMounted(true)
        end
    elseif player:getWasMounted() then
        player:toggleMount(true)
        player:setWasMounted(false)
    end
end

event:register()
