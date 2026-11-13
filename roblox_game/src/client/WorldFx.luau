-- Everything in the 3D world that only this player sees:
--   * Spike's animation (turns to face you, bobs, nods while talking, blinks,
--     puffs his quills, spins when a quest is done)
--   * the "!" / "?" bubble over Spike
--   * shelf tags that show letters you have discovered
--   * signs and prompts in your language
--   * hint stars over the shelves you need, and a golden guide beam
--   * a glow around the product or Spike you are next to
--   * confetti bursts
--   * the camera on the title screen and during Spike's talks

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local GameData = require(Shared.GameData)
local Quest = require(Shared.Quest)
local Text = require(Shared.Text)

local S = Config.SCALE
local INK = Config.UI.ink
local GOLD = Config.UI.gold
local player = Players.LocalPlayer

local WorldFx = {}

local store, spike
local spikeBase = CFrame.new(Config.SPIKE_POS * S)
local spikeParts, spikeRel, spikeGroup, spikeCFrames = {}, {}, {}, {}
local eyeMeshes = {}
local spikeYaw = 0
local partyTime, shakeTime = 0, 0
local bubble, bubbleLabel
local beacons = {}
local beam, beamFrom, beamTarget
local fxPart, emitters = nil, {}
local highlight
local cameraMode = "follow"
local camPos, camLook

local function localPart(name, position)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = position
	p.Parent = workspace
	return p
end

local function characterRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------------------- setup

local function setupSpike()
	for _, d in spike:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(spikeParts, d)
			table.insert(spikeRel, spikeBase:ToObjectSpace(d.CFrame))
			table.insert(spikeGroup, d.Parent.Name)
			if d.Name == "Eye" then
				local mesh = d:FindFirstChildOfClass("SpecialMesh")
				if mesh then
					table.insert(eyeMeshes, mesh)
				end
			end
		end
	end

	-- Speech bubble: "!" when your basket is ready, "?" while shopping
	local root = spike:FindFirstChild("Root")
	bubble = Instance.new("BillboardGui")
	bubble.Name = "SpikeBubble"
	bubble.Size = UDim2.fromScale(3, 3)
	bubble.StudsOffset = Vector3.new(0, (2.75 - 1.1) * S, 0)
	bubble.AlwaysOnTop = true
	bubble.LightInfluence = 0
	bubble.Adornee = root
	bubble.Enabled = false
	local circle = Instance.new("Frame")
	circle.Size = UDim2.fromScale(1, 1)
	circle.BackgroundColor3 = GOLD
	circle.Parent = bubble
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = circle
	local st = Instance.new("UIStroke")
	st.Thickness = 4
	st.Color = INK
	st.Parent = circle
	bubbleLabel = Instance.new("TextLabel")
	bubbleLabel.Size = UDim2.fromScale(1, 1)
	bubbleLabel.BackgroundTransparency = 1
	bubbleLabel.Font = Enum.Font.FredokaOne
	bubbleLabel.TextScaled = true
	bubbleLabel.TextColor3 = INK
	bubbleLabel.Text = "!"
	bubbleLabel.Parent = circle
	bubble.Parent = player:WaitForChild("PlayerGui")
end

local function setupBeacons()
	for _, sec in GameData.SECTIONS do
		local crates = sec.kind == "crates"
		local pos = Vector3.new(sec.x, if crates then 3.35 else 3.85, sec.z + (if crates then -0.3 else 0.1)) * S
		local anchor = localPart("Beacon_" .. sec.id, pos)
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromScale(3.2, 3.2)
		gui.AlwaysOnTop = true
		gui.LightInfluence = 0
		gui.Adornee = anchor
		gui.Enabled = false
		local star = Instance.new("TextLabel")
		star.Size = UDim2.fromScale(1, 1)
		star.BackgroundTransparency = 1
		star.Text = "★"
		star.TextScaled = true
		star.Font = Enum.Font.GothamBlack
		star.TextColor3 = GOLD
		star.Parent = gui
		local outline = Instance.new("UIStroke")
		outline.Thickness = 3
		outline.Color = INK
		outline.Parent = star
		gui.Parent = anchor
		beacons[sec.id] = { gui = gui, star = star, base = pos, sec = sec }
	end
