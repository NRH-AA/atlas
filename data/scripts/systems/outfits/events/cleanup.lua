local event = Event()

function event.onPlayerLogout(self)
    self:setLastMountToggle(nil)
    self:setWasMounted(nil)
    return true
end

event:register()
