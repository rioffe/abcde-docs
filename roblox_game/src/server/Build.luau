-- Small helpers for building the store out of parts.
-- Sizes and offsets are in metres and get multiplied by Config.SCALE.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fonts = require(Shared:WaitForChild("Fonts"))

local S = Config.SCALE
local INK = Config.UI.ink

local Build = {}

-- Props for decorative parts that players can walk through.
Build.DECOR = { CanCollide = false, CanTouch = false, CanQuery = false }

function Build.hex(hex)
	return Color3.fromHex(hex)
end

function Build.merge(a, b)
	local out = {}
	for k, v in a or {} do
		out[k] = v
	end
	for k, v in b or {} do
		out[k] = v
	end
	return out
end

function Build.folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- Studs-based part. `shape` must be set before Size, so it is a separate argument.
function Build.part(parent, size, cframe, color, props, shape)
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

-- CFrame at (x, y, z) metres inside `origin`.
function Build.at(origin, x, y, z)
	return origin * CFrame.new(x * S, y * S, z * S)
end

function Build.box(parent, origin, w, h, d, color, x, y, z, props)
	return Build.part(parent, Vector3.new(w, h, d) * S, Build.at(origin, x, y, z), color, props)
end

-- Upright cylinder (Roblox cylinders lie along X, so it is turned on its side).
function Build.cylinder(parent, origin, radius, height, color, x, y, z, props)
	local cf = Build.at(origin, x, y, z) * CFrame.Angles(0, 0, math.pi / 2)
	return Build.part(parent, Vector3.new(height, radius * 2, radius * 2) * S, cf, color, props, Enum.PartType.Cylinder)
end

-- Cylinder lying along the X axis (wheels, handles).
function Build.rod(parent, origin, radius, length, color, x, y, z, props)
	return Build.part(parent, Vector3.new(length, radius * 2, radius * 2) * S, Build.at(origin, x, y, z), color, props, Enum.PartType.Cylinder)
end

function Build.ball(parent, origin, diameter, color, x, y, z, props)
	return Build.part(parent, Vector3.one * diameter * S, Build.at(origin, x, y, z), color, props, Enum.PartType.Ball)
end

-- Squashed sphere: a box-shaped part drawn with a sphere mesh. Sizes are diameters.
function Build.ellipsoid(parent, origin, sx, sy, sz, color, x, y, z, props)
	local p = Build.part(parent, Vector3.new(sx, sy, sz) * S, Build.at(origin, x, y, z), color, props)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

function Build.surfaceGui(part, face, pixelsPerStud)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 50
	gui.LightInfluence = 0.15
	gui.Parent = part
	return gui
end

local function corner(parent, scale)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

local function stroke(parent, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color or INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

-- A white rounded sticker with an emoji, filling one face of a part.
function Build.emojiFace(part, face, emoji)
	local gui = Build.surfaceGui(part, face, 90)
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.new(1, 1, 1)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	corner(bg, 0.18)
	stroke(bg, 3)

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.82, 0.82)
	label.BackgroundTransparency = 1
	label.Text = emoji
	label.TextScaled = true
	label.FontFace = Fonts.body
	label.Parent = bg
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = label
	return gui
end

-- A rounded coloured sign with an optional emoji on the left and a text label
-- named "Name" (the client swaps its text when the language changes).
function Build.signGui(part, face, color, emoji, text, textColor)
	local gui = Build.surfaceGui(part, face, 40)
	local bg = Instance.new("Frame")
	bg.Name = "Bg"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = color
	bg.BorderSizePixel = 0
	bg.Parent = gui
	corner(bg, 0.25)
	stroke(bg, 6)

	local left = 0.05
	if emoji then
		local e = Instance.new("TextLabel")
		e.BackgroundTransparency = 1
		e.Position = UDim2.fromScale(0.03, 0.1)
		e.Size = UDim2.fromScale(0.18, 0.8)
		e.Text = emoji
		e.TextScaled = true
		e.FontFace = Fonts.body
		e.Parent = bg
		left = 0.23
	end

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromScale(left, 0.14)
	name.Size = UDim2.fromScale(0.95 - left, 0.72)
	name.Text = text
	name.TextScaled = true
	name.FontFace = Fonts.display
	name.TextColor3 = textColor or Color3.new(1, 1, 1)
	name.TextXAlignment = if emoji then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
	name.Parent = bg
	return gui
end

return Build