end

local function attachBeam(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end
	if beamFrom then
		beamFrom:Destroy()
	end
	beamFrom = Instance.new("Attachment")
	beamFrom.Name = "GuideFrom"
	beamFrom.Position = Vector3.new(0, -1.5, 0)
	beamFrom.Parent = hrp
	beam.Attachment0 = beamFrom
end

local function setupBeam()
	beamTarget = localPart("GuideTarget", Vector3.zero)
	local to = Instance.new("Attachment")
	to.Parent = beamTarget
	beam = Instance.new("Beam")
	beam.Attachment1 = to
	beam.Color = ColorSequence.new(GOLD)
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 0.55),
	})
	beam.Width0 = 1.1
	beam.Width1 = 0.5
	beam.FaceCamera = true
	beam.LightEmission = 0.6
	beam.Segments = 20
	beam.CurveSize0 = 4
	beam.CurveSize1 = -4
	beam.Enabled = false
	beam.Parent = beamTarget
	if player.Character then
		task.spawn(attachBeam, player.Character)
	end
	player.CharacterAdded:Connect(attachBeam)
end

local function setupConfetti()
	fxPart = localPart("Confetti", Vector3.zero)
	local colors = {
		Config.NS_COLORS.A, Config.NS_COLORS.B, Config.NS_COLORS.C, Config.NS_COLORS.D, Config.NS_COLORS.E,
		Config.UI.accent, Config.UI.pink,
	}
	for _, color in colors do
		local e = Instance.new("ParticleEmitter")
		e.Enabled = false
		e.Color = ColorSequence.new(color)
		e.LightEmission = 0.1
		e.Size = NumberSequence.new(0.45)
		e.Speed = NumberRange.new(14, 28)
		e.SpreadAngle = Vector2.new(55, 55)
		e.Acceleration = Vector3.new(0, -38, 0)
		e.Drag = 1.2
		e.Lifetime = NumberRange.new(1.4, 2.4)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-360, 360)
		e.EmissionDirection = Enum.NormalId.Top
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Parent = fxPart
		table.insert(emitters, e)
	end
end

local function setupHighlight()
	highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.82
	highlight.OutlineColor = GOLD
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false

	ProximityPromptService.PromptShown:Connect(function(prompt)
		local target = prompt.Parent and prompt.Parent.Parent
		if target and target:IsA("Model") then
			highlight.Adornee = target
			highlight.Parent = target
			highlight.Enabled = true
		end
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		local target = prompt.Parent and prompt.Parent.Parent
		if highlight.Adornee == target then
			highlight.Enabled = false
		end
	end)
end

function WorldFx.init(storeFolder)
	store = storeFolder
	spike = store:WaitForChild("Spike")
	setupSpike()
	setupBeacons()
	setupBeam()
	setupConfetti()
	setupHighlight()
	local cam = workspace.CurrentCamera
	camPos, camLook = cam.CFrame.Position, cam.CFrame.Position + cam.CFrame.LookVector
end

---------------------------------------------------------------- language, tags, prompts

