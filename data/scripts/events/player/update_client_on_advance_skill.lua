local event = Event()

event.onPlayerAdvance = function(self, skill, oldLevel, newLevel)
	if skill == SKILL_LEVEL then
		return true
	end

	if newLevel > oldLevel then
		self:takeScreenshot(SCREENSHOT_TYPE_SKILLUP)
	end
	return true
end

event:register()
