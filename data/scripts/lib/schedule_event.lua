ScheduleEvent = {}
ScheduleEvent.__index = ScheduleEvent

function ScheduleEvent.new(time)
	local self = setmetatable({}, ScheduleEvent)
	self.time = time
	self.callback = nil
	self._lastTrigger = {}
	return self
end

setmetatable(ScheduleEvent, {
	__call = function(_, time)
		return ScheduleEvent.new(time)
	end
})

function ScheduleEvent:__newindex(key, value)
	if key == "onTrigger" then
		if type(value) ~= "function" then
			print("[Warning - ScheduleEvent] onTrigger must be a function")
			return
		end
		rawset(self, "callback", value)
	else
		rawset(self, key, value)
	end
end

local function parseTime(str)
	local h, m, s = str:match("^(%d%d):(%d%d):(%d%d)$")
	if not h then
		return nil
	end

	h, m, s = tonumber(h), tonumber(m), tonumber(s)
	if h > 23 or m > 59 or s > 59 then
		return nil
	end
	return h, m, s
end

function ScheduleEvent:register()
	if not self.callback then
		print("[Warning - ScheduleEvent] onTrigger not defined")
		return false
	end

	--[[
		local event = ScheduleEvent(30000)
		event.onTrigger = function() end
		event:register()
	]]
	if type(self.time) == "number" then
		if self.time < SCHEDULER_MINTICKS then
			print("[Warning - ScheduleEvent] Interval must be >= ".. SCHEDULER_MINTICKS .."ms")
			return false
		end

		local function loop()
			local success, err = pcall(self.callback)
			if not success then
				print("[Error - ScheduleEvent] Callback failed: " .. tostring(err))
			end
			addEvent(loop, self.time)
		end

		addEvent(loop, self.time)
		return true
	end

	--[[
		local event = ScheduleEvent("10:30:00")
		event.onTrigger = function() end
		event:register()
	]]
	if type(self.time) == "string" then
		local h, m, s = parseTime(self.time)
		if not h then
			print("[Warning - ScheduleEvent] Invalid time format, expected HH:MM:SS")
			return false
		end

		local function check()
			local now = os.date("*t")
			-- Clean up old entries (keep only today's stamps)
			for stamp in pairs(self._lastTrigger) do
				local stampDay = tonumber(stamp:match("^(%d+)%-"))
				if stampDay and stampDay ~= now.yday then
					self._lastTrigger[stamp] = nil
				end
			end
			
			local stamp = now.yday .. "-" .. h .. "-" .. m .. "-" .. s

			if now.hour == h and now.min == m and now.sec == s and not self._lastTrigger[stamp] then
				self._lastTrigger[stamp] = true
				local success, err = pcall(self.callback)
				if not success then
					print("[Error - ScheduleEvent] Callback failed: " .. tostring(err))
				end
			end

			addEvent(check, 1000)
		end

		addEvent(check, 1000)
		return true
	end

	--[[
		local event = ScheduleEvent({
			[SUNDAY] = {"10:00:00", "23:00:00"},
			[FRIDAY] = 30000
		})

		event.onTrigger = function() end
		event:register()
	]]
	if type(self.time) == "table" then
		local dayTimes = {}
		local dayIntervals = {}

		for day, value in pairs(self.time) do
			if type(day) ~= "number" or day < SUNDAY or day > SATURDAY then
				print("[Warning - ScheduleEvent] Invalid weekday: " .. tostring(day))
				return false
			end

			if type(value) == "table" then
				dayTimes[day] = {}
				for _, timeStr in ipairs(value) do
					local h, m, s = parseTime(timeStr)
					if not h then
						print("[Warning - ScheduleEvent] Invalid time: " .. tostring(timeStr))
						return false
					end
					table.insert(dayTimes[day], { h, m, s })
				end
			elseif type(value) == "number" then
				if value < SCHEDULER_MINTICKS then
					print("[Warning - ScheduleEvent] Interval must be >= " .. SCHEDULER_MINTICKS .. "ms")
					return false
				end
				dayIntervals[day] = value
			else
				print("[Warning - ScheduleEvent] Invalid value for weekday " .. day)
				return false
			end
		end

		local function checkTimes()
			local now = os.date("*t")
			-- Clean up old entries (keep only today's stamps)
			for stamp in pairs(self._lastTrigger) do
				local stampDay = tonumber(stamp:match("^(%d+)%-"))
				if stampDay and stampDay ~= now.yday then
					self._lastTrigger[stamp] = nil
				end
			end

			local today = dayTimes[now.wday]
			if today then
				for _, t in ipairs(today) do
					local stamp = now.yday .. "-" .. t[1] .. "-" .. t[2] .. "-" .. t[3]
					if now.hour == t[1] and now.min == t[2] and now.sec == t[3] and not self._lastTrigger[stamp] then
						self._lastTrigger[stamp] = true
						local success, err = pcall(self.callback)
						if not success then
							print("[Error - ScheduleEvent] Callback failed: " .. tostring(err))
						end
					end
				end
			end

			addEvent(checkTimes, 1000)
		end

		addEvent(checkTimes, 1000)

		for dayIndex, interval in pairs(dayIntervals) do
			local function loop()
				if os.date("*t").wday == dayIndex then
					local success, err = pcall(self.callback)
					if not success then
						print("[Error - ScheduleEvent] Callback failed: " .. tostring(err))
					end
				end
				addEvent(loop, interval)
			end

			addEvent(loop, interval)
		end

		return true
	end

	print("[Warning - ScheduleEvent] Invalid time type")
	return false
end
