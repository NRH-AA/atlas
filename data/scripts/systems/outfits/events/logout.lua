local event = CreatureEvent("MountsCleanup")

function event.onLogout(player)
    player:setLastMountToggle(nil)
    player:setWasMounted(nil)
    return true
end

event:register()
