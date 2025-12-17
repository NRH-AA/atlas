local LOST_CONNECTION_MILLIS = 5000
local REMOVE_TARGET_PLAYER_MILLIS = 7000
local PZ_LOCKED_NO_PONG_KICK_MILLIS = 60000

local event = Event()

event.onCreatureThink = function(self, interval)
	if not self:isPlayer() then
		return
	end

    local timeNow = os.mtime()

    local hasLostConnection = false
    if timeNow - self:getLastPing() >= LOST_CONNECTION_MILLIS then
        self:setLastPing(timeNow)
        if self:getClient() then
            local msg = NetworkMessage()
            msg:addByte(0x1D)
            msg:sendToPlayer(self)
            msg:delete()
        else
            hasLostConnection = true
        end
    end

    local noPongTime = timeNow - self:getLastPong()
    if hasLostConnection or noPongTime >= REMOVE_TARGET_PLAYER_MILLIS then
        local target = self:getTarget()
        if target and target:isPlayer() then
            self:setTarget(nil)
        end
    end

    local noPongKickTime = self:getVocation():getNoPongKickTime()
    if self:isPzLocked() and noPongKickTime < PZ_LOCKED_NO_PONG_KICK_MILLIS then
        noPongKickTime = PZ_LOCKED_NO_PONG_KICK_MILLIS
    end

    if noPongTime >= noPongKickTime then
        if self:getTile():hasFlag(TILESTATE_NOLOGOUT) then
            return true
        end

        self:remove()
    end
    return true
end

event:register()
