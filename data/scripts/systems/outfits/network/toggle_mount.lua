local handler = PacketHandler(0xD4)

function handler.onReceive(player, msg)
	if not Outfits.AllowToggleMount then
		return
	end
	
	local mounted = msg:getBool()
	player:toggleMount(mounted)
end

handler:register()
