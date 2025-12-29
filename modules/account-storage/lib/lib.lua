do
	local storages = {}

	function Game.getAccountsStorage() return storages end

	function Game.clearAccountStorageValue(accountId, key)
		local accountStorage = storages[accountId]
		if accountStorage then
			accountStorage[key] = nil
		end
	end

	function Game.getAccountStorageValue(accountId, key)
		local accountStorage = storages[accountId]
		return accountStorage and accountStorage[key] or nil
	end

	function Game.setAccountStorageValue(accountId, key, value)
		if not storages[accountId] then
			storages[accountId] = {}
		end
		storages[accountId][key] = value
	end
end
