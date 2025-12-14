function Player:onBrowseField(position)
	if hasEvent.onPlayerBrowseField then
		return Event.onPlayerBrowseField(self, position)
	end
	return true
end

function Player:onLook(thing, position, distance)
	local description = ""
	if hasEvent.onPlayerLook then
		description = Event.onPlayerLook(self, thing, position, distance, description)
	end

	if description ~= "" then
		self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
end

function Player:onLookInBattleList(creature, distance)
	local description = ""
	if hasEvent.onPlayerLookInBattleList then
		description = Event.onPlayerLookInBattleList(self, creature, distance, description)
	end

	if description ~= "" then
		self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
end

function Player:onLookInTrade(partner, item, distance)
	local description = "You see " .. item:getDescription(distance)
	if hasEvent.onPlayerLookInTrade then
		description = Event.onPlayerLookInTrade(self, partner, item, distance, description)
	end

	if description ~= "" then
		self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
end

function Player:onLookInShop(itemType, count)
	local description = "You see "
	if hasEvent.onPlayerLookInShop then
		description = Event.onPlayerLookInShop(self, itemType, count, description)
	end

	if description ~= "" then
		self:sendTextMessage(MESSAGE_INFO_DESCR, description)
	end
end

function Player:onLookInMarket(itemType)
	if hasEvent.onPlayerLookInMarket then
		Event.onPlayerLookInMarket(self, itemType)
	end
end

function Player:onMoveItem(item, count, fromPosition, toPosition, fromThing, toThing)
	if hasEvent.onPlayerMoveItem then
		return Event.onPlayerMoveItem(self, item, count, fromPosition, toPosition, fromThing, toThing)
	end
	return RETURNVALUE_NOERROR
end

function Player:onItemMoved(item, count, fromPosition, toPosition, fromThing, toThing)
	if hasEvent.onPlayerItemMoved then
		Event.onPlayerItemMoved(self, item, count, fromPosition, toPosition, fromThing, toThing)
	end
end

function Player:onMoveCreature(creature, fromPosition, toPosition)
	if hasEvent.onPlayerMoveCreature then
		return Event.onPlayerMoveCreature(self, creature, fromPosition, toPosition)
	end
	return true
end

function Player:onReportRuleViolation(targetName, reportType, reportReason, comment, translation)
	if hasEvent.onPlayerReportRuleViolation then
		Event.onPlayerReportRuleViolation(self, targetName, reportType, reportReason, comment, translation)
	end
end

function Player:onReportBug(message, position)
	if hasEvent.onPlayerReportBug then
		return Event.onPlayerReportBug(self, message, position)
	end
	return true
end

function Player:onRotateItem(item)
	if hasEvent.onPlayerRotateItem then
		return Event.onPlayerRotateItem(self, item)
	end
	return true
end

function Player:onTurn(direction)
	if hasEvent.onPlayerTurn then
		return Event.onPlayerTurn(self, direction)
	end
	return true
end

function Player:onTradeRequest(target, item)
	if hasEvent.onPlayerTradeRequest then
		return Event.onPlayerTradeRequest(self, target, item)
	end
	return true
end

function Player:onTradeAccept(target, item, targetItem)
	if hasEvent.onPlayerTradeAccept then
		return Event.onPlayerTradeAccept(self, target, item, targetItem)
	end
	return true
end

function Player:onTradeCompleted(target, item, targetItem, isSuccess)
	if hasEvent.onPlayerTradeCompleted then
		Event.onPlayerTradeCompleted(self, target, item, targetItem, isSuccess)
	end
end

function Player:onPodiumRequest(item)
	if not item:isPodium() then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return
	end

	self:sendEditPodium(item)
end

function Player:onPodiumEdit(item, outfit, direction, isVisible)
	if not item:isPodium() then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return
	end

	if not self:getGroup():getAccess() then
		-- check if the player is in melee range
		if getDistanceBetween(self:getPosition(), item:getPosition()) > 1 then
			self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
			return
		end

		-- reset outfit if unable to wear
		if not self:canWearOutfit(outfit.lookType, outfit.lookAddons) then
			outfit.lookType = 0
		end

		-- reset mount if unable to ride
		local mount = Game.getMountIdByLookType(outfit.lookMount)
		if not (mount and self:hasMount(mount)) then
			outfit.lookMount = 0
		end
	end

	local podiumOutfit = item:getOutfit()
	local playerOutfit = self:getOutfit()

	-- use player outfit if podium is empty
	if podiumOutfit.lookType == 0 then
		podiumOutfit.lookType = playerOutfit.lookType
		podiumOutfit.lookHead = playerOutfit.lookHead
		podiumOutfit.lookBody = playerOutfit.lookBody
		podiumOutfit.lookLegs = playerOutfit.lookLegs
		podiumOutfit.lookFeet = playerOutfit.lookFeet
		podiumOutfit.lookAddons = playerOutfit.lookAddons
	end

	-- set player mount colors podium is empty
	if podiumOutfit.lookMount == 0 then
		podiumOutfit.lookMount = playerOutfit.lookMount
		podiumOutfit.lookMountHead = playerOutfit.lookMountHead
		podiumOutfit.lookMountBody = playerOutfit.lookMountBody
		podiumOutfit.lookMountLegs = playerOutfit.lookMountLegs
		podiumOutfit.lookMountFeet = playerOutfit.lookMountFeet
	end

	-- "outfit" box checked
	if outfit.lookType ~= 0 then
		podiumOutfit.lookType = outfit.lookType
		podiumOutfit.lookHead = outfit.lookHead
		podiumOutfit.lookBody = outfit.lookBody
		podiumOutfit.lookLegs = outfit.lookLegs
		podiumOutfit.lookFeet = outfit.lookFeet
		podiumOutfit.lookAddons = outfit.lookAddons
	end

	-- "mount" box checked
	if outfit.lookMount ~= 0 then
		podiumOutfit.lookMount = outfit.lookMount
		podiumOutfit.lookMountHead = outfit.lookMountHead
		podiumOutfit.lookMountBody = outfit.lookMountBody
		podiumOutfit.lookMountLegs = outfit.lookMountLegs
		podiumOutfit.lookMountFeet = outfit.lookMountFeet
	end

	-- prevent invisible podium state
	if outfit.lookType == 0 and outfit.lookMount == 0 then
		isVisible = true
	end

	-- save player choices
	item:setFlag(PODIUM_SHOW_PLATFORM, isVisible)
	item:setFlag(PODIUM_SHOW_OUTFIT, outfit.lookType ~= 0)
	item:setFlag(PODIUM_SHOW_MOUNT, outfit.lookMount ~= 0)
	item:setDirection(direction < DIRECTION_NORTHEAST and direction or DIRECTION_SOUTH)
	item:setOutfit(podiumOutfit)
