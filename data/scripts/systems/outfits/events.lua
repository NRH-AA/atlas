local event = Event()

event.onCreatureChangeZone = function(self, fromZone, toZone)
    if not self:isPlayer() then
        return
    end

    local player = self:getPlayer()
    if toZone == ZONE_PROTECTION and not player:getGroup():getAccess() and player:isMounted() then
        player:toggleMount(false)
        player:setWasMounted(true)
    elseif fromZone == ZONE_PROTECTION and player:getWasMounted() then
        player:toggleMount(true)
        player:setWasMounted(false)
    end
end

event:register()
