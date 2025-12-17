// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "events.h"

#include "item.h"
#include "player.h"
#include "monster.h"

namespace {

LuaScriptInterface scriptInterface{"Event Interface"};

struct CreatureHandlers
{
	int32_t onChangeOutfit = -1;
	int32_t onAreaCombat = -1;
	int32_t onTargetCombat = -1;
	int32_t onHear = -1;
	int32_t onChangeZone = -1;
	int32_t onChangeHealth = -1;
	int32_t onChangeMana = -1;
	int32_t onUpdateStorage = -1;
	int32_t onThink = -1;
	int32_t onPrepareDeath = -1;
	int32_t onDeath = -1;
	int32_t onKill = -1;
} creatureHandlers;

struct PartyHandlers
{
	int32_t onJoin = -1;
	int32_t onLeave = -1;
	int32_t onDisband = -1;
	int32_t onShareExperience = -1;
	int32_t onInvite = -1;
	int32_t onRevokeInvitation = -1;
	int32_t onPassLeadership = -1;
} partyHandlers;

struct PlayerHandlers
{
	int32_t onBrowseField = -1;
	int32_t onLook = -1;
	int32_t onLookInBattleList = -1;
	int32_t onLookInTrade = -1;
	int32_t onLookInShop = -1;
	int32_t onLookInMarket = -1;
	int32_t onMoveItem = -1;
	int32_t onItemMoved = -1;
	int32_t onMoveCreature = -1;
	int32_t onReportRuleViolation = -1;
	int32_t onReportBug = -1;
	int32_t onRotateItem = -1;
	int32_t onTurn = -1;
	int32_t onTradeRequest = -1;
	int32_t onTradeAccept = -1;
	int32_t onTradeCompleted = -1;
	int32_t onPodiumRequest = -1;
	int32_t onPodiumEdit = -1;
	int32_t onGainExperience = -1;
	int32_t onLoseExperience = -1;
	int32_t onGainSkillTries = -1;
	int32_t onWrapItem = -1;
	int32_t onInventoryUpdate = -1;
	int32_t onNetworkMessage = -1;
	int32_t onSpellCheck = -1;
	int32_t onLogin = -1;
	int32_t onJoin = -1;
	int32_t onLogout = -1;
	int32_t onReconnect = -1;
	int32_t onModalWindow = -1;
	int32_t onExtendedOpcode = -1;
} playerHandlers;

struct MonsterHandlers
{
	int32_t onDropLoot = -1;
	int32_t onSpawn = -1;
} monsterHandlers;

bool load_from_xml()
{
	pugi::xml_document doc;
	pugi::xml_parse_result result = doc.load_file("data/events/events.xml");
	if (!result) {
		printXMLError("Error - tfs::events::load_from_xml", "data/events/events.xml", result);
		return false;
	}

	creatureHandlers = {};
	partyHandlers = {};
	playerHandlers = {};
	monsterHandlers = {};

	std::set<std::string> classes;
	for (auto eventNode : doc.child("events").children()) {
		if (!eventNode.attribute("enabled").as_bool()) {
			continue;
		}

		const std::string& className = eventNode.attribute("class").as_string();
		auto res = classes.insert(className);
		if (res.second) {
			const std::string& lowercase = boost::algorithm::to_lower_copy(className);
			if (scriptInterface.loadFile("data/events/scripts/" + lowercase + ".lua") != 0) {
				std::cout << "[Warning - tfs::events::load_from_xml] Can not load script: " << lowercase << ".lua"
				          << std::endl;
				std::cout << scriptInterface.getLastLuaError() << std::endl;
			}
		}

		const std::string& methodName = eventNode.attribute("method").as_string();
		const auto event = scriptInterface.getMetaEvent(className, methodName);
		if (className == "Creature") {
			if (methodName == "onChangeOutfit") {
				creatureHandlers.onChangeOutfit = event;
			} else if (methodName == "onAreaCombat") {
				creatureHandlers.onAreaCombat = event;
			} else if (methodName == "onTargetCombat") {
				creatureHandlers.onTargetCombat = event;
			} else if (methodName == "onHear") {
				creatureHandlers.onHear = event;
			} else if (methodName == "onChangeZone") {
				creatureHandlers.onChangeZone = event;
			} else if (methodName == "onChangeHealth") {
				creatureHandlers.onChangeHealth = event;
			} else if (methodName == "onChangeMana") {
				creatureHandlers.onChangeMana = event;
			} else if (methodName == "onUpdateStorage") {
				creatureHandlers.onUpdateStorage = event;
			} else if (methodName == "onThink") {
				creatureHandlers.onThink = event;
			} else if (methodName == "onPrepareDeath") {
				creatureHandlers.onPrepareDeath = event;
			} else if (methodName == "onDeath") {
				creatureHandlers.onDeath = event;
			} else if (methodName == "onKill") {
				creatureHandlers.onKill = event;
			} else {
				std::cout << "[Warning - tfs::events::load_from_xml] Unknown creature method: " << methodName
				          << std::endl;
			}
		} else if (className == "Party") {
			if (methodName == "onJoin") {
				partyHandlers.onJoin = event;
			} else if (methodName == "onLeave") {
				partyHandlers.onLeave = event;
			} else if (methodName == "onDisband") {
				partyHandlers.onDisband = event;
			} else if (methodName == "onShareExperience") {
				partyHandlers.onShareExperience = event;
			} else if (methodName == "onInvite") {
				partyHandlers.onInvite = event;
			} else if (methodName == "onRevokeInvitation") {
				partyHandlers.onRevokeInvitation = event;
			} else if (methodName == "onPassLeadership") {
				partyHandlers.onPassLeadership = event;
			} else {
				std::cout << "[Warning - tfs::events::load_from_xml] Unknown party method: " << methodName << std::endl;
			}
		} else if (className == "Player") {
			if (methodName == "onBrowseField") {
				playerHandlers.onBrowseField = event;
			} else if (methodName == "onLook") {
				playerHandlers.onLook = event;
			} else if (methodName == "onLookInBattleList") {
				playerHandlers.onLookInBattleList = event;
			} else if (methodName == "onLookInTrade") {
				playerHandlers.onLookInTrade = event;
			} else if (methodName == "onLookInShop") {
				playerHandlers.onLookInShop = event;
			} else if (methodName == "onLookInMarket") {
				playerHandlers.onLookInMarket = event;
			} else if (methodName == "onTradeRequest") {
				playerHandlers.onTradeRequest = event;
			} else if (methodName == "onTradeAccept") {
				playerHandlers.onTradeAccept = event;
			} else if (methodName == "onTradeCompleted") {
				playerHandlers.onTradeCompleted = event;
			} else if (methodName == "onPodiumRequest") {
				playerHandlers.onPodiumRequest = event;
			} else if (methodName == "onPodiumEdit") {
				playerHandlers.onPodiumEdit = event;
			} else if (methodName == "onMoveItem") {
				playerHandlers.onMoveItem = event;
			} else if (methodName == "onItemMoved") {
				playerHandlers.onItemMoved = event;
			} else if (methodName == "onMoveCreature") {
				playerHandlers.onMoveCreature = event;
			} else if (methodName == "onReportRuleViolation") {
				playerHandlers.onReportRuleViolation = event;
			} else if (methodName == "onReportBug") {
				playerHandlers.onReportBug = event;
			} else if (methodName == "onRotateItem") {
				playerHandlers.onRotateItem = event;
			} else if (methodName == "onTurn") {
				playerHandlers.onTurn = event;
			} else if (methodName == "onGainExperience") {
				playerHandlers.onGainExperience = event;
			} else if (methodName == "onLoseExperience") {
				playerHandlers.onLoseExperience = event;
			} else if (methodName == "onGainSkillTries") {
				playerHandlers.onGainSkillTries = event;
			} else if (methodName == "onWrapItem") {
				playerHandlers.onWrapItem = event;
			} else if (methodName == "onInventoryUpdate") {
				playerHandlers.onInventoryUpdate = event;
			} else if (methodName == "onNetworkMessage") {
				playerHandlers.onNetworkMessage = event;
			} else if (methodName == "onSpellCheck") {
				playerHandlers.onSpellCheck = event;
			} else if (methodName == "onLogin") {
				playerHandlers.onLogin = event;
			} else if (methodName == "onJoin") {
				playerHandlers.onJoin = event;
			} else if (methodName == "onLogout") {
				playerHandlers.onLogout = event;
			} else if (methodName == "onReconnect") {
				playerHandlers.onReconnect = event;
			} else if (methodName == "onModalWindow") {
				playerHandlers.onModalWindow = event;
			} else if (methodName == "onExtendedOpcode") {
				playerHandlers.onExtendedOpcode = event;
			} else {
				std::cout << "[Warning - tfs::events::load_from_xml] Unknown player method: " << methodName
				          << std::endl;
			}
		} else if (className == "Monster") {
			if (methodName == "onDropLoot") {
				monsterHandlers.onDropLoot = event;
			} else if (methodName == "onSpawn") {
				monsterHandlers.onSpawn = event;
			} else {
				std::cout << "[Warning - tfs::events::load_from_xml] Unknown monster method: " << methodName
				          << std::endl;
			}
		} else {
			std::cout << "[Warning - tfs::events::load_from_xml] Unknown class: " << className << std::endl;
		}
	}

	return true;
}

} // namespace

