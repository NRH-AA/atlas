local talkaction = TalkAction("/addoutfit")

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

	local outfit = Game.getOutfit(split[2], target:getSex())
	if not outfit then
		player:sendCancelMessage("Outfit " .. split[2] .. " does not exist.")
		return false
	end

	if target:hasOutfit(outfit.lookType) then
		player:sendCancelMessage("Target already has this outfit.")
		return false
	end

	return target:addOutfit(outfit.lookType, addons)
end

talkaction:separator(" ")
talkaction:accountType(ACCOUNT_TYPE_GAMEMASTER)
talkaction:register()
