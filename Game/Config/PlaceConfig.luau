--!strict
-- PlaceConfig
-- Which place is which. Both places run this same codebase; PlaceRole reads this.
-- DEVELOPER: update these if the places are ever re-created/moved to another universe.

return {
	LobbyPlaceId = 113809617295749,
	MatchPlaceId = 82470107066597,

	-- Used when the PlaceId matches neither (e.g. an unpublished copy). Can also be
	-- forced per-place with a Workspace attribute: PlaceRole = "Lobby" | "Match".
	DefaultRole = "Lobby",
}