namespace tfs::events {

int32_t getScriptId(EventInfoId eventInfoId)
{
	switch (eventInfoId) {
		case EventInfoId::CREATURE_ONHEAR:
			return creatureHandlers.onHear;
		case EventInfoId::MONSTER_ONSPAWN:
			return monsterHandlers.onSpawn;
		default:
			return -1;
	}
}

bool load()
{
	scriptInterface.initState();
	return load_from_xml();
}

bool reload()
{
	scriptInterface.reInitState();
	return load_from_xml();
}

} // namespace tfs::events

namespace tfs::events::creature {

bool onChangeOutfit(const std::shared_ptr<Creature>& creature, const Outfit_t& outfit)
{
	// Creature:onChangeOutfit(outfit)
	if (creatureHandlers.onChangeOutfit == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onChangeOutfit] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onChangeOutfit, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onChangeOutfit);

	tfs::lua::pushThing(L, creature);
	tfs::lua::pushOutfit(L, outfit);
	return scriptInterface.callFunction(2);
}

ReturnValue onAreaCombat(const std::shared_ptr<Creature>& creature, const std::shared_ptr<Tile>& tile, bool aggressive)
{
	// Creature:onAreaCombat(tile, aggressive)
	if (creatureHandlers.onAreaCombat == -1) {
		return RETURNVALUE_NOERROR;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onAreaCombat] Call stack overflow" << std::endl;
		return RETURNVALUE_NOTPOSSIBLE;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onAreaCombat, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onAreaCombat);

	if (creature) {
		tfs::lua::pushThing(L, creature);
	} else {
		lua_pushnil(L);
	}

	tfs::lua::pushThing(L, tile);
	tfs::lua::pushBoolean(L, aggressive);

	ReturnValue returnValue;
	if (tfs::lua::protectedCall(L, 3, 1) != 0) {
		returnValue = RETURNVALUE_NOTPOSSIBLE;
		reportErrorFunc(L, tfs::lua::popString(L));
	} else {
		returnValue = tfs::lua::getNumber<ReturnValue>(L, -1);
		lua_pop(L, 1);
	}

	tfs::lua::resetScriptEnv();
	return returnValue;
}