function WorldFx.localize(lang, state)
	local function t(k)
		return Text.get(lang, k)
	end
	for _, sign in store.Signs:GetChildren() do
		local name = sign:FindFirstChild("Name", true)
		if name and name:IsA("TextLabel") then
			local sectionId = sign:GetAttribute("SectionId")
			if sectionId then
				name.Text = Text.name(lang, GameData.SECTION_BY_ID[sectionId].nm)
			elseif sign.Name == "KitchenSign" then
				name.Text = t("kitchen")
			elseif sign.Name == "BigSign" then
				name.Text = t("market")
			end
		end
	end

	local discovered = state and state.discovered or {}
	for _, slot in store.Products:GetChildren() do
		local p = GameData.PRODUCT_BY_ID[slot.Name]
		if p then
			local prompt = slot:FindFirstChild("LookPrompt", true)
			if prompt then
				prompt.ActionText = t("look")
				prompt.ObjectText = Text.name(lang, p.nm)
			end
			local tag = slot:FindFirstChild("Tag")
			local bg = tag and tag:FindFirstChild("Bg", true)
			local letter = bg and bg:FindFirstChild("Letter")
			if bg and letter then
				if discovered[p.id] then
					local g = p.ns.grade
					bg.BackgroundColor3 = Config.NS_COLORS[g]
					letter.Text = g
					letter.TextColor3 = if g == "C" then INK else Color3.new(1, 1, 1)
				else
					bg.BackgroundColor3 = Color3.new(1, 1, 1)
					letter.Text = "?"
					letter.TextColor3 = INK
				end
			end
		end
	end

	local talk = spike:FindFirstChild("TalkPrompt", true)
	if talk then
		local ready = state and Quest.basketDone(state.filled) and not state.finished
		talk.ActionText = if ready then t("talkReady") else t("talk")
		talk.ObjectText = t("spike")
	end
end

---------------------------------------------------------------- effects

