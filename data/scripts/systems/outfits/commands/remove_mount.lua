local talkaction = TalkAction("/removemount")

function talkaction.onSay(player, words, param)
	local split = param:splitTrimmed(",")
	if #split < 2 then
		player:sendCancelMessage("Insufficient parameters.")
		return false
	end

	local target = Player(split[1])
	if not target then
		player:sendCancelMessage("A player with that name is not online.")
		return false
	end

	local mount = Game.getMount(split[2])
	if not mount then
		player:sendCancelMessage("Mount " .. split[2] .. " does not exist.")
		return false
	end

	if not target:hasMount(mount.lookType) then
		player:sendCancelMessage("Target does not have this mount.")
		return false
	end

	return target:removeMount(mount.lookType)
end

talkaction:separator(" ")
talkaction:accountType(ACCOUNT_TYPE_GAMEMASTER)
talkaction:register()