ReturnValue onTargetCombat(const std::shared_ptr<Creature>& creature, const std::shared_ptr<Creature>& target)
{
	// Creature:onTargetCombat(target)
	if (creatureHandlers.onTargetCombat == -1) {
		return RETURNVALUE_NOERROR;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onTargetCombat] Call stack overflow" << std::endl;
		return RETURNVALUE_NOTPOSSIBLE;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onTargetCombat, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onTargetCombat);

	if (creature) {
		tfs::lua::pushThing(L, creature);
	} else {
		lua_pushnil(L);
	}

	tfs::lua::pushThing(L, target);

	ReturnValue returnValue;
	if (tfs::lua::protectedCall(L, 2, 1) != 0) {
		returnValue = RETURNVALUE_NOTPOSSIBLE;
		reportErrorFunc(L, tfs::lua::popString(L));
	} else {
		returnValue = tfs::lua::getNumber<ReturnValue>(L, -1);
		lua_pop(L, 1);
	}

	tfs::lua::resetScriptEnv();
	return returnValue;
}

void onHear(const std::shared_ptr<Creature>& creature, const std::shared_ptr<Creature>& speaker,
            const std::string& words, SpeakClasses type)
{
	// Creature:onHear(speaker, words, type)
	if (creatureHandlers.onHear == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onHear] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onHear, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onHear);

	tfs::lua::pushThing(L, creature);
	tfs::lua::pushThing(L, speaker);
	tfs::lua::pushString(L, words);
	tfs::lua::pushNumber(L, type);
	scriptInterface.callVoidFunction(4);
}

void onChangeZone(const std::shared_ptr<Creature>& creature, ZoneType_t fromZone, ZoneType_t toZone)
{
	// Creature:onChangeZone(fromZone, toZone)
	if (creatureHandlers.onChangeZone == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onChangeZone] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onChangeZone, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onChangeZone);

	tfs::lua::pushThing(L, creature);
	tfs::lua::pushNumber(L, fromZone);
	tfs::lua::pushNumber(L, toZone);
	scriptInterface.callVoidFunction(3);
}

void onChangeHealth(const std::shared_ptr<Creature>& creature, const std::shared_ptr<Creature>& attacker,
                    CombatDamage& damage)
{
	// Creature:onChangeHealth(attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if (creatureHandlers.onChangeHealth == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onChangeHealth] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onChangeHealth, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onChangeHealth);

	tfs::lua::pushThing(L, creature);

	if (attacker) {
		tfs::lua::pushSharedPtr(L, attacker);
		tfs::lua::setCreatureMetatable(L, -1, attacker);
	} else {
		lua_pushnil(L);
	}

	tfs::lua::pushNumber(L, damage.primary.value);
	tfs::lua::pushNumber(L, damage.primary.type);
	tfs::lua::pushNumber(L, damage.secondary.value);
	tfs::lua::pushNumber(L, damage.secondary.type);
	tfs::lua::pushNumber(L, damage.origin);

	if (tfs::lua::protectedCall(L, 7, 4) != 0) {
		reportErrorFunc(nullptr, tfs::lua::popString(L));
	} else {
		damage.primary.value = std::abs(tfs::lua::getNumber<int32_t>(L, -4, damage.primary.value));
		damage.primary.type = tfs::lua::getNumber<CombatType_t>(L, -3, damage.primary.type);
		damage.secondary.value = std::abs(tfs::lua::getNumber<int32_t>(L, -2, damage.secondary.value));
		damage.secondary.type = tfs::lua::getNumber<CombatType_t>(L, -1, damage.secondary.type);
		lua_pop(L, 4);

		if (damage.primary.type != COMBAT_HEALING) {
			damage.primary.value = -damage.primary.value;
			damage.secondary.value = -damage.secondary.value;
		}
	}

	tfs::lua::resetScriptEnv();
}

