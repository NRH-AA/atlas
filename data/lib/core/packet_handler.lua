PacketHandlers = {}

local function register(self)
	if not self.onReceive then
		debugPrint("[Warning - PacketHandler::register] need to setup a callback before you can register.")
		return
	end

	if type(self.onReceive) ~= "function" then
		debugPrint(string.format("[Warning - PacketHandler::onReceive] a function is expected."))
		return
	end

	PacketHandlers[self.packetType] = self.onReceive
end

local function clear(self)
	PacketHandlers[self.packetType] = nil
end

function PacketHandler(packetType)
	return {
		clear = clear,
		packetType = packetType,
		register = register,
	}
end
