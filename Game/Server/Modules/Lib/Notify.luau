--!strict
-- Notify: server -> client toasts and big banners.
--   Notify.Toast(player | "all", text, style?)   style: "Candy" | "Good" | "Bad" | "Info"
--   Notify.Banner(player | "all", title, subtitle?, color?) -- center-screen title card

local Net = shared("Net")

local ToastEvent = Net.Event("Toast")
local BannerEvent = Net.Event("Banner")

local Notify = {}

function Notify.Toast(target: Player | string, text: string, style: string?)
	if target == "all" then
		ToastEvent:FireAllClients(text, style or "Info")
	else
		ToastEvent:FireClient(target :: Player, text, style or "Info")
	end
end

function Notify.Banner(target: Player | string, title: string, subtitle: string?, color: Color3?)
	if target == "all" then
		BannerEvent:FireAllClients(title, subtitle, color)
	else
		BannerEvent:FireClient(target :: Player, title, subtitle, color)
	end
end

return Notify