function WorldFx.burst(position, count)
	fxPart.Position = position
	local each = math.max(1, math.ceil(count / #emitters))
	for _, e in emitters do
		e:Emit(each)
	end
end

function WorldFx.burstAtProduct(productId, count)
	local slot = store.Products:FindFirstChild(productId)
	if slot and slot.PrimaryPart then
		WorldFx.burst(slot.PrimaryPart.Position + Vector3.new(0, 1.5, 2), count)
	end
end

function WorldFx.burstAtSpike(count)
	WorldFx.burst(spikeBase.Position + Vector3.new(0, 2 * S, 0.3 * S), count)
end

function WorldFx.party(seconds)
	partyTime = seconds
end

function WorldFx.shake()
	shakeTime = 1
end

function WorldFx.setCameraMode(mode)
	if mode == cameraMode then
		return
	end
	cameraMode = mode
	local cam = workspace.CurrentCamera
	if mode == "follow" then
		cam.CameraType = Enum.CameraType.Custom
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			cam.CameraSubject = humanoid
		end
	else
		camPos, camLook = cam.CFrame.Position, cam.CFrame.Position + cam.CFrame.LookVector * 10
		cam.CameraType = Enum.CameraType.Scriptable
	end
end

---------------------------------------------------------------- per frame

local function wrapAngle(a)
	return (a + math.pi) % (2 * math.pi) - math.pi
end

local function animateSpike(dt, time, talking)
	local hrp = characterRoot()
	if partyTime > 0 then
		spikeYaw += dt * 7
		partyTime -= dt
		if partyTime <= 0 then
			spikeYaw = 0
		end
	elseif hrp then
		local d = hrp.Position - spikeBase.Position
		local want = math.atan2(d.X, d.Z)
		spikeYaw += wrapAngle(want - spikeYaw) * math.min(1, dt * 4)
	end
	shakeTime = math.max(0, shakeTime - dt * 1.5)

	local bob = if partyTime > 0 then math.abs(math.sin(time * 9)) * 0.5 elseif talking then math.abs(math.sin(time * 14)) * 0.06 else 0
	local nod = if talking then math.sin(time * 16) * 0.08 else math.sin(time * 1.3) * 0.04
	local puff = if partyTime > 0 then 1.25 else 1 + math.sin(time * 2) * 0.02 + math.sin(time * 40) * 0.06 * shakeTime
	local wave = if talking then math.sin(time * 10) * 0.4 else math.sin(time * 2) * 0.08

	local root = CFrame.new(spikeBase.Position + Vector3.new(0, bob * S, 0)) * CFrame.Angles(0, spikeYaw, 0)
	local headPivot = CFrame.new(Config.SPIKE_HEAD * S)
	local headTurn = headPivot * CFrame.Angles(-nod, 0, 0) * headPivot:Inverse()
	local spoonPivot = CFrame.new(Config.SPIKE_SPOON * S)
	local spoonTurn = spoonPivot * CFrame.Angles(0, 0, wave) * spoonPivot:Inverse()
	local quillCentre = Config.SPIKE_QUILLS * S

	for i, rel in spikeRel do
		local group = spikeGroup[i]
		if group == "Head" then
			rel = headTurn * rel
		elseif group == "Spoon" then
			rel = spoonTurn * rel
		elseif group == "Quills" then
			local p = rel.Position
			rel = (rel - p) + (quillCentre + (p - quillCentre) * puff)
		end
		spikeCFrames[i] = root * rel
	end
	workspace:BulkMoveTo(spikeParts, spikeCFrames, Enum.BulkMoveMode.FireCFrameChanged)

	local blink = if (time % 3.7) < 0.12 then 0.15 else 1
	for _, mesh in eyeMeshes do
		mesh.Scale = Vector3.new(1, blink, 1)
	end
end

local function updateCamera(dt, time)
	if cameraMode == "follow" then
		return
	end
	local base = spikeBase.Position
	local wantPos, wantLook
	if cameraMode == "title" then
		wantPos = base + Vector3.new(math.sin(time * 0.15) * 2.2, 3, 5.4) * S
		wantLook = base + Vector3.new(0, 1.5, 0) * S
	else
		wantPos = base + Vector3.new(math.sin(0.35) * 4.2, 2.6, 4.6) * S
		wantLook = base + Vector3.new(0, 1.25, 0) * S
	end
	local cam = workspace.CurrentCamera
	if cam.CameraType ~= Enum.CameraType.Scriptable then
		cam.CameraType = Enum.CameraType.Scriptable
	end
	local k = 1 - math.pow(0.02, dt)
	camPos = camPos:Lerp(wantPos, k)
	camLook = camLook:Lerp(wantLook, k)
	cam.CFrame = CFrame.lookAt(camPos, camLook)
end

-- ctx: { mode, state, hintActive, talking }
function WorldFx.update(dt, time, ctx)
	animateSpike(dt, time, ctx.talking)
	updateCamera(dt, time)

	local state = ctx.state
	local playing = state and not state.finished
	local done = state and Quest.basketDone(state.filled)

	-- Bubble over Spike
	if ctx.mode ~= "title" and playing and done then
		bubble.Enabled = true
		bubbleLabel.Text = "!"
		bubble.StudsOffset = Vector3.new(0, (2.75 - 1.1 + math.sin(time * 3) * 0.12) * S, 0)
	elseif ctx.mode == "play" and playing then
		bubble.Enabled = true
		bubbleLabel.Text = "?"
		bubble.StudsOffset = Vector3.new(0, (2.75 - 1.1 + math.sin(time * 3) * 0.12) * S, 0)
	else
		bubble.Enabled = false
	end

	-- Hint stars over needed sections
	local need = if ctx.hintActive and playing then Quest.neededSections(state.q, state.filled) else nil
	for id, b in beacons do
		local on = need ~= nil and need[id] == true
		b.gui.Enabled = on
		if on then
			b.gui.StudsOffset = Vector3.new(0, math.sin(time * 4) * 0.15 * S, 0)
			b.star.Rotation = math.sin(time * 3) * 17
		end
	end

	-- Guide beam: to Spike when the basket is full, else to the nearest needed section
	local hrp = characterRoot()
	local target
	if ctx.mode == "play" and playing and done then
		target = (Config.SPIKE_POS + Vector3.new(0, 0.3, 2)) * S
	elseif need and hrp then
		local best = math.huge
		for id in need do
			local sec = GameData.SECTION_BY_ID[id]
			local p = Vector3.new(sec.x, 0.3, sec.z + 1.4) * S
			local d = (p - hrp.Position).Magnitude
			if d < best then
				best, target = d, p
			end
		end
	end
	if target and hrp and beamFrom and (Vector3.new(target.X, hrp.Position.Y, target.Z) - hrp.Position).Magnitude > 2.5 * S then
		beamTarget.Position = target
		beam.Enabled = true
	else
		beam.Enabled = false
	end
end

return WorldFx
