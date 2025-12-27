-- /removeoutfit <player>, <outfitName|lookType>
-- Removes the owned outfit from the target player.
local talkaction = TalkAction("/removeoutfit")

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

	if not target:hasOutfit(outfit.lookType) then
		player:sendCancelMessage("Target does not have this outfit.")
		return false
	end

	return target:removeOutfit(outfit.lookType)
end

talkaction:separator(" ")
talkaction:accountType(ACCOUNT_TYPE_GAMEMASTER)
talkaction:register()
