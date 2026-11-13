-- All on-screen UI, built in code in the web game's chunky "sticker" style:
-- white panels with thick navy outlines, bright buttons with a pressed lip.
--
-- Two ScreenGuis:
--   NutriHud   - quest list, top bar, toasts, Spike's dialog (stays below Roblox's top bar)
--   NutriModal - product card, quest complete, final, help, title screen (full screen)
--
-- Ui never decides game rules; it renders what init.client tells it and calls
-- back through the `handlers` table.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Fonts = require(Shared.Fonts)
local GameData = require(Shared.GameData)
local NutriScore = require(Shared.NutriScore)
local Quest = require(Shared.Quest)
local Text = require(Shared.Text)

local C = Config.UI
local NS = Config.NS
local NSC = Config.NS_COLORS
local S = Config.SCALE
local WHITE = Color3.new(1, 1, 1)
local DISPLAY = Fonts.display
local BODY = Fonts.body

local Ui = {}

local lang = "en"
local handlers = {}
local refs = {}
local hudScales, modalScales = {}, {}
local spikeTemplate = nil
local toastToken = 0

local function t(key, vars)
	return Text.get(lang, key, vars)
end

local function escape(s)
	return (string.gsub(s, "[&<>]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }))
end

---------------------------------------------------------------- building blocks

local function make(className, props, children)
	local inst = Instance.new(className)
	local parent = nil
	for k, v in props or {} do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(px)
	return make("UICorner", { CornerRadius = UDim.new(0, px) })
end

local function round()
	return make("UICorner", { CornerRadius = UDim.new(1, 0) })
end

local function outline(thickness, color)
	return make("UIStroke", {
		Thickness = thickness or 3,
		Color = color or C.ink,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function textOutline(thickness, color)
	return make("UIStroke", { Thickness = thickness, Color = color })
end

local function pad(x, y)
	y = y or x
	return make("UIPadding", {
		PaddingLeft = UDim.new(0, x),
		PaddingRight = UDim.new(0, x),
		PaddingTop = UDim.new(0, y),
		PaddingBottom = UDim.new(0, y),
	})
end

local function vlist(gap, align)
	return make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
	})
end

local function hlist(gap, align, valign)
	return make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = valign or Enum.VerticalAlignment.Center,
	})
end

local function label(props, children)
	local base = {
		BackgroundTransparency = 1,
		FontFace = BODY,
		TextColor3 = C.ink,
		TextSize = 18,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}
	for k, v in props do
		base[k] = v
	end
	return make("TextLabel", base, children)
end

local function frame(props, children)
	local base = { BackgroundTransparency = 1, BorderSizePixel = 0 }
	for k, v in props do
		base[k] = v
	end
	return make("Frame", base, children)
end

local function clear(container)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Chunky button with a darker lip underneath that "presses" on click.
local function button(props)
	local radius = props.radius or 16
	local btn = make("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = C.ink,
		Size = props.size,
		LayoutOrder = props.order or 0,
		Parent = props.parent,
	}, { corner(radius) })
	local face = label({
		Name = "Face",
		Size = UDim2.new(1, 0, 1, -4),
		BackgroundTransparency = 0,
		BackgroundColor3 = props.color or C.accent,
		Text = props.text or "",
		FontFace = DISPLAY,
		TextSize = props.textSize or 22,
		TextColor3 = props.textColor or WHITE,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = btn,
	}, { corner(radius), outline(3) })
	local function up()
		face.Position = UDim2.new()
	end
	btn.MouseButton1Down:Connect(function()
		face.Position = UDim2.fromOffset(0, 3)
	end)
	btn.MouseButton1Up:Connect(up)
	btn.MouseLeave:Connect(up)
	if props.onClick then
		btn.Activated:Connect(function()
			props.onClick()
		end)
	end
	return btn, face
end

local function iconButton(text, onClick, order, parent)
	local btn = make("TextButton", {
		Size = UDim2.fromOffset(42, 42),
		BackgroundColor3 = WHITE,
		Text = text,
		FontFace = DISPLAY,
		TextSize = 20,
		TextColor3 = C.ink,
		AutoButtonColor = true,
		LayoutOrder = order,
		Parent = parent,
	}, { round(), outline(3) })
	btn.Activated:Connect(function()
		onClick()
	end)
	return btn
end

local function pill(order, parent)
	return label({
		Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0,
		BackgroundColor3 = WHITE,
		FontFace = DISPLAY,
		TextSize = 18,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = order,
		Parent = parent,
	}, { round(), outline(3), pad(12, 0) })
end

