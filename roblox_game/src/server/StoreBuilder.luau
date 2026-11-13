-- Builds the ABCDE Market: floor, walls, sliding doors, section shelves full of
-- products, Spike's kitchen, Spike himself, and some trees outside.
--
-- Layout matches the web game (metres, scaled by Config.SCALE). The shopper
-- enters at +Z; the fridges are along the back wall at -Z.
--
-- Everything goes in workspace.Store, which is parented only once it is
-- complete and has the attribute Ready = true, so clients see it all at once.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Fonts = require(Shared.Fonts)
local GameData = require(Shared.GameData)

local Build = require(script.Parent.Build)
local SpikeBuilder = require(script.Parent.SpikeBuilder)

local S = Config.SCALE
local hex = Build.hex
local DECOR = Build.DECOR
local INK = Config.UI.ink
local WHITE = Color3.new(1, 1, 1)
local O = CFrame.new()

local StoreBuilder = {}

local function setupLighting()
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(150, 160, 185)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 180, 205)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.4

	local cc = Lighting:FindFirstChild("NutriColor") or Instance.new("ColorCorrectionEffect")
	cc.Name = "NutriColor"
	cc.Saturation = 0.12
	cc.Contrast = 0.04
	cc.Parent = Lighting

	-- Turn the template's grey baseplate into a lawn.
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Material = Enum.Material.Grass
		baseplate.Color = hex("#8cc97a")
		for _, child in baseplate:GetChildren() do
			if child:IsA("Texture") or child:IsA("Decal") then
				child:Destroy()
			end
		end
	end
end

local function buildShell(parent)
	-- Checkered floor, 2 m tiles, top surface at y = 0
	local floor = Build.folder("Floor", parent)
	local light, mint = hex("#f4f8fb"), hex("#d9efe6")
	for ix = 0, 19 do
		for iz = 0, 17 do
			Build.box(floor, O, 2, 0.2, 2, if (ix + iz) % 2 == 0 then light else mint, -19 + ix * 2, -0.1, -17 + iz * 2, {
				Reflectance = 0.04,
			})
		end
	end

	-- Walls with a blue stripe; the front wall is low with a gap for the doors
	local wall, stripe = hex("#f7fbff"), Config.UI.accent
	local walls = Build.folder("Walls", parent)
	-- Pieces meet edge to edge instead of overlapping: two faces in (almost)
	-- the same place flicker. The back wall stops at the side walls; the
	-- stripes sit on the wall surfaces and meet in the corners.
	Build.box(walls, O, 40, 5, 0.3, wall, 0, 2.5, -18.15)
	Build.box(walls, O, 0.3, 5, 36.6, wall, -20.15, 2.5, 0)
	Build.box(walls, O, 0.3, 5, 36.6, wall, 20.15, 2.5, 0)
	Build.box(walls, O, 17, 1.2, 0.3, wall, -11.5, 0.6, 18.15)
	Build.box(walls, O, 17, 1.2, 0.3, wall, 11.5, 0.6, 18.15)
	Build.box(walls, O, 39.68, 0.35, 0.16, stripe, 0, 1.4, -17.92, DECOR)
	Build.box(walls, O, 0.16, 0.35, 36, stripe, -19.92, 1.4, 0, DECOR)
	Build.box(walls, O, 0.16, 0.35, 36, stripe, 19.92, 1.4, 0, DECOR)

	-- Entrance arch in the five Nutri-Score colours. Posts stop under the
	-- beam and are well thicker than the low wall they pass through.
	for i, g in Config.NS do
		Build.box(walls, O, 0.3, 0.6, 0.3, Config.NS_COLORS[g], -3.2 + (i - 1) * 1.6, 3.15, 18.15)
	end
	Build.box(walls, O, 0.3, 2.825, 0.5, stripe, -3.2, 1.4125, 18.15)
	Build.box(walls, O, 0.3, 2.825, 0.5, stripe, 3.2, 1.4125, 18.15)
	Build.box(walls, O, 6.6, 0.25, 0.5, stripe, 0, 2.95, 18.15)

	-- Sliding glass doors (the server opens them when someone walks up)
	local doors = Build.folder("Doors", parent)
	local glass = { Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false, CanTouch = false }
	Build.box(doors, O, 3, 2.6, 0.08, hex("#9fd3f0"), -1.5, 1.3, 18.05, Build.merge(glass, { Name = "DoorL" }))
	Build.box(doors, O, 3, 2.6, 0.08, hex("#9fd3f0"), 1.5, 1.3, 18.05, Build.merge(glass, { Name = "DoorR" }))
