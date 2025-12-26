local event = Event()

function event.onCreatureChangeZone(self, fromZone, toZone)
    if not self:isPlayer() then
        return
    end

    if toZone == ZONE_PROTECTION and not self:getGroup():getAccess() and self:isMounted() then
        self:setWasMounted(true)
        self:toggleMount(false)
    elseif fromZone == ZONE_PROTECTION and self:getWasMounted() then
        self:toggleMount(true)
        self:setWasMounted(false)
    end
end

event:register()