-- Little coloured letter square; grade "any" draws the A→E rainbow.
local function mini(grade, size, order)
	size = size or 22
	if grade == "any" then
		return frame({
			Size = UDim2.fromOffset(size * 1.6, size),
			BackgroundTransparency = 0,
			BackgroundColor3 = WHITE,
			LayoutOrder = order or 0,
		}, {
			corner(math.floor(size * 0.28)),
			make("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, NSC.A),
					ColorSequenceKeypoint.new(0.25, NSC.B),
					ColorSequenceKeypoint.new(0.5, NSC.C),
					ColorSequenceKeypoint.new(0.75, NSC.D),
					ColorSequenceKeypoint.new(1, NSC.E),
				}),
			}),
		})
	end
	return label({
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 0,
		BackgroundColor3 = NSC[grade],
		Text = grade,
		FontFace = DISPLAY,
		TextSize = math.floor(size * 0.72),
		TextColor3 = if grade == "C" then C.ink else WHITE,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = order or 0,
	}, { corner(math.floor(size * 0.28)) })
end

-- The A–E Nutri-Score strip. `selected` letter is enlarged; with `pick`,
-- the other letters fade.
local function strip(selected, pick, parent, order)
	local f = frame({
		Size = UDim2.fromOffset(0, 60),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0,
		BackgroundColor3 = WHITE,
		LayoutOrder = order or 0,
		Parent = parent,
	}, { corner(14), outline(3), pad(10, 0), hlist(2, nil, Enum.VerticalAlignment.Center) })
	local holder = frame({ Size = UDim2.fromOffset(16, 54), LayoutOrder = 0, Parent = f })
	label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(54, 12),
		Rotation = -90,
		Text = "NUTRI-SCORE",
		FontFace = DISPLAY,
		TextScaled = true,
		TextWrapped = false,
		TextColor3 = C.muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = holder,
	})
	for i, g in NS do
		local on = g == selected
		local tile = label({
			Size = if on then UDim2.fromOffset(48, 48) else UDim2.fromOffset(38, 38),
			BackgroundTransparency = if pick and not on then 0.5 else 0,
			BackgroundColor3 = NSC[g],
			Text = g,
			FontFace = DISPLAY,
			TextSize = if on then 30 else 24,
			TextTransparency = if pick and not on then 0.35 else 0,
			TextColor3 = if g == "C" then C.ink else WHITE,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = i,
			ZIndex = if on then 2 else 1,
			Parent = f,
		}, { corner(if on then 10 else 6) })
		if on then
			outline(3, WHITE).Parent = tile
		end
	end
	return f
end

-- Spike's face: a live 3D view of a copy of his model.
local function face(size, parent, order)
	local vp = make("ViewportFrame", {
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = C.panel2,
		Ambient = Color3.fromRGB(190, 190, 200),
		LightColor = WHITE,
		LightDirection = Vector3.new(-0.5, -1, -1),
		LayoutOrder = order or 0,
		Parent = parent,
	}, { corner(math.floor(size * 0.3)), outline(3) })
	if spikeTemplate then
		local clone = spikeTemplate:Clone()
		clone.Parent = vp
		local camera = make("Camera", { FieldOfView = 30, Parent = vp })
		vp.CurrentCamera = camera
		local base = CFrame.new(Config.SPIKE_POS * S)
		local look = (base * CFrame.new(0, 1.4 * S, 0.3 * S)).Position
		local from = (base * CFrame.new(0.35 * S, 1.65 * S, 3.6 * S)).Position
		camera.CFrame = CFrame.lookAt(from, look)
	end
	return vp
end

local function hudScale(inst)
	local s = make("UIScale", { Parent = inst })
	table.insert(hudScales, s)
	return s
end

local function modalScale(inst)
	local s = make("UIScale", { Parent = inst })
	table.insert(modalScales, s)
	return s
end

local function updateScales()
	local size = workspace.CurrentCamera.ViewportSize
	local hud = math.clamp(math.min(size.X / 1050, size.Y / 680), 0.6, 1)
	local modal = math.clamp(math.min(size.X / 540, size.Y / 820), 0.5, 1.1)
	for _, s in hudScales do
		s.Scale = hud
	end
	for _, s in modalScales do
		s.Scale = modal
	end
end

-- A dimmed full-screen layer with a centred white sheet. Clicking the dim
-- area calls `onDim` (if given).
local function modalSheet(name, width, onDim)
	local dim = make("TextButton", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.ink,
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		Parent = refs.modal,
	})
	if onDim then
		dim.Activated:Connect(onDim)
	end
	local sheet = frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		BackgroundColor3 = C.panel,
		Active = true,
		Parent = dim,
	}, { corner(18), outline(3), pad(18, 18), vlist(12, Enum.HorizontalAlignment.Center) })
	modalScale(sheet)
	return dim, sheet
end

local function closeButton(parent, onClick)
	local x = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = WHITE,
		Text = "×",
		FontFace = DISPLAY,
		TextSize = 26,
		TextColor3 = C.ink,
		ZIndex = 3,
		Parent = parent,
	}, { round(), outline(3) })
	x.Activated:Connect(onClick)
	return x
end

