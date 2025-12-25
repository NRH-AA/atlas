local event = Event()

event.onPlayerLogin = function(self)
	print(self:getName() .. " has logged in.")
	return true
end

event:register()

event = Event()

event.onPlayerLogout = function(self)
	print(self:getName() .. " has logged out.")
	return true
end

event:register()
