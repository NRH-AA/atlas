local action = Action()

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    return onUseKitchenKnife(player, item, fromPosition, target, toPosition, isHotkey)
end

action:id(2566)
action:register()