void onChangeMana(const std::shared_ptr<Creature>& creature, const std::shared_ptr<Creature>& attacker,
                  CombatDamage& damage)
{
	// Creature:onChangeMana(attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if (creatureHandlers.onChangeMana == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onChangeMana] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onChangeMana, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onChangeMana);

	tfs::lua::pushThing(L, creature);

	if (attacker) {
		tfs::lua::pushThing(L, attacker);
	} else {
		lua_pushnil(L);
	}

	tfs::lua::pushNumber(L, damage.primary.value);
	tfs::lua::pushNumber(L, damage.primary.type);
	tfs::lua::pushNumber(L, damage.secondary.value);
	tfs::lua::pushNumber(L, damage.secondary.type);
	tfs::lua::pushNumber(L, damage.origin);

	if (tfs::lua::protectedCall(L, 7, 4) != 0) {
		reportErrorFunc(nullptr, tfs::lua::popString(L));
	} else {
		damage.primary.value = tfs::lua::getNumber<int32_t>(L, -4, damage.primary.value);
		damage.primary.type = tfs::lua::getNumber<CombatType_t>(L, -3, damage.primary.type);
		damage.secondary.value = tfs::lua::getNumber<int32_t>(L, -2, damage.secondary.value);
		damage.secondary.type = tfs::lua::getNumber<CombatType_t>(L, -1, damage.secondary.type);
		lua_pop(L, 4);
	}

	tfs::lua::resetScriptEnv();
}

void onUpdateStorage(const std::shared_ptr<Creature>& creature, uint32_t key, std::optional<int32_t> value,
                     std::optional<int32_t> oldValue, bool isSpawn)
{
	// Creature:onUpdateStorage(key, value, oldValue, isSpawn)
	if (creatureHandlers.onUpdateStorage == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onUpdateStorage] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onUpdateStorage, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onUpdateStorage);

	tfs::lua::pushThing(L, creature);
	tfs::lua::pushNumber(L, key);

	if (value) {
		tfs::lua::pushNumber(L, value.value());
	} else {
		lua_pushnil(L);
	}

	if (oldValue) {
		tfs::lua::pushNumber(L, oldValue.value());
	} else {
		lua_pushnil(L);
	}

	tfs::lua::pushBoolean(L, isSpawn);
	scriptInterface.callVoidFunction(5);
}

void onThink(const std::shared_ptr<Creature>& creature, uint32_t interval)
{
	// Player:onThink(interval)
	if (creatureHandlers.onThink == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onThink] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onThink, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onThink);

	tfs::lua::pushThing(L, creature);
	tfs::lua::pushNumber(L, interval);
	scriptInterface.callVoidFunction(2);
}

bool onPrepareDeath(const std::shared_ptr<Creature>& creature, const std::shared_ptr<Creature>& killer)
{
	// Creature:onPrepareDeath(killer)
	if (creatureHandlers.onPrepareDeath == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onPrepareDeath] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onPrepareDeath, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onPrepareDeath);

	tfs::lua::pushThing(L, creature);

	if (killer) {
		tfs::lua::pushThing(L, killer);
	} else {
		lua_pushnil(L);
	}

	return scriptInterface.callFunction(2);
}

void onDeath(const std::shared_ptr<Creature>& creature, const std::shared_ptr<Item>& corpse,
             const std::shared_ptr<Creature>& killer, const std::shared_ptr<Creature>& mostDamageKiller,
             bool lastHitUnjustified, bool mostDamageUnjustified)
{
	// Creature:onDeath(corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	if (creatureHandlers.onDeath == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onDeath] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onDeath, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onDeath);

	tfs::lua::pushThing(L, creature);
	tfs::lua::pushThing(L, corpse);

	if (killer) {
		tfs::lua::pushThing(L, killer);
	} else {
		lua_pushnil(L);
	}

	if (mostDamageKiller) {
		tfs::lua::pushThing(L, mostDamageKiller);
	} else {
		lua_pushnil(L);
	}

	tfs::lua::pushBoolean(L, lastHitUnjustified);
	tfs::lua::pushBoolean(L, mostDamageUnjustified);
	scriptInterface.callVoidFunction(6);
}

void onKill(const std::shared_ptr<Creature>& creature, const std::shared_ptr<Creature>& target)
{
	// Creature:onKill(target)
	if (creatureHandlers.onKill == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::creature::onKill] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(creatureHandlers.onKill, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(creatureHandlers.onKill);

	tfs::lua::pushThing(L, creature);
	tfs::lua::pushThing(L, target);
	scriptInterface.callVoidFunction(2);
}

} // namespace tfs::events::creature