-- Springs an element in from nothing. Sheets already carry the screen-size
-- UIScale, so they grow back to that size rather than to 1.
local function popIn(inst, delay)
	local scale = inst:FindFirstChildOfClass("UIScale")
	local target = 1
	if scale and table.find(modalScales, scale) then
		target = scale.Scale
	elseif not scale then
		scale = make("UIScale", { Parent = inst })
	end
	scale.Scale = 0
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, delay or 0), { Scale = target }):Play()
end

---------------------------------------------------------------- HUD

local function buildHud()
	-- Quest card, top-left
	local quest = frame({
		Name = "Quest",
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(440, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		BackgroundColor3 = C.panel,
		Visible = false,
		Parent = refs.hud,
	}, { corner(18), outline(3), pad(8, 8), vlist(8) })
	hudScale(quest)
	local head = make("TextButton", {
		Name = "Head",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.ink,
		LayoutOrder = 1,
		Parent = quest,
	}, { corner(12), pad(12, 9), vlist(4) })
	local row = frame({ Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = head })
	refs.qNum = label({ Size = UDim2.new(1, -70, 1, 0), TextColor3 = WHITE, TextTransparency = 0.2, TextSize = 14, FontFace = DISPLAY, Parent = row })
	refs.qProg = label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(56, 22),
		BackgroundTransparency = 0,
		BackgroundColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = DISPLAY,
		TextSize = 16,
		Parent = row,
	}, { round() })
	refs.qTitle = label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextColor3 = WHITE,
		FontFace = DISPLAY,
		TextSize = 22,
		LayoutOrder = 2,
		Parent = head,
	})
	refs.slots = frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = quest }, { vlist(6) })
	head.Activated:Connect(function()
		refs.slots.Visible = not refs.slots.Visible
	end)
	refs.quest = quest

	-- Top bar, centred (Roblox's player list lives top-right)
	local bar = frame({
		Name = "Bar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		Parent = refs.hud,
	}, { hlist(8, Enum.HorizontalAlignment.Center) })
	hudScale(bar)
	refs.scorePill = pill(1, bar)
	refs.foundPill = pill(2, bar)
	refs.hintBtn = iconButton("⭐", handlers.onHint, 3, bar)
	refs.hintBtn.TextSize = 22
	refs.langBtn = iconButton("EN", handlers.onCycleLang, 4, bar)
	refs.langBtn.TextSize = 16
	refs.soundBtn = iconButton("🔊", handlers.onSound, 5, bar)
	refs.helpBtn = iconButton("?", handlers.onHelp, 6, bar)
	refs.bar = bar
end

local function needChips(max, parent)
	if max == "E" then
		mini("any", 26, 1).Parent = parent
		label({ Text = t("anyGrade"), TextSize = 17, TextColor3 = C.muted, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), TextWrapped = false, LayoutOrder = 2, Parent = parent })
	elseif max == "A" then
		mini("A", 26, 1).Parent = parent
		label({ Text = t("onlyA"), TextSize = 17, TextColor3 = C.muted, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), TextWrapped = false, LayoutOrder = 2, Parent = parent })
	else
		mini(max, 26, 1).Parent = parent
		local words = string.gsub(t("orBetter", { g = "" }), "^%s+", "")
		label({ Text = words, TextSize = 17, TextColor3 = C.muted, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), TextWrapped = false, LayoutOrder = 2, Parent = parent })
	end
end

local function renderSlots(state)
	clear(refs.slots)
	for i, def in Quest.slotsOf(state.q) do
		local id = state.filled[i]
		local p = id and GameData.PRODUCT_BY_ID[id]
		local row = frame({
			Size = UDim2.new(1, 0, 0, 56),
			BackgroundTransparency = 0,
			BackgroundColor3 = if p then C.doneRow else C.panel2,
			LayoutOrder = i,
			Parent = refs.slots,
		}, { corner(12) })
		label({
			Text = if p then p.e else def.e,
			TextSize = 32,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTransparency = if p then 0 else 0.45,
			Position = UDim2.fromOffset(6, 0),
			Size = UDim2.new(0, 40, 1, 0),
			Parent = row,
		})
		local name = if p then Text.name(lang, p.nm) else Text.name(lang, def.lbl)
		label({
			Text = if p then "<s>" .. escape(name) .. "</s>" else escape(name),
			RichText = true,
			TextSize = 20,
			TextColor3 = if p then C.muted else C.ink,
			Position = UDim2.fromOffset(54, 0),
			Size = UDim2.new(1, -205, 1, 0),
			Parent = row,
		})
		local need = frame({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = row,
		}, { hlist(4, Enum.HorizontalAlignment.Right) })
		if p then
			mini(p.ns.grade, 26, 1).Parent = need
		else
			needChips(def.max, need)
		end
	end
end

