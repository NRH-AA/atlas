local handler = PacketHandler(0xD2)

function handler.onReceive(player, msg)
	if not Outfits.AllowChangeOutfit then
		return
	end

	player:sendOutfitWindow()
end

handler:register()
