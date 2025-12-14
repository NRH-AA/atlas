local event = Event()

event.onPlayerJoin = function(self)
	print(self:getName() .. " has logged in.")
end

event:register()

event = Event()

event.onPlayerLogout = function(self)
	print(self:getName() .. " has logged out.")
	return true
end

event:register()