function Ui.renderHUD(state, soundOn)
	if not state then
		return
	end
	local q = GameData.QUESTS[state.q]
	local slots = Quest.slotsOf(state.q)
	refs.qNum.Text = Text.upper(t("quest")) .. " " .. state.q .. "/" .. #GameData.QUESTS
	refs.qTitle.Text = q.e .. " " .. Text.name(lang, q.title)
	refs.qProg.Text = (#slots - Quest.remaining(state.filled)) .. "/" .. #slots
	renderSlots(state)

	local found = 0
	for _ in state.discovered do
		found += 1
	end
	refs.scorePill.Text = t("points") .. " " .. state.score
	refs.foundPill.Text = t("found") .. " " .. found .. "/" .. #GameData.PRODUCTS
	refs.langBtn.Text = Text.upper(lang)
	refs.soundBtn.Text = if soundOn then "🔊" else "🔇"
end

function Ui.setHudVisible(questVisible, barVisible)
	refs.quest.Visible = questVisible
	refs.bar.Visible = barVisible
end

-- "+10" floating up under the top bar.
function Ui.pop(text)
	local l = label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 58),
		Size = UDim2.fromOffset(120, 44),
		Text = text,
		FontFace = DISPLAY,
		TextSize = 36,
		TextColor3 = NSC.A,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = refs.hud,
	}, { textOutline(2.5, WHITE) })
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(l, info, { Position = UDim2.new(0.5, 0, 0, 0), TextTransparency = 1 }):Play()
	TweenService:Create(l:FindFirstChildOfClass("UIStroke"), info, { Transparency = 1 }):Play()
	task.delay(1.2, function()
		l:Destroy()
	end)
end

---------------------------------------------------------------- toast

local function buildToast()
	local toast = frame({
		Name = "Toast",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -130),
		Size = UDim2.new(1, -32, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		BackgroundColor3 = C.panel,
		Visible = false,
		Parent = refs.hud,
	}, { corner(18), pad(14, 10), make("UISizeConstraint", { MaxSize = Vector2.new(560, math.huge) }) })
	hudScale(toast)
	refs.toastStroke = outline(3)
	refs.toastStroke.Parent = toast
	face(52, toast)
	refs.toastText = label({
		Position = UDim2.fromOffset(66, 0),
		Size = UDim2.new(1, -66, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 20,
		Parent = toast,
	}, { make("UISizeConstraint", { MinSize = Vector2.new(0, 52) }) })
	refs.toastText.TextYAlignment = Enum.TextYAlignment.Center
	refs.toast = toast
end

function Ui.toast(message, kind, seconds)
	refs.toastText.Text = message
	refs.toastStroke.Color = if kind == "good" then C.good elseif kind == "bad" then NSC.D else C.ink
	refs.toastStroke.Thickness = if kind then 4 else 3
	refs.toast.Visible = true
	toastToken += 1
	local mine = toastToken
	task.delay(seconds or 3.8, function()
		if toastToken == mine then
			refs.toast.Visible = false
		end
	end)
end

---------------------------------------------------------------- dialog

local function buildDialog()
	local dialog = frame({
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		BackgroundColor3 = C.panel,
		Visible = false,
		Parent = refs.hud,
	}, { corner(18), outline(3), pad(16, 14), make("UISizeConstraint", { MaxSize = Vector2.new(720, math.huge) }) })
	hudScale(dialog)
	face(84, dialog)
	local body = frame({
		Position = UDim2.fromOffset(100, 0),
		Size = UDim2.new(1, -100, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = dialog,
	}, { vlist(8) })
	refs.dlgName = label({ FontFace = DISPLAY, TextColor3 = C.quill, TextSize = 19, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = body })
	refs.dlgText = label({
		TextSize = 23,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LineHeight = 1.15,
		LayoutOrder = 2,
		Parent = body,
	}, { make("UISizeConstraint", { MinSize = Vector2.new(0, 72) }) })
	refs.dlgStrip = frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = body })
	local actions = frame({ Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 4, Parent = body })
	local next, nextFace = button({ text = "", size = UDim2.fromOffset(170, 46), parent = actions, onClick = handlers.onDialogNext })
	next.AnchorPoint = Vector2.new(1, 0)
	next.Position = UDim2.fromScale(1, 0)
	refs.dlgNextFace = nextFace
	refs.dialog = dialog
end

function Ui.showDialog(visible)
	refs.dialog.Visible = visible
	if visible then
		refs.toast.Visible = false
	end
end

-- Shows one line. `visible` is how many characters are typed out so far.
function Ui.setDialog(name, text, scale, nextLabel, visible)
	refs.dlgName.Text = Text.upper(name)
	refs.dlgText.Text = text
	refs.dlgText.MaxVisibleGraphemes = visible
	refs.dlgNextFace.Text = nextLabel
	clear(refs.dlgStrip)
	if scale then
		strip(if scale == "all" then nil else scale, scale ~= "all", refs.dlgStrip)
	end
end

function Ui.setDialogVisible(visible)
	refs.dlgText.MaxVisibleGraphemes = visible
end

---------------------------------------------------------------- product card

