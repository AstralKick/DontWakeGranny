--!strict
-- EventService (Match)
-- Rolls at most one random event per night (Config/EventConfig) and exposes its effects.
-- Never the same event twice in a row; milestone nights have EventChance 0 in NightConfig.

local EventConfig = shared("EventConfig")
local NightConfig = shared("NightConfig")

local EventService = {}

local current: string? = nil
local last: string? = nil
local rng = Random.new()

function EventService:Roll(n: number): string?
	local cfg = NightConfig.Get(n)
	current = nil
	-- Studio override for testing a specific event.
	local forced = workspace:GetAttribute("DebugEvent")
	if typeof(forced) == "string" and EventConfig[forced] then
		current = forced
		return current
	end
	if rng:NextNumber() >= cfg.EventChance then
		return nil
	end
	local pool, total = {}, 0
	for key, def in EventConfig do
		if n >= def.MinNight and key ~= last then
			table.insert(pool, key)
			total += def.Weight
		end
	end
	table.sort(pool)
	local r = rng:NextNumber() * total
	for _, key in pool do
		r -= EventConfig[key].Weight
		if r <= 0 then
			current = key
			break
		end
	end
	last = current
	return current
end

function EventService:GetKey(): string?
	return current
end

function EventService:Get(): any
	return current and EventConfig[current]
end

function EventService:Has(flag: string): boolean
	local def = EventService:Get()
	return def ~= nil and def[flag] ~= nil and def[flag] ~= false
end

local function num(flag: string): number
	local def = EventService:Get()
	return if def and typeof(def[flag]) == "number" then def[flag] else 1
end

function EventService:HearingMult(): number
	return num("HearingMult")
end
function EventService:SpeedMult(): number
	return num("SpeedMult")
end
function EventService:LootMult(): number
	return num("LootMult")
end
function EventService:LootCountMult(): number
	return num("LootCountMult")
end

function EventService.Preload() end
function EventService:Start() end

return EventService