namespace tfs::events::party {

bool onJoin(Party* party, const std::shared_ptr<Player>& player)
{
	// Party:onJoin(player) or Party.onJoin(self, player)
	if (partyHandlers.onJoin == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::party::onJoin] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(partyHandlers.onJoin, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(partyHandlers.onJoin);

	tfs::lua::pushParty(L, party);
	tfs::lua::pushThing(L, player);
	return scriptInterface.callFunction(2);
}

bool onLeave(Party* party, const std::shared_ptr<Player>& player)
{
	// Party:onLeave(player) or Party.onLeave(self, player)
	if (partyHandlers.onLeave == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::party::onLeave] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(partyHandlers.onLeave, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(partyHandlers.onLeave);

	tfs::lua::pushParty(L, party);
	tfs::lua::pushThing(L, player);
	return scriptInterface.callFunction(2);
}

bool onDisband(Party* party)
{
	// Party:onDisband() or Party.onDisband(self)
	if (partyHandlers.onDisband == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::party::onDisband] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(partyHandlers.onDisband, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(partyHandlers.onDisband);

	tfs::lua::pushParty(L, party);
	return scriptInterface.callFunction(1);
}

bool onInvite(Party* party, const std::shared_ptr<Player>& player)
{
	// Party:onInvite(player) or Party.onInvite(self, player)
	if (partyHandlers.onInvite == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::party::onInvite] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(partyHandlers.onInvite, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(partyHandlers.onInvite);

	tfs::lua::pushParty(L, party);
	tfs::lua::pushThing(L, player);
	return scriptInterface.callFunction(2);
}

bool onRevokeInvitation(Party* party, const std::shared_ptr<Player>& player)
{
	// Party:onRevokeInvitation(player) or Party.onRevokeInvitation(self, player)
	if (partyHandlers.onRevokeInvitation == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::party::onRevokeInvitation] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(partyHandlers.onRevokeInvitation, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(partyHandlers.onRevokeInvitation);

	tfs::lua::pushParty(L, party);
	tfs::lua::pushThing(L, player);
	return scriptInterface.callFunction(2);
}

bool onPassLeadership(Party* party, const std::shared_ptr<Player>& player)
{
	// Party:onPassLeadership(player) or Party.onPassLeadership(self, player)
	if (partyHandlers.onPassLeadership == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::party::onPassLeadership] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(partyHandlers.onPassLeadership, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(partyHandlers.onPassLeadership);

	tfs::lua::pushParty(L, party);
	tfs::lua::pushThing(L, player);
	return scriptInterface.callFunction(2);
}

void onShareExperience(Party* party, uint64_t& exp)
{
	// Party:onShareExperience(exp) or Party.onShareExperience(self, exp)
	if (partyHandlers.onShareExperience == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::party::onShareExperience] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(partyHandlers.onShareExperience, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(partyHandlers.onShareExperience);

	tfs::lua::pushParty(L, party);
	tfs::lua::pushNumber(L, exp);

	if (tfs::lua::protectedCall(L, 2, 1) != 0) {
		reportErrorFunc(L, tfs::lua::popString(L));
	} else {
		exp = tfs::lua::getNumber<uint64_t>(L, -1);
		lua_pop(L, 1);
	}

	tfs::lua::resetScriptEnv();
}

} // namespace tfs::events::party

namespace tfs::events::player {

bool onBrowseField(const std::shared_ptr<Player>& player, const Position& position)
{
	// Player:onBrowseField(position) or Player.onBrowseField(self, position)
	if (playerHandlers.onBrowseField == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onBrowseField] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onBrowseField, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onBrowseField);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushPosition(L, position);
	return scriptInterface.callFunction(2);
}

void onLook(const std::shared_ptr<Player>& player, const Position& position, const std::shared_ptr<Thing>& thing,
            uint8_t stackpos, int32_t lookDistance)
{
	// Player:onLook(thing, position, distance) or Player.onLook(self, thing, position, distance)
	if (playerHandlers.onLook == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onLook] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onLook, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onLook);

	tfs::lua::pushThing(L, player);

	if (const auto& creature = thing->asCreature()) {
		tfs::lua::pushThing(L, creature);
	} else if (const auto& item = thing->asItem()) {
		tfs::lua::pushSharedPtr(L, item);
		tfs::lua::setItemMetatable(L, -1, item);
	} else {
		lua_pushnil(L);
	}

	tfs::lua::pushPosition(L, position, stackpos);
	tfs::lua::pushNumber(L, lookDistance);
	scriptInterface.callVoidFunction(4);
}

void onLookInBattleList(const std::shared_ptr<Player>& player, const std::shared_ptr<Creature>& creature,
                        int32_t lookDistance)
{
	// Player:onLookInBattleList(creature, position, distance) or Player.onLookInBattleList(self, creature, position,
	// distance)
	if (playerHandlers.onLookInBattleList == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onLookInBattleList] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onLookInBattleList, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onLookInBattleList);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, creature);
	tfs::lua::pushNumber(L, lookDistance);
	scriptInterface.callVoidFunction(3);
}

void onLookInTrade(const std::shared_ptr<Player>& player, const std::shared_ptr<Player>& partner,
                   const std::shared_ptr<Item>& item, int32_t lookDistance)
{
	// Player:onLookInTrade(partner, item, distance) or Player.onLookInTrade(self, partner, item, distance)
	if (playerHandlers.onLookInTrade == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onLookInTrade] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onLookInTrade, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onLookInTrade);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, partner);
	tfs::lua::pushThing(L, item);
	tfs::lua::pushNumber(L, lookDistance);
	scriptInterface.callVoidFunction(4);
}

bool onLookInShop(const std::shared_ptr<Player>& player, const ItemType* itemType, uint8_t count)
{
	// Player:onLookInShop(itemType, count) or Player.onLookInShop(self, itemType, count)
	if (playerHandlers.onLookInShop == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onLookInShop] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onLookInShop, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onLookInShop);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushItemType(L, itemType);
	tfs::lua::pushNumber(L, count);
	return scriptInterface.callFunction(3);
}

bool onLookInMarket(const std::shared_ptr<Player>& player, const ItemType* itemType)
{
	// Player:onLookInMarket(itemType) or Player.onLookInMarket(self, itemType)
	if (playerHandlers.onLookInMarket == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onLookInMarket] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onLookInMarket, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onLookInMarket);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushItemType(L, itemType);
	return scriptInterface.callFunction(2);
}

