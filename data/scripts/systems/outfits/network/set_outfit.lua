local handler = PacketHandler(0xD3)

function handler.onReceive(player, msg)
	if not Outfits.AllowChangeOutfit then
		return
	end

	local outfitType = msg:getByte()

	local outfit = player:getCurrentOutfit()
	outfit.lookType = msg:getU16()
	outfit.lookHead = msg:getByte()
	outfit.lookBody = msg:getByte()
	outfit.lookLegs = msg:getByte()
	outfit.lookFeet = msg:getByte()
	outfit.lookAddons = msg:getByte()

	if outfitType == 0 then -- set outfit from customize character window
		local lookMount = msg:getU16()
		local lookMountHead = msg:getByte()
		local lookMountBody = msg:getByte()
		local lookMountLegs = msg:getByte()
		local lookMountFeet = msg:getByte()

		if lookMount ~= 0 then
			outfit.lookMount = lookMount
			outfit.lookMountHead = lookMountHead
			outfit.lookMountBody = lookMountBody
			outfit.lookMountLegs = lookMountLegs
			outfit.lookMountFeet = lookMountFeet
		end

		msg:getU16() -- familiar looktype
		local randomizeMount = msg:getBool()

		if not player:canWearOutfit(outfit.lookType, outfit.lookAddons) then
			return
		end

		if outfit.lookMount ~= 0 and not player:canRideMount(outfit.lookMount) then
			return
		end

		player:setOutfit(outfit)
		player:setRandomizeMount(randomizeMount)
	elseif outfitType == 1 then -- try outfit from store window
		outfit.lookMount = 0
		outfit.lookMountHead = msg:getByte()
		outfit.lookMountBody = msg:getByte()
		outfit.lookMountLegs = msg:getByte()
		outfit.lookMountFeet = msg:getByte()

		-- open store?
	elseif outfitType == 2 then -- set podium outfit
		local position = msg:getPosition()
		local clientId = msg:getU16()
		local stackpos = msg:getByte()

		outfit.lookMount = msg:getU16()
		outfit.lookMountHead = msg:getByte()
		outfit.lookMountBody = msg:getByte()
		outfit.lookMountLegs = msg:getByte()
		outfit.lookMountFeet = msg:getByte()

		local direction = msg:getByte()
		local isVisible = msg:getBool()

		if not player:canWearOutfit(outfit.lookType, outfit.lookAddons) or not player:hasMount(outfit.lookMount) then
			return
		end

		local tile = Tile(position)
		if not tile then
			return
		end

		local item = tile:getTopDownItem()
		if not item then
			return
		end

		local itemPosition = item:getPosition()
		if itemPosition.stackpos ~= stackpos then
			return
		end

		local it = Game.getItemTypeByClientId(clientId)
		if not it or it:getClientId() ~= clientId then
			return
		end

		player:onPodiumEdit(item, outfit, direction, isVisible)
	else
		print("Warning: Unknown outfitType received in set outfit message: " .. outfitType)
	end
end

handler:register()