end

-- Big "A B C D E MARKET" sign on the back wall.
local function buildBigSign(parent)
	local sign = Build.box(parent, O, 14, 2.2, 0.05, INK, 0, 4.1, -17.95, Build.merge(DECOR, { Name = "BigSign", Transparency = 1 }))
	local gui = Build.surfaceGui(sign, Enum.NormalId.Back, 25)
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = INK
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = bg

	for i, g in Config.NS do
		local tile = Instance.new("TextLabel")
		tile.Position = UDim2.fromScale((40 + (i - 1) * 104) / 1024, 22 / 160)
		tile.Size = UDim2.fromScale(94 / 1024, 116 / 160)
		tile.BackgroundColor3 = Config.NS_COLORS[g]
		tile.Text = g
		tile.TextScaled = true
		tile.FontFace = Fonts.display
		tile.TextColor3 = if g == "C" then INK else WHITE
		tile.Parent = bg
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.2, 0)
		c.Parent = tile
	end

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromScale(570 / 1024, 0.2)
	name.Size = UDim2.fromScale(420 / 1024, 0.6)
	name.Text = "MARKET"
	name.TextScaled = true
	name.FontFace = Fonts.display
	name.TextColor3 = WHITE
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = bg
end

-- One pack of a product, standing at `cf` (bottom centre), front facing +Z.
local PACK_SIZES = {
	box = { 0.34, 0.5, 0.14 },
	loaf = { 0.4, 0.22, 0.26 },
	bag = { 0.36, 0.4, 0.16 },
	carton = { 0.22, 0.42, 0.22 },
	tray = { 0.4, 0.1, 0.3 },
}

local function buildPack(parent, cf, p, withLabel)
	local color = hex(p.c)
	local dims = PACK_SIZES[p.sh]
	if dims then
		local part = Build.box(parent, cf, dims[1], dims[2], dims[3], color, 0, dims[2] / 2, 0, DECOR)
		if withLabel then
			Build.emojiFace(part, if p.sh == "tray" then Enum.NormalId.Top else Enum.NormalId.Back, p.e)
		end
	elseif p.sh == "bottle" then
		local glassy = if p.cat == "water" then { Transparency = 0.25 } else nil
		Build.cylinder(parent, cf, 0.085, 0.42, color, 0, 0.21, 0, Build.merge(DECOR, glassy))
		Build.cylinder(parent, cf, 0.05, 0.1, color, 0, 0.47, 0, Build.merge(DECOR, glassy))
		Build.cylinder(parent, cf, 0.04, 0.04, INK, 0, 0.54, 0, DECOR)
		if withLabel then
			Build.emojiFace(Build.box(parent, cf, 0.17, 0.17, 0.01, WHITE, 0, 0.22, 0.09, DECOR), Enum.NormalId.Back, p.e)
		end
	elseif p.sh == "jar" then
		Build.cylinder(parent, cf, 0.12, 0.2, color, 0, 0.1, 0, DECOR)
		Build.cylinder(parent, cf, 0.125, 0.05, INK, 0, 0.225, 0, DECOR)
		if withLabel then
			Build.emojiFace(Build.box(parent, cf, 0.16, 0.16, 0.01, WHITE, 0, 0.1, 0.125, DECOR), Enum.NormalId.Back, p.e)
		end
	elseif p.sh == "can" then
		Build.cylinder(parent, cf, 0.1, 0.17, color, 0, 0.085, 0, DECOR)
		if withLabel then
			Build.emojiFace(Build.box(parent, cf, 0.15, 0.15, 0.01, WHITE, 0, 0.085, 0.105, DECOR), Enum.NormalId.Back, p.e)
		end
	end
end

