--!strict
-- PlaceRole
-- Returns "Lobby" or "Match" for the current place. Both places share one codebase.

local PlaceConfig = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("PlaceConfig"))

local forced = workspace:GetAttribute("PlaceRole")
local role: string
if forced == "Lobby" or forced == "Match" then
	role = forced
elseif game.PlaceId == PlaceConfig.MatchPlaceId then
	role = "Match"
elseif game.PlaceId == PlaceConfig.LobbyPlaceId then
	role = "Lobby"
else
	role = PlaceConfig.DefaultRole
end

return {
	Role = role,
	IsLobby = role == "Lobby",
	IsMatch = role == "Match",
}
