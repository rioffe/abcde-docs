-- Sound effects, played only for the local player.
--
-- The web game's sounds are recreated as WAV files in assets/sounds/
-- (made by tools/make_sounds.py). Upload them to Roblox once
-- (Studio: View → Asset Manager → Bulk Import) and paste each asset id
-- into IDS below, e.g. open = "rbxassetid://1234567890".
--
-- Until an id is filled in, that effect plays the web game's melody on
-- Roblox's built-in volume-slider chime, re-pitched note by note, so the
-- game is never silent.

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Sfx = {}
Sfx.enabled = true

-- Uploaded sounds (assets/sounds/nutri_<name>.wav). Leave "" to use the fallback.
Sfx.IDS = {
	talk = "",
	open = "",
	close = "",
	near = "",
	right = "",
	miss = "",
	wrong = "",
	add = "",
	hint = "",
	fanfare = "",
}

-- Built-in chime (ships with every Roblox client), pitched at about 490 Hz.
local FALLBACK = "rbxasset://sounds/volume_slider.ogg"
local FALLBACK_HZ = 490

-- The web game's notes as { frequency Hz, delay s, volume }.
local MELODIES = {
	talk = { { 580, 0, 0.12 } },
	open = { { 523, 0, 0.4 }, { 784, 0.06, 0.4 } },
	close = { { 523, 0, 0.4 }, { 659, 0.08, 0.4 } },
	near = { { 523, 0, 0.45 }, { 659, 0.08, 0.45 } },
	right = { { 523, 0, 0.5 }, { 659, 0.07, 0.5 }, { 784, 0.14, 0.5 }, { 1046, 0.21, 0.5 } },
	miss = { { 330, 0, 0.45 }, { 262, 0.12, 0.4 } },
	wrong = { { 220, 0, 0.55 }, { 180, 0.13, 0.5 } },
	add = { { 660, 0, 0.45 }, { 990, 0.07, 0.45 }, { 1320, 0.14, 0.4 } },
	hint = { { 1046, 0, 0.35 }, { 1318, 0.08, 0.35 }, { 1568, 0.16, 0.35 } },
	fanfare = {
		{ 523, 0, 0.55 }, { 659, 0.12, 0.55 }, { 784, 0.24, 0.55 }, { 1046, 0.36, 0.55 },
		{ 784, 0.48, 0.55 }, { 1046, 0.6, 0.55 }, { 1318, 0.72, 0.6 },
	},
}

local VOLUME = 0.7 -- for uploaded sounds

local templates = {} -- [soundId] = preloaded Sound to clone

local function template(soundId)
	local s = templates[soundId]
	if not s then
		s = Instance.new("Sound")
		s.Name = "NutriSfx"
		s.SoundId = soundId
		s.Parent = SoundService
		templates[soundId] = s
	end
	return s
end

local function playSound(soundId, speed, volume, delay)
	local base = template(soundId)
	local function go()
		if not Sfx.enabled then
			return
		end
		local s = base:Clone()
		s.PlaybackSpeed = speed
		s.Volume = volume
		s.Parent = SoundService
		s:Play()
		Debris:AddItem(s, 3)
	end
	if delay and delay > 0 then
		task.delay(delay, go)
	else
		go()
	end
end

local reported = {}

function Sfx.play(name)
	if not reported[name] then
		reported[name] = true
		print("[NutriQuest] playing sound:", name, if Sfx.enabled then "" else "(sound is switched off)")
	end
	if not Sfx.enabled then
		return
	end
	local id = Sfx.IDS[name]
	if id and id ~= "" then
		-- Spike's chatter varies in pitch like the web game (420–740 Hz).
		local speed = if name == "talk" then 0.72 + math.random() * 0.56 else 1
		playSound(id, speed, if name == "talk" then 0.35 else VOLUME, 0)
		return
	end
	local melody = MELODIES[name]
	if not melody then
		return
	end
	for _, note in melody do
		local hz = note[1]
		if name == "talk" then
			hz = 420 + math.random() * 320
		end
		playSound(FALLBACK, hz / FALLBACK_HZ, note[3], note[2])
	end
end

-- Load every sound up front so the first play isn't late or silent, and
-- report in the Output window whether each one loaded.
task.spawn(function()
	local list = { template(FALLBACK) }
	for _, id in Sfx.IDS do
		if id ~= "" then
			table.insert(list, template(id))
		end
	end
	local ok, err = pcall(function()
		ContentProvider:PreloadAsync(list, function(contentId, status)
			if status == Enum.AssetFetchStatus.Success then
				print("[NutriQuest] sound loaded:", contentId)
			else
				warn("[NutriQuest] sound FAILED to load:", contentId, status.Name)
			end
		end)
	end)
	if not ok then
		warn("[NutriQuest] sound preload error:", err)
	end
	for _, s in list do
		print("[NutriQuest] sound", s.SoundId, "IsLoaded =", s.IsLoaded, "TimeLength =", s.TimeLength)
	end
end)

return Sfx