-- Shelf-edge price tag. The client fills in the letter once it is discovered.
local function buildTag(parent, position)
	local tag = Build.box(parent, O, 0.36, 0.24, 0.02, WHITE, position.X, position.Y, position.Z, Build.merge(DECOR, {
		Name = "Tag",
		Transparency = 1,
	}))
	local gui = Build.surfaceGui(tag, Enum.NormalId.Back, 80)
	local bg = Instance.new("Frame")
	bg.Name = "Bg"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = WHITE
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = bg
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = INK
	stroke.Parent = bg
	local letter = Instance.new("TextLabel")
	letter.Name = "Letter"
	letter.BackgroundTransparency = 1
	letter.Size = UDim2.fromScale(1, 1)
	letter.Text = "?"
	letter.TextScaled = true
	letter.FontFace = Fonts.display
	letter.TextColor3 = INK
	letter.Parent = bg
end

local function buildSection(sec, fixtures, signs, products)
	local list = GameData.productsIn(sec.id)
	local n = #list
	local half = sec.len / 2
	local origin = CFrame.new(sec.x * S, 0, sec.z * S)
	local trim = hex(sec.col)
	local crates = sec.kind == "crates"
	local group = Build.folder(sec.id, fixtures)

	if crates then
		Build.box(group, origin, sec.len, 0.55, 1.2, hex("#c99a63"), 0, 0.275, 0)
		Build.box(group, origin, sec.len + 0.1, 0.06, 1.3, trim, 0, 0.58, 0)
		for _, dx in { -1.6, 1.6 } do
			Build.box(group, origin, 0.08, 1.72, 0.08, INK, dx, 1.44, -0.44, DECOR)
		end
	else
		-- The pieces meet edge to edge and never overlap: two faces in (almost)
		-- the same place flicker. Side trims hold everything between them, the
		-- back panel sits on the base, and the top trim caps it all.
		local fridge = sec.kind == "fridge"
		local inner = sec.len - 0.08 -- between the side trims
		Build.box(group, origin, 0.08, 2.06, 1.2, trim, -half, 1.03, 0)
		Build.box(group, origin, 0.08, 2.06, 1.2, trim, half, 1.03, 0)
		Build.box(group, origin, sec.len + 0.08, 0.12, 1.2, trim, 0, 2.12, 0)
		Build.box(group, origin, inner, 0.42, 1.2, trim, 0, 0.21, 0)
		Build.box(group, origin, inner, 1.64, 0.1, if fridge then hex("#dff2ff") else hex("#f2f5fb"), 0, 1.24, -0.55)
		for _, y in { 0.48, 1.28 } do
			Build.box(group, origin, inner, 0.05, 1.075, hex("#dfe6f2"), 0, y, 0.0375)
		end
		if fridge then
			local strip = Build.box(group, origin, sec.len - 0.2, 0.08, 0.08, WHITE, 0, 2.0, 0.5, Build.merge(DECOR, {
				Material = Enum.Material.Neon,
			}))
			local light = Instance.new("SurfaceLight")
			light.Face = Enum.NormalId.Bottom
			light.Brightness = 1.2
			light.Range = 8
			light.Color = hex("#e8f6ff")
			light.Parent = strip
		end
	end

	-- Section sign, tipped slightly toward the shopper
	local signY = if crates then 2.3 else 2.85
	local signZ = sec.z + (if crates then -0.3 else 0.1)
	local sign = Build.part(signs, Vector3.new(4.2, 1.05, 0.05) * S, CFrame.new(sec.x * S, signY * S, signZ * S) * CFrame.Angles(0.12, 0, 0), trim, Build.merge(DECOR, {
		Name = "Sign_" .. sec.id,
		Transparency = 1,
	}))
	sign:SetAttribute("SectionId", sec.id)
	-- Paint both faces so the sign isn't see-through from behind.
	for _, face in { Enum.NormalId.Back, Enum.NormalId.Front } do
		Build.signGui(sign, face, trim, sec.e, sec.nm[1])
	end

	-- Products
	for i, p in list do
		local x = sec.x - half + (i - 0.5) * sec.len / n
		local slot = Instance.new("Model")
		slot.Name = p.id
		slot:SetAttribute("ProductId", p.id)
		slot:SetAttribute("SectionId", sec.id)

		local baseY, tagPos
		if crates then
			baseY = 0.58
			local o = CFrame.new(x * S, baseY * S, sec.z * S)
			Build.box(slot, o, 0.95, 0.28, 0.7, hex("#b98352"), 0, 0.14, 0, DECOR)
			local color = hex(p.c)
			for k = 0, 8 do
				local fx = (k % 3 - 1) * 0.26 + (math.random() - 0.5) * 0.05
				local fy = 0.32 + math.random() * 0.06
				local fz = (k // 3 - 1) * 0.18
				Build.ball(slot, o, 0.22 * (0.9 + math.random() * 0.25), color, fx, fy, fz, DECOR)
			end
			Build.emojiFace(Build.box(slot, o, 0.34, 0.34, 0.02, WHITE, 0, 0.2, 0.36, DECOR), Enum.NormalId.Back, p.e)
			tagPos = Vector3.new(x + 0.34, baseY + 0.14, sec.z + 0.39)
		else
			local level = if n > 4 then (i - 1) % 2 else 0
			baseY = if level == 1 then 1.305 else 0.505
			local o = CFrame.new(x * S, baseY * S, (sec.z + 0.05) * S)
			local stacked = p.sh == "tray" or p.sh == "loaf"
			local copies = if stacked then { { 0, 0, 0.15 }, { 0, 0, -0.2 } } else { { -0.2, 0, 0.12 }, { 0.2, 0, 0.135 }, { 0, 0, -0.18 } }
			for _, c in copies do
				buildPack(slot, Build.at(o, c[1], c[2], c[3]), p, c[3] > 0)
			end
			if stacked then
				buildPack(slot, Build.at(o, 0, if p.sh == "tray" then 0.1 else 0.22, -0.2), p, false)
			end
			tagPos = Vector3.new(x, baseY + (if level == 1 then -0.07 else 0.03), sec.z + 0.68)
		end
		buildTag(slot, tagPos)

		-- Invisible box that carries the "Look closer" prompt
		local hit = Build.box(slot, O, math.min(0.9, sec.len / n * 1.6), 0.9, 1.1, WHITE, x, baseY + 0.35, sec.z + 0.15, Build.merge(DECOR, {
			Name = "Hit",
			Transparency = 1,
		}))
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "LookPrompt"
		prompt.ActionText = "Look closer"
		prompt.ObjectText = p.nm[1]
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("ProductId", p.id)
		prompt.Parent = hit

		slot.PrimaryPart = hit
		pcall(function()
			slot.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		end)
		slot.Parent = products
	end
end

local function buildKitchen(parent, signs)
	local k = Config.KITCHEN_POS
	local origin = CFrame.new(k * S)
	local pink, white = hex("#e2477f"), WHITE

	Build.box(parent, origin, 6, 0.12, 1.1, white, 0, 0.89, 0)
	Build.box(parent, origin, 6.1, 0.08, 1.2, pink, 0, 0.99, 0)
	for _, leg in { { -2.82, -0.42 }, { 2.82, -0.42 }, { -2.82, 0.42 }, { 2.82, 0.42 } } do
		Build.box(parent, origin, 0.16, 0.84, 0.16, pink, leg[1], 0.42, leg[2])
	end
	Build.box(parent, origin, 5.6, 0.06, 0.9, hex("#f2f5fb"), 0, 0.24, 0)
	-- Players should not walk through the counter
	Build.box(parent, origin, 6.2, 1.1, 1.2, white, 0, 0.55, 0, { Transparency = 1, Name = "Blocker" })

	-- Stove, pot with a rattling lid and steam
	Build.box(parent, origin, 1.4, 0.06, 0.9, INK, -1.6, 1.05, 0, DECOR)
	Build.cylinder(parent, origin, 0.32, 0.4, hex("#c7cfdd"), -1.6, 1.28, 0, Build.merge(DECOR, { Material = Enum.Material.Metal }))
	local lid = Build.cylinder(parent, origin, 0.34, 0.04, hex("#9aa6bb"), -1.6, 1.5, 0, Build.merge(DECOR, { Name = "Lid", Material = Enum.Material.Metal }))
	local steam = Instance.new("ParticleEmitter")
	steam.Color = ColorSequence.new(WHITE)
	steam.LightEmission = 0.2
	steam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	steam.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1.8),
	})
	steam.Lifetime = NumberRange.new(1.5, 2.5)
	steam.Rate = 6
	steam.Speed = NumberRange.new(2, 3.5)
	steam.SpreadAngle = Vector2.new(12, 12)
	steam.Acceleration = Vector3.new(0, 1, 0)
	steam.EmissionDirection = Enum.NormalId.Top
	steam.Parent = lid

	-- Cutting board with veg
	local board = Build.box(parent, origin, 0.9, 0.05, 0.5, hex("#d9a066"), 1.3, 1.05, 0, DECOR)
	board.CFrame *= CFrame.Angles(0, 0.2, 0)
	for _, f in { { "#d93a2b", 1.1 }, { "#f07c1c", 1.45 }, { "#3d8b3d", 1.7 } } do
		Build.ball(parent, origin, 0.22, hex(f[1]), f[2], 1.17, 0.05, DECOR)
	end

	-- Kitchen sign above the counter, on two posts
	local sign = Build.part(signs, Vector3.new(4.2, 1.05, 0.05) * S, CFrame.new((k + Vector3.new(0, 2.6, -0.4)) * S) * CFrame.Angles(0.12, 0, 0), WHITE, Build.merge(DECOR, {
		Name = "KitchenSign",
		Transparency = 1,
	}))
	-- Paint both faces so the sign isn't see-through from behind.
	for _, face in { Enum.NormalId.Back, Enum.NormalId.Front } do
		Build.signGui(sign, face, WHITE, nil, "Spike’s kitchen", Config.UI.quill)
	end
	for _, dx in { -1.8, 1.8 } do
		Build.box(parent, origin, 0.08, 1.2, 0.08, pink, dx, 1.6, -0.45, DECOR)
	end
