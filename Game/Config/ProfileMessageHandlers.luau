-- ProfileMessageHandlers
-- Handlers for cross-server ProfileStore messages (VIDK SMProfile:SendMessage).
-- Each handler: (player, message, processed) — call processed() once handled.

local function service(name: string)
	local ok, s = pcall(shared, name)
	return if ok then s else nil
end

return {
	-- Sent to an inviter when a friend they invited plays for the first time.
	ReferralReward = function(player: Player, message, processed)
		local rewards = service("RewardsService")
		if rewards then
			rewards:GrantReferralInviter(player, message.nSenderId)
		end
		processed()
	end,
}