local function factRow(order, name, value, chipFrame)
	local row = frame({ Size = UDim2.new(1, 0, 0, 32), LayoutOrder = order, Parent = refs.facts })
	label({ Text = name, Size = UDim2.new(1, -160, 1, 0), TextSize = 17, Parent = row })
	label({
		Text = value,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -66, 0, 0),
		Size = UDim2.fromOffset(92, 32),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 17,
		Parent = row,
	})
	if chipFrame then
		chipFrame.AnchorPoint = Vector2.new(1, 0.5)
		chipFrame.Position = UDim2.new(1, 0, 0.5, 0)
		chipFrame.Parent = row
	end
	frame({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.line,
		Parent = row,
	})
end

local function chip(value, kind, skipped)
	local text, bg, fg = "0", C.zero, C.ink
	if skipped then
		text, bg = "<s>+" .. value .. "</s>", C.zero
	elseif value > 0 then
		text = (if kind == "bad" then "−" else "+") .. value
		bg = if kind == "bad" then C.bad else C.good
		fg = WHITE
	end
	return label({
		Size = UDim2.fromOffset(52, 24),
		BackgroundTransparency = 0,
		BackgroundColor3 = bg,
		Text = text,
		RichText = true,
		FontFace = DISPLAY,
		TextSize = 16,
		TextColor3 = fg,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, { round() })
end

local function num(value)
	return tostring(value)
end

local function renderFacts(p, revealed)
	clear(refs.facts)
	local r = p.ns
	local n = NutriScore.nutrients(p)
	local order = 0
	local function add(key, value, points, kind, skipped)
		order += 1
		local c = if revealed and points ~= nil then chip(points, kind, skipped) else nil
		factRow(order, t(key), value, c)
	end
	if r.water then
		add("energy", "0 kJ", 0, "bad")
		add("sugar", "0 g", 0, "bad")
		return
	end
	add("energy", if p.cat == "fat" then math.floor(n.sf * 37 + 0.5) .. " kJ" else num(n.kj) .. " kJ", r.bad.energy, "bad")
	if p.cat == "fat" then
		add("fat", num(n.fat) .. " g", nil)
	end
	add("sugar", num(n.sug) .. " g", r.bad.sugar, "bad")
	add("satfat", num(n.sf) .. " g", r.bad.satfat, "bad")
	add("salt", num(n.salt) .. " g", r.bad.salt, "bad")
	if n.sweet then
		add("sweet", t("yes"), r.bad.sweet, "bad")
	end
	add("fiber", num(n.fib) .. " g", r.good.fiber, "good")
	add("protein", num(n.pro) .. " g", if r.proteinCounted then r.good.protein else r.proteinRaw, "good", not r.proteinCounted and r.proteinRaw > 0)
	add("fvl", num(n.fvl) .. " %", r.good.fvl, "good")
end

local function buildCard()
	local dim, sheet = modalSheet("Card", 500, function()
		handlers.onCloseCard()
	end)
	refs.card = dim

	local head = frame({ Size = UDim2.new(1, 0, 0, 80), LayoutOrder = 1, Parent = sheet })
	refs.cardEmoji = label({
		Size = UDim2.fromOffset(80, 80),
		BackgroundTransparency = 0,
		TextSize = 46,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = head,
	}, { corner(18), outline(3) })
	local info = frame({ Position = UDim2.fromOffset(94, 0), Size = UDim2.new(1, -140, 1, 0), Parent = head }, {
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
		}),
	})
	refs.cardSec = label({ Size = UDim2.new(1, 0, 0, 16), TextSize = 13, TextColor3 = C.muted, LayoutOrder = 1, Parent = info })
	refs.cardName = label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, FontFace = DISPLAY, TextSize = 26, LayoutOrder = 2, Parent = info })
	refs.cardPer = label({ Size = UDim2.new(1, 0, 0, 16), TextSize = 14, TextColor3 = C.muted, LayoutOrder = 3, Parent = info })
	closeButton(head, function()
		handlers.onCloseCard()
	end)

	refs.facts = frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = sheet }, { vlist(0) })

	-- Guess area
	local guess = frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = sheet }, { vlist(10, Enum.HorizontalAlignment.Center) })
	refs.guessQ = label({ Size = UDim2.new(1, 0, 0, 30), FontFace = DISPLAY, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1, Parent = guess })
	local row = frame({ Size = UDim2.new(1, 0, 0, 76), LayoutOrder = 2, Parent = guess }, { hlist(10, Enum.HorizontalAlignment.Center) })
	for i, g in NS do
		button({
			text = g,
			color = NSC[g],
			textColor = if g == "C" then C.ink else WHITE,
			size = UDim2.fromOffset(80, 74),
			textSize = 40,
			radius = 14,
			order = i,
			parent = row,
			onClick = function()
				handlers.onGuess(g)
			end,
		})
	end
	refs.guessHint = label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 15, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 3, Parent = guess })
	refs.guessArea = guess

	-- Reveal area
	local reveal = frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, Visible = false, Parent = sheet }, { vlist(10, Enum.HorizontalAlignment.Center) })
	refs.verdict = label({ Size = UDim2.new(1, 0, 0, 30), FontFace = DISPLAY, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1, Parent = reveal })
	refs.cardStrip = frame({ Size = UDim2.fromOffset(0, 60), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, Parent = reveal })
	refs.calc = frame({ Size = UDim2.new(1, 0, 0, 74), LayoutOrder = 3, Parent = reveal }, { hlist(6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top) })
	refs.why = label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 4, Parent = reveal })
	refs.note = label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 5, Parent = reveal })
	local actions = frame({ Size = UDim2.new(1, 0, 0, 52), LayoutOrder = 6, Parent = reveal }, { hlist(10, Enum.HorizontalAlignment.Center) })
	local _, addFace = button({ size = UDim2.fromOffset(230, 52), parent = actions, order = 1, onClick = handlers.onAdd })
	local _, backFace = button({ size = UDim2.fromOffset(190, 52), color = WHITE, textColor = C.ink, parent = actions, order = 2, onClick = handlers.onBack })
	refs.addFace, refs.backFace = addFace, backFace
	refs.revealArea = reveal
