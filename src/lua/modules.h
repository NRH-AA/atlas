#pragma once

#include "script.h"

namespace tfs::lua::modules {

void import(LuaScriptInterface& lsi);
bool load();
bool reload();

} // namespace tfs::lua::modules
