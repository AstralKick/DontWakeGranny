--!strict
-- Format: small display helpers.

local Format = {}

function Format.Number(n: number): string
	n = math.floor(n + 0.5)
	local s = tostring(math.abs(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (if n < 0 then "-" else "") .. out
end

-- Night clock: fraction 0..1 of the night -> "12:00 AM" .. "6:00 AM"
function Format.Clock(fraction: number, startHour: number, endHour: number): string
	fraction = math.clamp(fraction, 0, 1)
	local totalMinutes = (startHour + (endHour - startHour) * fraction) * 60
	local hour = math.floor(totalMinutes / 60) % 24
	local minute = math.floor(totalMinutes % 60 / 10) * 10 -- ticks in 10-minute steps, like an old clock
	local display = hour % 12
	if display == 0 then
		display = 12
	end
	return string.format("%d:%02d %s", display, minute, if hour < 12 then "AM" else "PM")
end

function Format.Seconds(s: number): string
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", s // 60, s % 60)
end

return Format
