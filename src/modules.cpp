// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "modules.h"

#include "luascript.h"

namespace fs = std::filesystem;

namespace {

LuaScriptInterface lsi("Modules Interface");

void load_libs()
{
	const auto dir = fs::current_path() / "modules";
	if (!fs::exists(dir) || !fs::is_directory(dir)) {
		return;
	}

	std::vector<fs::path> files;

	for (fs::recursive_directory_iterator it(dir), end; it != end; ++it) {
		if (!fs::is_regular_file(*it)) {
			continue;
		}

		const auto& path = it->path();
		if (path.extension() == ".lua") {
			for (const auto& part : path) {
				if (part == "lib") {
					files.push_back(path);
				}
			}
		}
	}

	std::sort(files.begin(), files.end());

	for (const auto& file : files) {
		if (lsi.loadFile(file.string()) == -1) {
			std::cout << "> " << file.filename().string() << " [error]" << std::endl;
			std::cout << "^ " << lsi.getLastLuaError() << std::endl;
			continue;
		}

		std::cout << "> " << file.filename().string() << " [lib loaded]" << std::endl;
	}
}

void load_scripts()
{
	const auto dir = fs::current_path() / "modules";
	if (!fs::exists(dir) || !fs::is_directory(dir)) {
		return;
	}

	std::vector<fs::path> files;
	const std::string disable = "#";

	for (fs::recursive_directory_iterator it(dir), end; it != end; ++it) {
		if (!fs::is_regular_file(*it)) {
			continue;
		}

		const auto& path = it->path();
		for (const auto& part : path) {
			if (part == "lib") {
				continue;
			}
		}

		if (path.extension() != ".lua") {
			continue;
		}

		if (path.filename().string().find(disable) != std::string::npos) {
			std::cout << "> " << path.filename().string() << " [disabled]" << std::endl;
			continue;
		}

		files.push_back(path);
	}

	std::sort(files.begin(), files.end());

	std::string lastModule;
	for (const auto& file : files) {
		auto moduleName = file.parent_path().filename().string();
		if (lastModule != moduleName) {
			std::cout << ">> [" << moduleName << "]" << std::endl;
			lastModule = moduleName;
		}

		if (lsi.loadFile(file.string()) == -1) {
			std::cout << "> " << file.filename().string() << " [error]" << std::endl;
			std::cout << "^ " << lsi.getLastLuaError() << std::endl;
			continue;
		}

		std::cout << "> " << file.filename().string() << " [loaded]" << std::endl;
	}
}

} // namespace

bool tfs::lua::modules::load()
{
	if (!lsi.initState()) {
		return false;
	}

	load_libs();
	load_scripts();
	return true;
}

bool tfs::lua::modules::reload()
{
	if (!lsi.reInitState()) {
		return false;
	}

	load_libs();
	load_scripts();
	return true;
}
