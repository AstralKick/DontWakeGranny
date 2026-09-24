--!strict
-- MapConfig
-- The run is split into CHAPTERS, one map each. Every chapter start is a checkpoint the
-- party leader can pick in Mom's car (replay any chapter you've reached).
--
-- Each map is a Model with the same structure as the original house (docs/MAP_CONTRACT.md):
-- PlayerSpawns, MomsCar (Trunk), Rooms, LootSpawns, PrizeSpawns, SearchNodes,
-- GrandmaSleepSpot, Barriers, FuseBox, tags (Door, HidingSpot, Searchable, Creaky, Breakable,
-- Lamp) ... In Studio the maps live in Workspace (House) and Workspace.Maps/<MapId>;
-- MapService moves the inactive ones to ServerStorage at runtime and names the active one
-- "House" in Workspace so every system finds it.
--
-- Areas inside a map are still called Ground / Upstairs / Basement / Attic (contract names);
-- AreaUnlock says on which night OF THE CHAPTER each opens, AreaNames what players see.

local MapConfig = {}

MapConfig.Chapters = {
	{
		MapId = "GrandmasHouse", Name = "Grandma's House",  Short = "House", FirstNight = 1, LastNight = 5,
		Tagline = "She's just napping.",
		AreaUnlock = { Upstairs = 3, Basement = 4, Attic = 5 },
		AreaNames = { Upstairs = "UPSTAIRS", Basement = "THE BASEMENT", Attic = "THE ATTIC" },
		Lighting = "House",
	},
	{
		MapId = "BackGarden", Name = "The Back Garden", Short = "Garden", FirstNight = 6, LastNight = 10,
		Tagline = "She sleeps on the porch now.",
		AreaUnlock = { Upstairs = 2, Basement = 3, Attic = 4 },
		AreaNames = { Upstairs = "THE GREENHOUSE", Basement = "THE POTTING SHED", Attic = "THE HEDGE MAZE" },
		Lighting = "Garden",
	},
	{
		MapId = "SunnyPines", Name = "Sunny Pines Retirement Home", Short = "Pines", FirstNight = 11, LastNight = 15,
		Tagline = "Visiting hours are over.",
		AreaUnlock = { Upstairs = 2, Basement = 3, Attic = 4 },
		AreaNames = { Upstairs = "THE RESIDENTS' WING", Basement = "THE BOILER ROOM", Attic = "MATRON'S WARD" },
		Lighting = "Institution",
	},
	{
		MapId = "StMildreds", Name = "St. Mildred's Chapel", Short = "Chapel", FirstNight = 16, LastNight = 20,
		Tagline = "She prays for company.",
		AreaUnlock = { Upstairs = 2, Basement = 3, Attic = 4 },
		AreaNames = { Upstairs = "THE BELL TOWER", Basement = "THE CRYPT", Attic = "THE GRAVEYARD" },
		Lighting = "Chapel",
	},
	{
		MapId = "HarvestFair", Name = "The Harvest Fair", Short = "Fair", FirstNight = 21, LastNight = 25,
		Tagline = "Everyone's having fun. Forever.",
		AreaUnlock = { Upstairs = 2, Basement = 3, Attic = 4 },
		AreaNames = { Upstairs = "THE FUNHOUSE", Basement = "THE GHOST TRAIN", Attic = "THE BIG TOP" },
		Lighting = "Fair",
	},
	{
		MapId = "NightmareHouse", Name = "The House That Grandma Built", Short = "???", FirstNight = 26, LastNight = 31,
		Tagline = "It's not her house anymore.",
		AreaUnlock = { Upstairs = 2, Basement = 3, Attic = 4 },
		AreaNames = { Upstairs = "THE WRONG STAIRS", Basement = "THE ROOTS", Attic = "THE NURSERY" },
		Lighting = "Nightmare",
	},
}

-- Which chapter a night belongs to.
function MapConfig.ChapterFor(night: number): any
	for _, c in MapConfig.Chapters do
		if night >= c.FirstNight and night <= c.LastNight then
			return c
		end
	end
	return MapConfig.Chapters[#MapConfig.Chapters]
end

function MapConfig.ByMapId(id: string): any
	for _, c in MapConfig.Chapters do
		if c.MapId == id then
			return c
		end
	end
	return nil
end

-- Areas open on this night of its chapter; plus the new area's display name (or the map's
-- name on a chapter's first night).
function MapConfig.AreasFor(night: number): ({ [string]: boolean }, string?)
	local c = MapConfig.ChapterFor(night)
	local k = night - c.FirstNight + 1
	local areas = { Ground = true }
	local newArea: string? = nil
	for area, openOn in c.AreaUnlock do
		areas[area] = k >= openOn
		if k == openOn then
			newArea = c.AreaNames[area] or string.upper(area)
		end
	end
	if k == 1 and night > 1 then
		newArea = string.upper(c.Name)
	end
	return areas, newArea
end

return MapConfig