end

local function calcColumn(order, value, kind, caption)
	local col = frame({ Size = UDim2.fromOffset(74, 74), LayoutOrder = order, Parent = refs.calc }, { vlist(2, Enum.HorizontalAlignment.Center) })
	label({
		Size = UDim2.fromOffset(46, 46),
		BackgroundTransparency = 0,
		BackgroundColor3 = if kind == "bad" then C.bad elseif kind == "good" then C.good else WHITE,
		Text = tostring(value),
		FontFace = DISPLAY,
		TextSize = 24,
		TextColor3 = if kind == "res" then C.ink else WHITE,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = col,
	}, { corner(12), outline(3) })
	label({ Size = UDim2.new(1, 0, 0, 24), Text = caption, TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2, Parent = col })
end

local function calcSign(order, text)
	label({ Size = UDim2.fromOffset(16, 46), Text = text, FontFace = DISPLAY, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = order, Parent = refs.calc })
end

-- card = { p = product, guess = letter | "seen" | nil }
function Ui.renderCard(card)
	local p = card.p
	local r = p.ns
	local sec = GameData.SECTION_BY_ID[p.s]
	local revealed = card.guess ~= nil

	refs.cardEmoji.Text = p.e
	refs.cardEmoji.BackgroundColor3 = Color3.fromHex(p.c)
	refs.cardSec.Text = sec.e .. " " .. Text.upper(Text.name(lang, sec.nm))
	refs.cardName.Text = Text.name(lang, p.nm)
	refs.cardPer.Text = if p.cat == "drink" or p.cat == "water" then t("per100ml") else t("per100g")
	renderFacts(p, revealed)

	refs.guessArea.Visible = not revealed
	refs.revealArea.Visible = revealed
	if not revealed then
		refs.guessQ.Text = t("guessQ")
		refs.guessHint.Text = t("guessHint")
		return
	end

	local diff = nil
	if card.guess ~= "seen" then
		diff = math.abs(Quest.gradeIndex(card.guess) - Quest.gradeIndex(r.grade))
	end
	refs.verdict.Text = if diff == nil then t("seen", { g = r.grade }) elseif diff == 0 then t("right") elseif diff == 1 then t("close") else t("wrongG", { g = r.grade })
	refs.verdict.TextColor3 = if diff == 0 then NSC.A else C.ink

	clear(refs.cardStrip)
	strip(r.grade, true, refs.cardStrip)

	clear(refs.calc)
	if r.water then
		refs.calc.Visible = false
		refs.why.Text = t("water")
	else
		refs.calc.Visible = true
		calcColumn(1, r.N, "bad", t("badPts"))
		calcSign(2, "−")
		calcColumn(3, r.P, "good", t("goodPts"))
		calcSign(4, "=")
		calcColumn(5, r.S, "res", t("scoreW"))
		calcSign(6, "›")
		local gradeCol = frame({ Size = UDim2.fromOffset(52, 74), LayoutOrder = 7, Parent = refs.calc })
		local m = mini(r.grade, 46)
		outline(3).Parent = m
		m.Parent = gradeCol

		local bestBad, bestGood = nil, nil
		for _, k in NutriScore.BAD_KEYS do
			local v = r.bad[k]
			if v and v > 0 and (bestBad == nil or v > r.bad[bestBad]) then
				bestBad = k
			end
		end
		for _, k in NutriScore.GOOD_KEYS do
			local v = r.good[k]
			if v and v > 0 and (bestGood == nil or v > r.good[bestGood]) then
				bestGood = k
			end
		end
		if not bestBad then
			refs.why.Text = t("whyNoBad")
		elseif bestGood then
			refs.why.Text = t("why", { bad = Text.lower(t(bestBad)), good = Text.lower(t(bestGood)) })
		else
			refs.why.Text = t("whyNoGood", { bad = Text.lower(t(bestBad)) })
		end
	end

	local notes = {}
	if p.cat == "fat" then
		table.insert(notes, t("noteFat"))
	end
	if p.cat == "cheese" then
		table.insert(notes, t("noteCheese"))
	end
	if p.cat == "drink" then
		table.insert(notes, t("noteDrink"))
	end
	if not r.proteinCounted and r.proteinRaw > 0 then
		table.insert(notes, t("noteProtein"))
	end
	refs.note.Text = table.concat(notes, " ")
	refs.note.Visible = #notes > 0

	refs.addFace.Text = "🧺 " .. t("add")
	refs.backFace.Text = t("back")