ReturnValue onMoveItem(const std::shared_ptr<Player>& player, const std::shared_ptr<Item>& item, uint16_t count,
                       const Position& fromPosition, const Position& toPosition,
                       const std::shared_ptr<Thing>& fromThing, const std::shared_ptr<Thing>& toThing)
{
	// Player:onMoveItem(item, count, fromPosition, toPosition) or Player.onMoveItem(self, item, count, fromPosition,
	// toPosition, fromThing, toThing)
	if (playerHandlers.onMoveItem == -1) {
		return RETURNVALUE_NOERROR;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onMoveItem] Call stack overflow" << std::endl;
		return RETURNVALUE_NOTPOSSIBLE;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onMoveItem, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onMoveItem);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, item);
	tfs::lua::pushNumber(L, count);
	tfs::lua::pushPosition(L, fromPosition);
	tfs::lua::pushPosition(L, toPosition);
	tfs::lua::pushThing(L, fromThing);
	tfs::lua::pushThing(L, toThing);

	ReturnValue returnValue;
	if (tfs::lua::protectedCall(L, 7, 1) != 0) {
		returnValue = RETURNVALUE_NOTPOSSIBLE;
		reportErrorFunc(L, tfs::lua::popString(L));
	} else {
		returnValue = tfs::lua::getNumber<ReturnValue>(L, -1);
		lua_pop(L, 1);
	}

	tfs::lua::resetScriptEnv();
	return returnValue;
}

void onItemMoved(const std::shared_ptr<Player>& player, const std::shared_ptr<Item>& item, uint16_t count,
                 const Position& fromPosition, const Position& toPosition, const std::shared_ptr<Thing>& fromThing,
                 const std::shared_ptr<Thing>& toThing)
{
	// Player:onItemMoved(item, count, fromPosition, toPosition) or Player.onItemMoved(self, item, count, fromPosition,
	// toPosition, fromThing, toThing)
	if (playerHandlers.onItemMoved == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onItemMoved] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onItemMoved, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onItemMoved);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, item);
	tfs::lua::pushNumber(L, count);
	tfs::lua::pushPosition(L, fromPosition);
	tfs::lua::pushPosition(L, toPosition);
	tfs::lua::pushThing(L, fromThing);
	tfs::lua::pushThing(L, toThing);
	scriptInterface.callVoidFunction(7);
}

bool onMoveCreature(const std::shared_ptr<Player>& player, const std::shared_ptr<Creature>& creature,
                    const Position& fromPosition, const Position& toPosition)
{
	// Player:onMoveCreature(creature, fromPosition, toPosition) or Player.onMoveCreature(self, creature, fromPosition,
	// toPosition)
	if (playerHandlers.onMoveCreature == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onMoveCreature] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onMoveCreature, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onMoveCreature);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, creature);
	tfs::lua::pushPosition(L, fromPosition);
	tfs::lua::pushPosition(L, toPosition);
	return scriptInterface.callFunction(4);
}

void onReportRuleViolation(const std::shared_ptr<Player>& player, const std::string& targetName, uint8_t reportType,
                           uint8_t reportReason, const std::string& comment, const std::string& translation)
{
	// Player:onReportRuleViolation(targetName, reportType, reportReason, comment, translation)
	if (playerHandlers.onReportRuleViolation == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onReportRuleViolation] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onReportRuleViolation, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onReportRuleViolation);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushString(L, targetName);
	tfs::lua::pushNumber(L, reportType);
	tfs::lua::pushNumber(L, reportReason);
	tfs::lua::pushString(L, comment);
	tfs::lua::pushString(L, translation);
	scriptInterface.callVoidFunction(6);
}

bool onReportBug(const std::shared_ptr<Player>& player, const std::string& message, const Position& position,
                 uint8_t category)
{
	// Player:onReportBug(message, position, category)
	if (playerHandlers.onReportBug == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onReportBug] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onReportBug, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onReportBug);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushString(L, message);
	tfs::lua::pushPosition(L, position);
	tfs::lua::pushNumber(L, category);
	return scriptInterface.callFunction(4);
}

void onRotateItem(const std::shared_ptr<Player>& player, const std::shared_ptr<Item>& item)
{
	// Player:onRotateItem(item)
	if (playerHandlers.onRotateItem == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onRotateItem] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onRotateItem, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onRotateItem);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, item);
	scriptInterface.callVoidFunction(2);
}

bool onTurn(const std::shared_ptr<Player>& player, Direction direction)
{
	// Player:onTurn(direction) or Player.onTurn(self, direction)
	if (playerHandlers.onTurn == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onTurn] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onTurn, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onTurn);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushNumber(L, direction);
	return scriptInterface.callFunction(2);
}

bool onTradeRequest(const std::shared_ptr<Player>& player, const std::shared_ptr<Player>& target,
                    const std::shared_ptr<Item>& item)
{
	// Player:onTradeRequest(target, item)
	if (playerHandlers.onTradeRequest == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onTradeRequest] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onTradeRequest, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onTradeRequest);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, target);
	tfs::lua::pushThing(L, item);
	return scriptInterface.callFunction(3);
}

bool onTradeAccept(const std::shared_ptr<Player>& player, const std::shared_ptr<Player>& target,
                   const std::shared_ptr<Item>& item, const std::shared_ptr<Item>& targetItem)
{
	// Player:onTradeAccept(target, item, targetItem)
	if (playerHandlers.onTradeAccept == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onTradeAccept] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onTradeAccept, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onTradeAccept);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, target);
	tfs::lua::pushThing(L, item);
	tfs::lua::pushThing(L, targetItem);
	return scriptInterface.callFunction(4);
}

