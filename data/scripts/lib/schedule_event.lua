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
	if not h then return nil end
	h, m, s = tonumber(h), tonumber(m), tonumber(s)
	if h > 23 or m > 59 or s > 59 then return nil end
	return h, m, s
end

local function safeCall(callback)
	local success, err = pcall(callback)
	if not success then
		print("[Error - ScheduleEvent] Callback failed: " .. tostring(err))
	end
end

function ScheduleEvent:scheduleInterval(interval)
	if interval < SCHEDULER_MINTICKS then
		print("[Warning - ScheduleEvent] Interval must be >= " .. SCHEDULER_MINTICKS .. "ms")
		return false
	end

	local function loop()
		safeCall(self.callback)
		addEvent(loop, interval)
	end

	addEvent(loop, interval)
	return true
end

function ScheduleEvent:scheduleTime(h, m, s)
	local function check()
		local now = os.date("*t")
		if not self._lastYear or self._lastYear ~= now.year then
			self._lastTrigger = {}
			self._lastYear = now.year
		end

		for stamp in pairs(self._lastTrigger) do
			local stampYear, stampDay = stamp:match("^(%d+)%-(%d+)%-")
			stampYear, stampDay = tonumber(stampYear), tonumber(stampDay)
			if stampYear ~= now.year or stampDay ~= now.yday then
				self._lastTrigger[stamp] = nil
			end
		end

		local stamp = now.year .. "-" .. now.yday .. "-" .. h .. "-" .. m .. "-" .. s
		if now.hour == h and now.min == m and now.sec == s and not self._lastTrigger[stamp] then
			self._lastTrigger[stamp] = true
			safeCall(self.callback)
		end

		addEvent(check, 1000)
	end

	addEvent(check, 1000)
	return true
end

function ScheduleEvent:scheduleDays(dayTimes, dayIntervals)
	for day, times in pairs(dayTimes) do
		local function checkTimes()
			local now = os.date("*t")
			if now.wday ~= day then
				addEvent(checkTimes, 1000)
				return
			end
			for _, t in ipairs(times) do
				local h, m, s = t[1], t[2], t[3]
				local stamp = now.yday .. "-" .. h .. "-" .. m .. "-" .. s
				if now.hour == h and now.min == m and now.sec == s and not self._lastTrigger[stamp] then
					self._lastTrigger[stamp] = true
					safeCall(self.callback)
				end
			end
			addEvent(checkTimes, 1000)
		end
		addEvent(checkTimes, 1000)
	end

	for day, interval in pairs(dayIntervals) do
		local function loop()
			if os.date("*t").wday == day then
				safeCall(self.callback)
			end
			addEvent(loop, interval)
		end

		local function scheduleInitial()
			if os.date("*t").wday == day then
				addEvent(loop, interval)
			else
				addEvent(scheduleInitial, interval)
			end
		end

		scheduleInitial()
	end

	return true
end

function ScheduleEvent:register()
	if not self.callback then
		print("[Warning - ScheduleEvent] onTrigger not defined")
		return false
	end

	if type(self.time) == "number" then
		return self:scheduleInterval(self.time)
	elseif type(self.time) == "string" then
		local h, m, s = parseTime(self.time)
		if not h then
			print("[Warning - ScheduleEvent] Invalid time format, expected HH:MM:SS")
			return false
		end

		return self:scheduleTime(h, m, s)
	elseif type(self.time) == "table" then
		local dayTimes, dayIntervals = {}, {}
		for day, value in pairs(self.time) do
			if type(value) == "table" then
				dayTimes[day] = {}
				for _, t in ipairs(value) do
					local h, m, s = parseTime(t)
					if not h then
						print("[Warning - ScheduleEvent] Invalid time: " .. tostring(t))
						return false
					end
					table.insert(dayTimes[day], {h, m, s})
				end
			elseif type(value) == "number" then
				dayIntervals[day] = value
			else
				print("[Warning - ScheduleEvent] Invalid value for weekday " .. day)
				return false
			end
		end
		return self:scheduleDays(dayTimes, dayIntervals)
	end

	print("[Warning - ScheduleEvent] Invalid time type")
	return false
end