end

function Player:onGainExperience(source, exp, rawExp, sendText)
	return hasEvent.onPlayerGainExperience and Event.onPlayerGainExperience(self, source, exp, rawExp, sendText) or exp
end

function Player:onLoseExperience(exp)
	return hasEvent.onPlayerLoseExperience and Event.onPlayerLoseExperience(self, exp) or exp
end

function Player:onGainSkillTries(skill, tries)
	if not APPLY_SKILL_MULTIPLIER then
		return hasEvent.onPlayerGainSkillTries and Event.onPlayerGainSkillTries(self, skill, tries) or tries
	end

	if skill == SKILL_MAGLEVEL then
		tries = tries * configManager.getNumber(configKeys.RATE_MAGIC)
		return hasEvent.onPlayerGainSkillTries and Event.onPlayerGainSkillTries(self, skill, tries) or tries
	end
	tries = tries * configManager.getNumber(configKeys.RATE_SKILL)
	return hasEvent.onPlayerGainSkillTries and Event.onPlayerGainSkillTries(self, skill, tries) or tries
end

function Player:onWrapItem(item)
	local topParent = item:getTopParent()
	if not topParent then
		return
	end

	local tile = Tile(topParent:getPosition())
	if not tile then
		return
	end

	local house = tile:getHouse()
	if not house then
		self:sendCancelMessage("You can only wrap and unwrap this item inside a house.")
		return
	end

	if house ~= self:getHouse() and not string.find(house:getAccessList(SUBOWNER_LIST):lower(), "%f[%a]" .. self:getName():lower() .. "%f[%A]") then
		self:sendCancelMessage("You cannot wrap or unwrap items from a house, which you are only guest to.")
		return
	end

	local wrapId = item:getAttribute("wrapid")
	if wrapId == 0 then
		return
	end

	if not hasEvent.onPlayerWrapItem or Event.onPlayerWrapItem(self, item) then
		local oldId = item:getId()
		item:remove(1)
		local item = tile:addItem(wrapId)
		if item then
			item:setAttribute("wrapid", oldId)
		end
	end
end

function Player:onInventoryUpdate(item, slot, equip)
	if hasEvent.onPlayerInventoryUpdate then
		Event.onPlayerInventoryUpdate(self, item, slot, equip)
	end
end

function Player:onNetworkMessage(recvByte, msg)
	local handler = PacketHandlers[recvByte]
	if not handler then
		--io.write(string.format("Player: %s sent an unknown packet header: 0x%02X with %d bytes!\n", self:getName(), recvByte, msg:len()))
		return
	end

	handler(self, msg)
end

function Player:onSpellCheck(spell)
	if hasEvent.onPlayerSpellCheck then
		return Event.onPlayerSpellCheck(self, spell)
	end
	return true
end

function Player:onLogin()
	if hasEvent.onPlayerLogin then
		return Event.onPlayerLogin(self)
	end
	return true
end

function Player:onJoin()
	if hasEvent.onPlayerJoin then
		Event.onPlayerJoin(self)
	end
end

function Player:onLogout()
	if hasEvent.onPlayerLogout then
		return Event.onPlayerLogout(self)
	end
	return true
end

function Player:onReconnect()
	if hasEvent.onPlayerReconnect then
		Event.onPlayerReconnect(self)
	end
end

function Player:onAdvance(skill, oldLevel, newLevel)
	if hasEvent.onPlayerAdvance then
		return Event.onPlayerAdvance(self, skill, oldLevel, newLevel)
	end
	return true
end

function Player:onModalWindow()
	if hasEvent.onPlayerModalWindow then
		Event.onPlayerModalWindow(self, modalWindowId, buttonId, choiceId)
	end
end

function Player:onTextEdit(item, text, windowTextId)
	if hasEvent.onPlayerTextEdit then
		return Event.onPlayerTextEdit(self, item, text, windowTextId)
	end
	return true
end

function Player:onExtendedOpcode(opcode, buffer)
	if hasEvent.onPlayerExtendedOpcode then
		Event.onPlayerExtendedOpcode(self, opcode, buffer)
	end
end
