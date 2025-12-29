#include "../otpch.h"

#include "modules.h"

#include "register.h"

namespace fs = std::filesystem;

namespace {

struct Module
{
	std::string name;
	bool isLib;
	bool enabled;
	fs::path path;
};

LuaScriptInterface lsi("Modules Interface");

std::vector<Module> get_modules()
{
	const auto dir = fs::current_path() / "modules";
	if (!fs::exists(dir) || !fs::is_directory(dir)) {
		return {};
	}

	std::vector<Module> modules;

	for (fs::recursive_directory_iterator it(dir), end; it != end; ++it) {
		if (!fs::is_regular_file(*it)) {
			continue;
		}

		const auto& path = it->path();
		if (path.extension() != ".lua") {
			continue;
		}

		const auto relative = fs::relative(path, dir);
		if (relative.empty()) {
			continue;
		}

		const auto itPart = relative.begin();
		const auto name = itPart->string();
		const auto enabled = path.filename().string().find("#") == std::string::npos;

		auto isLib = false;
		for (const auto& part : relative) {
			if (part == "lib") {
				isLib = true;
				break;
			}
		}

		modules.push_back({name, isLib, enabled, path});
	}

	std::sort(modules.begin(), modules.end(), [](const auto& a, const auto& b) {
		if (a.name != b.name) {
			return a.name < b.name;
		}

		if (a.isLib != b.isLib) {
			return a.isLib;
		}
		return a.path < b.path;
	});

	return modules;
}

} // namespace

namespace tfs::lua::modules {

void import(LuaScriptInterface& lsi)
{
	registerStdLib(lsi);
	registerGlobals(lsi);
	registerConfigManager(lsi);
	registerDatabase(lsi);
	registerAction(lsi);
	registerCombat(lsi);
	registerCondition(lsi);
	registerThing(lsi);

	registerCreature(lsi);
	registerMonster(lsi); // requires creature
	registerNpc(lsi);     // requires creature
	registerPlayer(lsi);  // requires creature

	registerGame(lsi);
	registerGlobalEvent(lsi);
	registerGroup(lsi);
	registerGuild(lsi);
	registerHouse(lsi);

	registerItem(lsi);
	registerContainer(lsi); // requires item
	registerPodium(lsi);    // requires item
	registerTeleport(lsi);  // requires item

	registerItemType(lsi);
	registerModalWindow(lsi);
	registerMonsters(lsi);
	registerMoveEvent(lsi);
	registerNetworkMessage(lsi);
	registerOutfit(lsi);
	registerParty(lsi);
	registerPosition(lsi);
	registerSpell(lsi);
	registerTalkAction(lsi);
	registerTile(lsi);
	registerVariant(lsi);
	registerVocation(lsi);
	registerWeapon(lsi);
	registerXml(lsi);
}

bool load()
{
	std::cout << ">> Loading modules" << std::endl;

	if (!lsi.initState()) {
		return false;
	}

	std::string currentModule;
	for (const auto module : get_modules()) {
		if (currentModule != module.name) {
			std::cout << ">> [" << module.name << "]" << std::endl;
			currentModule = module.name;
		}

		const auto fileName = module.path.filename().string();
		if (lsi.loadFile(module.path.string()) == -1) {
			if (module.isLib) {
				std::cout << "> " << fileName << " [lib error]" << std::endl;
			} else {
				std::cout << "> " << fileName << " [script error]" << std::endl;
			}

			std::cout << "^ " << lsi.getLastLuaError() << std::endl;
			continue;
		}

		if (module.isLib) {
			std::cout << "> " << fileName << " [lib loaded]" << std::endl;
		} else {
			std::cout << "> " << fileName << " [script loaded]" << std::endl;
		}
	}

	return true;
}

bool reload()
{
	std::cout << ">> Reloading modules" << std::endl;

	if (!lsi.reInitState()) {
		return false;
	}

	std::string currentModule;
	for (const auto module : get_modules()) {
		if (module.isLib) {
			continue;
		}

		if (currentModule != module.name) {
			std::cout << ">> [" << module.name << "]" << std::endl;
			currentModule = module.name;
		}

		const auto fileName = module.path.filename().string();
		if (lsi.loadFile(module.path.string()) == -1) {
			std::cout << "> " << fileName << " [script error]" << std::endl;
			std::cout << "^ " << lsi.getLastLuaError() << std::endl;
			continue;
		}

		std::cout << "> " << fileName << " [script reloaded]" << std::endl;
	}

	return true;
}

} // namespace tfs::lua::modules
