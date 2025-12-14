function Creature:onChangeOutfit(outfit)
	if hasEvent.onCreatureChangeMount then
		if not Event.onCreatureChangeMount(self, outfit.lookMount) then
			return false
		end
	end
	if hasEvent.onCreatureChangeOutfit then
		return Event.onCreatureChangeOutfit(self, outfit)
	end
	return true
end

function Creature:onAreaCombat(tile, isAggressive)
	if hasEvent.onCreatureAreaCombat then
		return Event.onCreatureAreaCombat(self, tile, isAggressive)
	end
	return RETURNVALUE_NOERROR
end

function Creature:onTargetCombat(target)
	if hasEvent.onCreatureTargetCombat then
		return Event.onCreatureTargetCombat(self, target)
	end
	return RETURNVALUE_NOERROR
end

function Creature:onHear(speaker, words, type)
	if hasEvent.onCreatureHear then
		Event.onCreatureHear(self, speaker, words, type)
	end
end

function Creature:onChangeZone(attacker, damage)
	if hasEvent.onCreatureChangeZone then
		Event.onCreatureChangeZone(self, attacker, damage)
	end
end

function Creature:onChangeHealth(attacker, damage)
	if hasEvent.onCreatureChangeHealth then
		Event.onCreatureChangeHealth(self, attacker, damage)
	end
end

function Creature:onChangeMana(attacker, damage)
	if hasEvent.onCreatureChangeMana then
		Event.onCreatureChangeMana(self, attacker, damage)
	end
end

function Creature:onUpdateStorage(key, value, oldValue, isSpawn)
	if hasEvent.onCreatureUpdateStorage then
		Event.onCreatureUpdateStorage(self, key, value, oldValue, isSpawn)
	end
end

function Creature:onThink(interval)
	if hasEvent.onCreatureThink then
		Event.onCreatureThink(self, interval)
	end
end

function Creature:onPrepareDeath(killer)
	if hasEvent.onCreaturePrepareDeath then
		return Event.onCreaturePrepareDeath(self, killer)
	end
	return true
end

function Creature:onDeath(corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	if hasEvent.onCreatureDeath then
		Event.onCreatureDeath(self, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	end
end

function Creature:onKill(target)
	if hasEvent.onCreatureKill then
		Event.onCreatureKill(self, target)
	end
end
