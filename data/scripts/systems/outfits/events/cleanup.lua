local event = Event()

function event.onCreatureRemoved(self)
    if not self:isPlayer() then
        return
    end

    self:setLastMountToggle(nil)
    self:setWasMounted(nil)
    return true
end

event:register()