void onTradeCompleted(const std::shared_ptr<Player>& player, const std::shared_ptr<Player>& target,
                      const std::shared_ptr<Item>& item, const std::shared_ptr<Item>& targetItem, bool isSuccess)
{
	// Player:onTradeCompleted(target, item, targetItem, isSuccess)
	if (playerHandlers.onTradeCompleted == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onTradeCompleted] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onTradeCompleted, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onTradeCompleted);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, target);
	tfs::lua::pushThing(L, item);
	tfs::lua::pushThing(L, targetItem);
	tfs::lua::pushBoolean(L, isSuccess);
	scriptInterface.callFunction(5);
}

void onPodiumRequest(const std::shared_ptr<Player>& player, const std::shared_ptr<Item>& item)
{
	// Player:onPodiumRequest(item) or Player.onPodiumRequest(self, item)
	if (playerHandlers.onPodiumRequest == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onPodiumRequest] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onPodiumRequest, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onPodiumRequest);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, item);
	scriptInterface.callVoidFunction(2);
}

void onPodiumEdit(const std::shared_ptr<Player>& player, const std::shared_ptr<Item>& item, const Outfit_t& outfit,
                  bool podiumVisible, Direction direction)
{
	// Player:onPodiumEdit(item, outfit, direction, isVisible) or Player.onPodiumEdit(self, item, outfit, direction,
	// isVisible)
	if (playerHandlers.onPodiumEdit == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onPodiumEdit] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onPodiumEdit, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onPodiumEdit);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, item);
	tfs::lua::pushOutfit(L, outfit);
	tfs::lua::pushNumber(L, direction);
	tfs::lua::pushBoolean(L, podiumVisible);
	scriptInterface.callVoidFunction(5);
}

void onGainExperience(const std::shared_ptr<Player>& player, const std::shared_ptr<Creature>& source, uint64_t& exp,
                      uint64_t rawExp, bool sendText)
{
	// Player:onGainExperience(source, exp, rawExp, sendText) rawExp gives the original exp which is not multiplied
	if (playerHandlers.onGainExperience == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onGainExperience] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onGainExperience, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onGainExperience);

	tfs::lua::pushThing(L, player);

	if (source) {
		tfs::lua::pushThing(L, source);
	} else {
		lua_pushnil(L);
	}

	tfs::lua::pushNumber(L, exp);
	tfs::lua::pushNumber(L, rawExp);
	tfs::lua::pushBoolean(L, sendText);

	if (tfs::lua::protectedCall(L, 5, 1) != 0) {
		reportErrorFunc(L, tfs::lua::popString(L));
	} else {
		exp = tfs::lua::getNumber<uint64_t>(L, -1);
		lua_pop(L, 1);
	}

	tfs::lua::resetScriptEnv();
}

void onLoseExperience(const std::shared_ptr<Player>& player, uint64_t& exp)
{
	// Player:onLoseExperience(exp)
	if (playerHandlers.onLoseExperience == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onLoseExperience] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onLoseExperience, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onLoseExperience);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushNumber(L, exp);

	if (tfs::lua::protectedCall(L, 2, 1) != 0) {
		reportErrorFunc(L, tfs::lua::popString(L));
	} else {
		exp = tfs::lua::getNumber<uint64_t>(L, -1, exp);
		lua_pop(L, 1);
	}

	tfs::lua::resetScriptEnv();
}

void onGainSkillTries(const std::shared_ptr<Player>& player, skills_t skill, uint64_t& tries)
{
	// Player:onGainSkillTries(skill, tries)
	if (playerHandlers.onGainSkillTries == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onGainSkillTries] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onGainSkillTries, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onGainSkillTries);

	tfs::lua::pushThing(L, player);

	tfs::lua::pushNumber(L, skill);
	tfs::lua::pushNumber(L, tries);

	if (tfs::lua::protectedCall(L, 3, 1) != 0) {
		reportErrorFunc(L, tfs::lua::popString(L));
	} else {
		tries = tfs::lua::getNumber<uint64_t>(L, -1, tries);
		lua_pop(L, 1);
	}

	tfs::lua::resetScriptEnv();
}

void onWrapItem(const std::shared_ptr<Player>& player, const std::shared_ptr<Item>& item)
{
	// Player:onWrapItem(item)
	if (playerHandlers.onWrapItem == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onWrapItem] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onWrapItem, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onWrapItem);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, item);
	scriptInterface.callVoidFunction(2);
}

void onInventoryUpdate(const std::shared_ptr<Player>& player, const std::shared_ptr<Item>& item, slots_t slot,
                       bool equip)
{
	// Player:onInventoryUpdate(item, slot, equip)
	if (playerHandlers.onInventoryUpdate == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onInventoryUpdate] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onInventoryUpdate, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onInventoryUpdate);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, item);
	tfs::lua::pushNumber(L, slot);
	tfs::lua::pushBoolean(L, equip);
	scriptInterface.callVoidFunction(4);
}

void onNetworkMessage(const std::shared_ptr<Player>& player, uint8_t recvByte, NetworkMessage_ptr& msg)
{
	// Player:onNetworkMessage(recvByte, msg)
	if (playerHandlers.onNetworkMessage == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onNetworkMessage] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onNetworkMessage, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onNetworkMessage);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushNumber(L, recvByte);
	tfs::lua::pushNetworkMessage(L, msg.release());
	scriptInterface.callVoidFunction(3);
}

