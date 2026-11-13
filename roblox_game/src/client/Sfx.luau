-- Little sound effects, played only for the local player.
--
-- The web game synthesised tones. Here every effect is one short built-in
-- "ping" sample played at different speeds (= different pitches), so the
-- game needs no uploaded audio. Swap the ids for Creator Store sounds if you
-- want richer audio.

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local PING = "rbxasset://sounds/electronicpingshort.wav"
local CLICK = "rbxasset://sounds/clickfast.wav"

local Sfx = {}
Sfx.enabled = true

local function tone(id, speed, volume, delay)
	task.delay(delay or 0, function()
		if not Sfx.enabled then
			return
		end
		local s = Instance.new("Sound")
		s.SoundId = id
		s.PlaybackSpeed = speed
		s.Volume = volume or 0.5
		s.Parent = SoundService
		s:Play()
		Debris:AddItem(s, 3)
	end)
end

-- Plays a run of pitches (playback speeds), `gap` seconds apart.
local function melody(speeds, gap, volume)
	for i, speed in speeds do
		tone(PING, speed, volume, (i - 1) * gap)
	end
end

local EFFECTS = {
	talk = function()
		tone(CLICK, 1.3 + math.random() * 0.5, 0.18)
	end,
	open = function()
		melody({ 1, 1.5 }, 0.06, 0.35)
	end,
	close = function()
		melody({ 1, 1.26 }, 0.08, 0.35)
	end,
	right = function()
		melody({ 1, 1.26, 1.5, 2 }, 0.07, 0.45)
	end,
	near = function()
		melody({ 1, 1.26 }, 0.08, 0.4)
	end,
	miss = function()
		melody({ 0.63, 0.5 }, 0.12, 0.35)
	end,
	wrong = function()
		melody({ 0.42, 0.34 }, 0.13, 0.45)
	end,
	add = function()
		melody({ 1.26, 1.9, 2.52 }, 0.07, 0.4)
	end,
	hint = function()
		melody({ 2, 2.52, 3 }, 0.08, 0.3)
	end,
	fanfare = function()
		melody({ 1, 1.26, 1.5, 2, 1.5, 2, 2.52 }, 0.12, 0.5)
	end,
}

function Sfx.play(name)
	local effect = EFFECTS[name]
	if effect and Sfx.enabled then
		effect()
	end
end

return Sfx
