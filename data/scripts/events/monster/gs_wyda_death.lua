local event = Event()

event.onCreatureDeath = function(self, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	if not self:isMonster() then
		return
	end

	local mType = self:getType()
	if mType:monsterName() ~= "Giant Spider Wyda" then
		return
	end

	self:say("It seems this was just an illusion.", TALKTYPE_MONSTER_SAY)
	if mostDamageKiller:isPlayer() then
		mostDamageKiller:addAchievement("Someone's Bored")
	end
end

event:register()