end

function Ui.showCard(card)
	Ui.renderCard(card)
	refs.card.Visible = true
	popIn(refs.card:FindFirstChildOfClass("Frame"))
end

function Ui.hideCard()
	refs.card.Visible = false
end

---------------------------------------------------------------- quest complete

local completeData = nil

local function buildComplete()
	local dim, sheet = modalSheet("Complete", 460)
	refs.complete = dim
	refs.cTitle = label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, FontFace = DISPLAY, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1, Parent = sheet })
	refs.cStars = frame({ Size = UDim2.new(1, 0, 0, 72), LayoutOrder = 2, Parent = sheet }, { hlist(8, Enum.HorizontalAlignment.Center) })
	refs.cList = frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = sheet }, { vlist(6) })
	refs.cPts = label({ Size = UDim2.new(1, 0, 0, 30), FontFace = DISPLAY, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 4, Parent = sheet })
	local _, nextFace = button({ size = UDim2.fromOffset(260, 58), textSize = 26, order = 5, parent = sheet, onClick = handlers.onNextQuest })
	refs.cNextFace = nextFace
end

local function bigStars(container, count, total)
	clear(container)
	for i = 1, total do
		local on = i <= count
		-- ⭐ is an emoji: no Roblox font has a ★ glyph. Missed stars are faded.
		local star = label({
			Size = UDim2.fromOffset(70, 70),
			Text = "⭐",
			TextSize = 58,
			TextTransparency = if on then 0 else 0.78,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = i,
			Parent = container,
		})
		if on then
			popIn(star, (i - 1) * 0.18)
		end
	end
end

function Ui.renderComplete()
	local d = completeData
	if not d then
		return
	end
	local q = GameData.QUESTS[d.q]
	refs.cTitle.Text = q.e .. " " .. t("done")
	local count = 0
	for _, on in d.stars do
		if on then
			count += 1
		end
	end
	clear(refs.cList)
	for i, key in { "s1", "s2", "s3" } do
		local on = d.stars[i]
		frame({
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundTransparency = if on then 0 else 0.5,
			BackgroundColor3 = C.panel2,
			LayoutOrder = i,
			Parent = refs.cList,
		}, {
			corner(10),
			label({ Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0, 30, 1, 0), Text = "⭐", TextSize = 22, TextTransparency = if on then 0 else 0.78 }),
			label({ Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -50, 1, 0), Text = t(key), TextSize = 17, TextTransparency = if on then 0 else 0.4 }),
		})
	end
	refs.cPts.Text = t("points") .. ": " .. d.score
	refs.cNextFace.Text = if d.q < #GameData.QUESTS then t("nextQ") .. " ›" else t("finish")
	return count
end

function Ui.showComplete(questIndex, stars, score)
	completeData = { q = questIndex, stars = stars, score = score }
	local count = Ui.renderComplete()
	bigStars(refs.cStars, count, 3)
	refs.complete.Visible = true
	popIn(refs.complete:FindFirstChildOfClass("Frame"))
end

function Ui.hideComplete()
	refs.complete.Visible = false
end

---------------------------------------------------------------- final

local finalData = nil

local function buildFinal()
	local dim, sheet = modalSheet("Final", 460)
	refs.final = dim
	face(120, sheet, 1)
	refs.fTitle = label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, FontFace = DISPLAY, TextSize = 32, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2, Parent = sheet })
	refs.fStars = frame({ Size = UDim2.new(1, 0, 0, 72), LayoutOrder = 3, Parent = sheet }, { hlist(8, Enum.HorizontalAlignment.Center) })
	refs.fText = label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 4, Parent = sheet })
	local _, againFace = button({ size = UDim2.fromOffset(240, 58), textSize = 26, order = 5, parent = sheet, onClick = handlers.onAgain })
	refs.fAgainFace = againFace
end

function Ui.renderFinal()
	local d = finalData
	if not d then
		return
	end
	refs.fTitle.Text = t("finalT")
	refs.fText.Text = t("finalText", { s = d.stars, p = d.score })
	refs.fAgainFace.Text = t("again")
end

