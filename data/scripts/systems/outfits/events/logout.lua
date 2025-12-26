local event = CreatureEvent("MountsCleanup")

function event.onLogout(self, player)
    player:setLastMountToggle(nil)
    player:setWasMounted(nil)
    return true
end

event:register()