bool onSpellCheck(const std::shared_ptr<Player>& player, const Spell* spell)
{
	// Player:onSpellCheck(spell)
	if (playerHandlers.onSpellCheck == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onSpellCheck] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onSpellCheck, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onSpellCheck);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushSpell(L, *spell);
	return scriptInterface.callFunction(2);
}

bool onLogin(const std::shared_ptr<Player>& player)
{
	// Player:onLogin()
	if (playerHandlers.onLogin == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onLogin] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onLogin, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onLogin);

	tfs::lua::pushThing(L, player);
	return scriptInterface.callFunction(1);
}

void onJoin(const std::shared_ptr<Player>& player)
{
	// Player:onJoin()
	if (playerHandlers.onJoin == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onJoin] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onJoin, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onJoin);

	tfs::lua::pushThing(L, player);
	scriptInterface.callVoidFunction(1);
}

bool onLogout(const std::shared_ptr<Player>& player)
{
	// Player:onLogout()
	if (playerHandlers.onLogout == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::Logout] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onLogout, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onLogout);

	tfs::lua::pushThing(L, player);
	return scriptInterface.callFunction(1);
}

void onReconnect(const std::shared_ptr<Player>& player)
{
	// Player:onReconnect()
	if (playerHandlers.onReconnect == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onReconnect] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onReconnect, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onReconnect);

	tfs::lua::pushThing(L, player);
	scriptInterface.callVoidFunction(1);
}

bool onAdvance(const std::shared_ptr<Player>& player, skills_t skill, uint32_t oldLevel, uint32_t newLevel)
{
	// Player:onLogout(skill, oldLevel, newLevel)
	if (playerHandlers.onLogout == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::Logout] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onLogout, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onLogout);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushNumber(L, static_cast<uint32_t>(skill));
	tfs::lua::pushNumber(L, oldLevel);
	tfs::lua::pushNumber(L, newLevel);
	return scriptInterface.callFunction(4);
}

void onModalWindow(const std::shared_ptr<Player>& player, uint32_t modalWindowId, uint8_t buttonId, uint8_t choiceId)
{
	// Player:onModalWindow(modalWindowId, buttonId, choiceId)
	if (playerHandlers.onModalWindow == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::ModalWindow] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onModalWindow, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onModalWindow);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushNumber(L, modalWindowId);
	tfs::lua::pushNumber(L, buttonId);
	tfs::lua::pushNumber(L, choiceId);
	scriptInterface.callVoidFunction(4);
}

bool onTextEdit(const std::shared_ptr<Player>& player, const std::shared_ptr<Item>& item, std::string_view text,
                const uint32_t windowTextId)
{
	// Player:onModalWindow(item, text, windowTextId)
	if (playerHandlers.onModalWindow == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onModalWindow] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onModalWindow, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onModalWindow);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushThing(L, item);
	tfs::lua::pushString(L, text);
	tfs::lua::pushNumber(L, windowTextId);
	return scriptInterface.callFunction(4);
}

void onExtendedOpcode(const std::shared_ptr<Player>& player, uint8_t opcode, std::string_view buffer)
{
	// Player:onExtendedOpcode(opcode, buffer)
	if (playerHandlers.onExtendedOpcode == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::player::onExtendedOpcode] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(playerHandlers.onExtendedOpcode, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(playerHandlers.onExtendedOpcode);

	tfs::lua::pushThing(L, player);
	tfs::lua::pushNumber(L, opcode);
	tfs::lua::pushString(L, buffer);
	scriptInterface.callVoidFunction(3);
}

} // namespace tfs::events::player

namespace tfs::events::monster {

bool onSpawn(const std::shared_ptr<Monster>& monster, const Position& position, bool startup, bool artificial)
{
	// Monster:onSpawn(position, startup, artificial)
	if (monsterHandlers.onSpawn == -1) {
		return true;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::monster:onSpawn] Call stack overflow" << std::endl;
		return false;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(monsterHandlers.onSpawn, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(monsterHandlers.onSpawn);

	tfs::lua::pushThing(L, monster);
	tfs::lua::pushPosition(L, position);
	tfs::lua::pushBoolean(L, startup);
	tfs::lua::pushBoolean(L, artificial);
	return scriptInterface.callFunction(4);
}

void onDropLoot(const std::shared_ptr<Monster>& monster, const std::shared_ptr<Container>& corpse)
{
	// Monster:onDropLoot(corpse)
	if (monsterHandlers.onDropLoot == -1) {
		return;
	}

	if (!tfs::lua::reserveScriptEnv()) {
		std::cout << "[Error - tfs::events::monsteronDropLoot] Call stack overflow" << std::endl;
		return;
	}

	const auto env = tfs::lua::getScriptEnv();
	env->setScriptId(monsterHandlers.onDropLoot, &scriptInterface);

	const auto L = scriptInterface.getLuaState();
	scriptInterface.pushFunction(monsterHandlers.onDropLoot);

	tfs::lua::pushThing(L, monster);

	if (corpse) {
		tfs::lua::pushThing(L, corpse);
	} else {
		lua_pushnil(L);
	}

	scriptInterface.callVoidFunction(2);
}

} // namespace tfs::events::monster