function Ui.showFinal(totalStars, score)
	finalData = { stars = totalStars, score = score }
	Ui.renderFinal()
	bigStars(refs.fStars, math.max(1, math.floor(totalStars / 6 + 0.5)), 3)
	refs.final.Visible = true
	popIn(refs.final:FindFirstChildOfClass("Frame"))
end

function Ui.hideFinal()
	refs.final.Visible = false
end

---------------------------------------------------------------- help

local function buildHelp()
	local dim, sheet = modalSheet("Help", 480, function()
		handlers.onCloseHelp()
	end)
	refs.help = dim
	local head = frame({ Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 1, Parent = sheet })
	refs.hTitle = label({ Size = UDim2.new(1, -50, 1, 0), FontFace = DISPLAY, TextSize = 28, Parent = head })
	closeButton(head, function()
		handlers.onCloseHelp()
	end)
	refs.hList = frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = sheet }, { vlist(8) })
	strip(nil, false, sheet, 3)
	refs.hScale = label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 17, LayoutOrder = 4, Parent = sheet })
end

function Ui.renderHelp()
	refs.hTitle.Text = t("help")
	clear(refs.hList)
	for i, key in { "h1", "h2", "h3", "h4" } do
		label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "•  " .. t(key), TextSize = 17, LayoutOrder = i, Parent = refs.hList })
	end
	refs.hScale.Text = t("hScale")
end

function Ui.showHelp()
	Ui.renderHelp()
	refs.help.Visible = true
	popIn(refs.help:FindFirstChildOfClass("Frame"))
end

function Ui.hideHelp()
	refs.help.Visible = false
end

---------------------------------------------------------------- title

local function buildTitle()
	local screen = frame({
		Name = "Title",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.ink,
		Visible = false,
		Parent = refs.modal,
	}, {
		make("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.45, 1),
				NumberSequenceKeypoint.new(1, 0.4),
			}),
		}),
	})
	local card = frame({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(580, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		BackgroundColor3 = C.panel,
		Parent = screen,
	}, { corner(22), outline(3), pad(22, 20), vlist(14, Enum.HorizontalAlignment.Center) })
	modalScale(card)

	local abc = frame({ Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 1, Parent = card }, { hlist(4) })
	for i, g in NS do
		mini(g, 38, i).Parent = abc
	end
	refs.tName = label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, FontFace = DISPLAY, TextSize = 46, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2, Parent = card })
	refs.tTag = label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 18, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 3, Parent = card })

	local langs = frame({ Size = UDim2.fromOffset(0, 46), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 4, Parent = card }, { hlist(8) })
	refs.langButtons = {}
	for i, entry in { { "lv", "Latviešu" }, { "ru", "Русский" }, { "en", "English" } } do
		local _, btnFace = button({
			text = entry[2],
			color = WHITE,
			textColor = C.ink,
			size = UDim2.fromOffset(140, 46),
			textSize = 20,
			radius = 14,
			order = i,
			parent = langs,
			onClick = function()
				handlers.onLang(entry[1])
			end,
		})
		refs.langButtons[entry[1]] = btnFace
	end

	local _, playFace = button({ size = UDim2.fromOffset(260, 62), textSize = 30, order = 5, parent = card, onClick = handlers.onPlay })
	refs.playFace = playFace
	refs.newBtn = make("TextButton", {
		Size = UDim2.fromOffset(240, 26),
		BackgroundTransparency = 1,
		FontFace = BODY,
		TextSize = 16,
		TextColor3 = C.muted,
		RichText = true,
		LayoutOrder = 6,
		Parent = card,
	})
	refs.newBtn.Activated:Connect(function()
		handlers.onNewGame()
	end)
	refs.title = screen
end

function Ui.renderTitle(state)
	refs.tName.Text = t("game")
	refs.tTag.Text = t("tag")
	local started = state.introDone or state.score > 0
	refs.playFace.Text = if started and not state.finished then t("cont") else t("play")
	refs.newBtn.Text = "<u>" .. escape(t("newGame")) .. "</u>"
	refs.newBtn.Visible = started
	for code, btnFace in refs.langButtons do
		local on = code == lang
		btnFace.BackgroundColor3 = if on then C.ink else WHITE
		btnFace.TextColor3 = if on then WHITE else C.ink
	end
end

function Ui.showTitle(visible)
	refs.title.Visible = visible
end

---------------------------------------------------------------- setup

function Ui.setLang(l)
	lang = l
end

function Ui.init(h, template)
	handlers = h
	spikeTemplate = template
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	refs.hud = make("ScreenGui", {
		Name = "NutriHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 5,
		Parent = playerGui,
	})
	refs.modal = make("ScreenGui", {
		Name = "NutriModal",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10,
		Parent = playerGui,
	})
	buildHud()
	buildToast()
	buildDialog()
	buildTitle()
	buildCard()
	buildComplete()
	buildFinal()
	buildHelp()
	updateScales()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScales)
end

return Ui
