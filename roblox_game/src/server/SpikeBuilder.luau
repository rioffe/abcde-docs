-- Builds Spike, the porcupine chef, out of parts: round body, cream face,
-- a fan of quills, chef's hat and a wooden spoon.
--
-- The model is split into sub-models the client animates:
--   Body   - everything that just moves with Spike
--   Head   - nods while he talks (pivot Config.SPIKE_HEAD)
--   Quills - puff out when he is happy or startled (centre Config.SPIKE_QUILLS)
--   Spoon  - waves while he talks (pivot Config.SPIKE_SPOON)
-- Spike faces +Z. Eye parts are named "Eye" so the client can make him blink.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Build = require(script.Parent.Build)

local S = Config.SCALE
local hex = Build.hex
local DECOR = Build.DECOR

local SpikeBuilder = {}

local function model(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- One quill: dark shaft with a cream tip, pointing along `dir`.
local function quill(parent, origin, base, dir, len, shaftColor, tipColor)
	local up = if math.abs(dir.Y) > 0.95 then Vector3.xAxis else Vector3.yAxis
	local side = dir:Cross(up).Unit
	local function rodAt(center, length, diameter, color)
		local cf = CFrame.fromMatrix(origin * (center * S), dir, side)
		Build.part(parent, Vector3.new(length, diameter, diameter) * S, cf, color, DECOR, Enum.PartType.Cylinder)
	end
	rodAt(base + dir * (0.31 * len), 0.62 * len, 0.075, shaftColor)
	rodAt(base + dir * (0.62 * len + 0.08), 0.2, 0.045, tipColor)
end

-- `feet` is Spike's position in studs, at floor level.
function SpikeBuilder.build(parent, feet)
	local origin = CFrame.new(feet)
	local spike = model("Spike", nil)

	local bodyColor = hex("#8a5a3b")
	local faceColor = hex("#e7c9a0")
	local ink = Config.UI.ink
	local white = Color3.new(1, 1, 1)
	local pink = hex("#f4a3a3")
	local wood = hex("#d9a066")

	-- Body
	local body = model("Body", spike)
	Build.ellipsoid(body, origin, 1.44, 1.32, 1.55, bodyColor, 0, 0.82, 0, DECOR)
	Build.ellipsoid(body, origin, 1.12, 1.12, 0.67, faceColor, 0, 0.74, 0.42, DECOR)
	for _, x in { -0.3, 0.3 } do
		Build.cylinder(body, origin, 0.125, 0.3, bodyColor, x, 0.2, 0.08, DECOR)
		Build.ellipsoid(body, origin, 0.3, 0.15, 0.4, ink, x, 0.07, 0.16, DECOR)
		Build.ellipsoid(body, origin, 0.22, 0.22, 0.22, faceColor, x * 1.83, 0.85, 0.45, DECOR) -- hands
	end

	-- Chef's hat, tipped back a little
	local hatOrigin = Build.at(origin, 0, 1.62, 0.15) * CFrame.Angles(-0.18, 0, 0)
	Build.cylinder(body, hatOrigin, 0.29, 0.22, white, 0, 0, 0, DECOR)
	Build.ball(body, hatOrigin, 0.52, white, 0, 0.28, 0, DECOR)
	Build.ball(body, hatOrigin, 0.36, white, -0.18, 0.22, 0, DECOR)
	Build.ball(body, hatOrigin, 0.36, white, 0.18, 0.22, 0, DECOR)
	Build.ball(body, hatOrigin, 0.36, white, 0, 0.22, 0.15, DECOR)

	-- Head (snout, nose, eyes, cheeks, ears)
	local head = model("Head", spike)
	local h = Config.SPIKE_HEAD
	local headOrigin = Build.at(origin, h.X, h.Y, h.Z)
	Build.ellipsoid(head, headOrigin, 0.63, 0.51, 0.6, faceColor, 0, 0, 0, DECOR)
	Build.ellipsoid(head, headOrigin, 0.17, 0.17, 0.17, ink, 0, 0.02, 0.3, DECOR)
	for _, x in { -0.15, 0.15 } do
		Build.ellipsoid(head, headOrigin, 0.15, 0.15, 0.15, white, x, 0.13, 0.2, DECOR).Name = "Eye"
		Build.ellipsoid(head, headOrigin, 0.09, 0.09, 0.09, ink, x, 0.13, 0.265, DECOR).Name = "Eye"
		Build.ellipsoid(head, headOrigin, 0.1, 0.1, 0.1, pink, x * 1.6, -0.03, 0.22, DECOR)
		Build.ellipsoid(head, headOrigin, 0.18, 0.18, 0.18, bodyColor, x * 2, 0.24, -0.05, DECOR)
	end

	-- Wooden spoon
	local spoon = model("Spoon", spike)
	local sp = Config.SPIKE_SPOON
	local spoonOrigin = Build.at(origin, sp.X, sp.Y, sp.Z) * CFrame.Angles(0, 0, -0.35)
	Build.cylinder(spoon, spoonOrigin, 0.025, 0.7, wood, 0, 0.3, 0, DECOR)
	Build.ellipsoid(spoon, spoonOrigin, 0.18, 0.09, 0.23, wood, 0, 0.68, 0, DECOR)

	-- Quills: spread over the back half of a sphere, sweeping backwards
	local quills = model("Quills", spike)
	local q = Config.SPIKE_QUILLS
	local quillOrigin = Build.at(origin, q.X, q.Y, q.Z)
	local shaftColor, tipColor = hex("#4a2b19"), hex("#f1dfc0")
	local wanted, candidates = 110, 220
	local count = 0
	for i = 0, candidates - 1 do
		if count >= wanted then
			break
		end
		local y = 1 - (i / (candidates - 1)) * 2
		local r = math.sqrt(math.max(0, 1 - y * y))
		local th = i * 2.399963
		local d = Vector3.new(math.cos(th) * r, y, math.sin(th) * r)
		if d.Z <= 0.25 and d.Y >= -0.3 then
			count += 1
			local dir = (d + Vector3.new(0, 0.15, -0.55)).Unit
			local base = Vector3.new(d.X * 0.7, d.Y * 0.64, d.Z * 0.76)
			local len = 0.9 + ((count * 37) % 10) / 25
			quill(quills, quillOrigin, base, dir, len, shaftColor, tipColor)
		end
	end

	-- Invisible box players bump into and talk to
	local root = Build.box(spike, origin, 1.6, 2.2, 1.6, white, 0, 1.1, 0, {
		Name = "Root",
		Transparency = 1,
		CanCollide = true,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk to Spike"
	prompt.ObjectText = "Spike"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Spike", true)
	prompt.Parent = root

	spike.WorldPivot = origin
	pcall(function()
		spike.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	spike.Parent = parent
	return spike
end

return SpikeBuilder