end

local function tree(parent, x, z, size)
	local origin = CFrame.new(x * S, 0, z * S)
	Build.cylinder(parent, origin, 0.3 * size, 2.4 * size, hex("#8a5a3b"), 0, 1.2 * size, 0, { Material = Enum.Material.Wood })
	local greens = { hex("#4caf50"), hex("#5cbf60"), hex("#3f9a45") }
	Build.ball(parent, origin, 3 * size, greens[1], 0, 3.2 * size, 0, { Material = Enum.Material.Grass })
	Build.ball(parent, origin, 2.2 * size, greens[2], 0.7 * size, 3.9 * size, 0.3 * size, Build.merge(DECOR, { Material = Enum.Material.Grass }))
	Build.ball(parent, origin, 2 * size, greens[3], -0.6 * size, 3.7 * size, -0.4 * size, Build.merge(DECOR, { Material = Enum.Material.Grass }))
end

local function buildOutside(parent)
	-- Path from the doors
	Build.box(parent, O, 6, 0.1, 10, hex("#e9e4da"), 0, -0.05, 23.5)
	-- Flower beds either side of the entrance
	local flowers = { "#e63e11", "#fecb02", "#ff6fa5", "#ffffff", "#8a62d6" }
	for _, bx in { -6.5, 6.5 } do
		Build.box(parent, O, 6, 0.3, 1.6, hex("#7a4b2c"), bx, 0.15, 20)
		for i = 0, 13 do
			local fx = bx - 2.6 + (i % 7) * 0.86
			local fz = 19.6 + (i // 7) * 0.8
			Build.ball(parent, O, 0.4, hex(flowers[(i % #flowers) + 1]), fx, 0.45, fz, DECOR)
		end
	end
	-- Trees around the store
	local spots = {
		{ -26, -12, 1 }, { -27, 1, 1.15 }, { -26, 13, 0.95 }, { 26, -12, 1.1 }, { 27, 0, 0.95 }, { 26, 12, 1.05 },
		{ -14, 27, 1 }, { 14, 27, 1.1 }, { -24, 25, 0.9 }, { 24, 25, 1 }, { 0, -26, 1.2 }, { -14, -25, 1 }, { 14, -25, 0.95 },
	}
	for _, s in spots do
		tree(parent, s[1], s[2], s[3])
	end
end

function StoreBuilder.build()
	setupLighting()

	local store = Instance.new("Folder")
	store.Name = "Store"
	local building = Build.folder("Building", store)
	local fixtures = Build.folder("Fixtures", store)
	local signs = Build.folder("Signs", store)
	local products = Build.folder("Products", store)
	local kitchen = Build.folder("Kitchen", store)
	local outside = Build.folder("Outside", store)

	buildShell(building)
	buildBigSign(signs)
	for _, sec in GameData.SECTIONS do
		buildSection(sec, fixtures, signs, products)
	end
	buildKitchen(kitchen, signs)
	SpikeBuilder.build(store, Config.SPIKE_POS * S)
	buildOutside(outside)

	store:SetAttribute("Ready", true)
	store.Parent = workspace
	return store
end

return StoreBuilder
