-- Server-side game rules. The server owns every player's progress: the client
-- asks (guess a letter, put something in the basket, finish a quest) and the
-- server checks and answers, so nobody can award themselves points.
--
-- Also: leaderstats (Points / Stars), a shopping cart welded to each avatar,
-- and the sliding doors.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local GameData = require(Shared.GameData)
local Quest = require(Shared.Quest)
local Text = require(Shared.Text)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Build = require(script.Parent.Build)
local Progress = require(script.Parent.Progress)

local S = Config.SCALE
local hex = Build.hex
local PRODUCTS = GameData.PRODUCT_BY_ID

local Gameplay = {}

local states = {} -- [player] = progress table
local canSave = {} -- [player] = loaded OK, so saving is safe
local carts = {} -- [player] = { model, hrp, offset }
local store = nil

---------------------------------------------------------------- helpers

local function ensureBasket(st)
	local size = #Quest.slotsOf(st.q)
	if type(st.filled) ~= "table" or #st.filled ~= size then
		st.filled = Quest.emptyBasket(st.q)
	end
end

local function totalStars(st)
	local n = 0
	for _, v in st.stars do
		n += v
	end
	return n
end

local function updateLeaderstats(player, st)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Points.Value = st.score
		stats.Stars.Value = totalStars(st)
	end
end

local function push(player)
	local st = states[player]
	if st then
		updateLeaderstats(player, st)
		Remotes.StateChanged:FireClient(player, st)
	end
end

local function save(player)
	local st = states[player]
	if st then
		Progress.save(player, st, canSave[player])
	end
end

-- Waits (briefly) for a player's progress to finish loading.
local function stateOf(player)
	local waited = 0
	while not states[player] and player.Parent and waited < 15 do
		waited += task.wait(0.1)
	end
	return states[player]
end

local function nearProduct(player, productId)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local slot = store and store.Products:FindFirstChild(productId)
	if not hrp or not slot or not slot.PrimaryPart then
		return false
	end
	return (hrp.Position - slot.PrimaryPart.Position).Magnitude < 30
end

---------------------------------------------------------------- shopping cart

local CART_PART = { Anchored = false, Massless = true, CanCollide = false, CanTouch = false, CanQuery = false }

local function weld(part, hrp)
	local w = Instance.new("WeldConstraint")
	w.Part0 = hrp
	w.Part1 = part
	w.Parent = part
end

local function rebuildCartContents(player)
	local info = carts[player]
	local st = states[player]
	if not info or not st or not info.model.Parent then
		return
	end
	local old = info.model:FindFirstChild("Contents")
	if old then
		old:Destroy()
	end
	local contents = Instance.new("Model")
	contents.Name = "Contents"
	local origin = info.hrp.CFrame * info.offset
	local n = 0
	for _, id in st.filled do
		local p = id and PRODUCTS[id]
		if p then
			local x = ((n % 3) - 1) * 0.17
			local y = 0.52 + (n // 9) * 0.17
			local z = (((n // 3) % 3) - 1) * 0.15
			local cube = Build.box(contents, origin * CFrame.Angles(0, (math.random() - 0.5) * 0.6, 0), 0.16, 0.16, 0.16, hex(p.c), x, y, z, CART_PART)
			Build.emojiFace(cube, Enum.NormalId.Top, p.e)
			Build.emojiFace(cube, Enum.NormalId.Back, p.e)
			n += 1
		end
	end
	for _, part in contents:GetChildren() do
		weld(part, info.hrp)
	end
	contents.Parent = info.model
end

local function buildCart(player, character)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not hrp or not humanoid then
		return
	end
	local floorOffset = if humanoid.RigType == Enum.HumanoidRigType.R15 then humanoid.HipHeight + hrp.Size.Y / 2 else 3
	-- Cart origin: on the floor, 0.72 m in front of the avatar, local +Z pointing forward.
	local offset = CFrame.new(0, -floorOffset, 0) * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0, 0.72 * S)
	local origin = hrp.CFrame * offset

	local cart = Instance.new("Model")
	cart.Name = "ShoppingCart"
	local ink, metal, pink = Config.UI.ink, hex("#9aa6bb"), hex("#e2477f")
	Build.box(cart, origin, 0.62, 0.4, 0.55, hex("#9fb7d9"), 0, 0.62, 0, Build.merge(CART_PART, {
		Transparency = 0.6,
		Material = Enum.Material.Glass,
	}))
	-- Rim and corner bars
	for _, z in { -0.275, 0.275 } do
		Build.box(cart, origin, 0.64, 0.03, 0.03, ink, 0, 0.82, z, CART_PART)
		Build.box(cart, origin, 0.64, 0.03, 0.03, ink, 0, 0.42, z, CART_PART)
	end
	for _, x in { -0.31, 0.31 } do
		Build.box(cart, origin, 0.03, 0.03, 0.57, ink, x, 0.82, 0, CART_PART)
		for _, z in { -0.275, 0.275 } do
			Build.box(cart, origin, 0.03, 0.4, 0.03, ink, x, 0.62, z, CART_PART)
			Build.box(cart, origin, 0.04, 0.38, 0.04, metal, x * 0.9, 0.25, z * 0.87, CART_PART)
		end
	end
	Build.rod(cart, origin, 0.025, 0.66, pink, 0, 0.92, -0.34, CART_PART)
	for _, x in { -0.25, 0.25 } do
		for _, z in { -0.2, 0.2 } do
			Build.rod(cart, origin, 0.06, 0.04, ink, x, 0.06, z, CART_PART)
		end
	end
	for _, part in cart:GetChildren() do
		weld(part, hrp)
	end

	local old = character:FindFirstChild("ShoppingCart")
	if old then
		old:Destroy()
	end
	cart.Parent = character
	carts[player] = { model = cart, hrp = hrp, offset = offset }
	rebuildCartContents(player)
end

---------------------------------------------------------------- doors

local function runDoors()
	local doors = store.Building.Doors
	local left, right = doors.DoorL, doors.DoorR
	local leftClosed, rightClosed = left.Position, right.Position
	local slide = 2.8 * S
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local open = false
	while true do
		task.wait(0.15)
		local someoneNear = false
		for _, player in Players:GetPlayers() do
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local p = hrp.Position / S
				if p.Z > 14.5 and p.Z < 22 and math.abs(p.X) < 5 then
					someoneNear = true
					break
				end
			end
		end
		if someoneNear ~= open then
			open = someoneNear
			local d = if open then slide else 0
			TweenService:Create(left, info, { Position = leftClosed - Vector3.new(d, 0, 0) }):Play()
			TweenService:Create(right, info, { Position = rightClosed + Vector3.new(d, 0, 0) }):Play()
		end
	end
end

---------------------------------------------------------------- remotes

local function bindRemotes()
	Remotes.GetState.OnServerInvoke = function(player)
		return stateOf(player)
	end

	Remotes.SetLanguage.OnServerInvoke = function(player, lang)
		local st = stateOf(player)
		if st and Text.isLang(lang) then
			st.lang = lang
		end
		return true
	end

	Remotes.FinishIntro.OnServerInvoke = function(player)
		local st = stateOf(player)
		if st then
			st.introDone = true
			push(player)
		end
		return true
	end

	-- Guess a product's letter. Returns { grade, diff, points } or { grade, seen = true }.
	Remotes.Guess.OnServerInvoke = function(player, productId, letter)
		local st = stateOf(player)
		local p = type(productId) == "string" and PRODUCTS[productId]
		if not st or not p or type(letter) ~= "string" or not Quest.gradeIndex(letter) then
			return nil
		end
		local grade = p.ns.grade
		if st.discovered[p.id] then
			return { grade = grade, seen = true, state = st }
		end
		st.discovered[p.id] = true
		st.gT += 1
		local diff = math.abs(Quest.gradeIndex(letter) - Quest.gradeIndex(grade))
		local points = 0
		if diff == 0 then
			st.gR += 1
			points = 10
		elseif diff == 1 then
			st.gR += 0.5
			points = 5
		end
		st.score += points
		push(player)
		return { grade = grade, diff = diff, points = points, state = st }
	end

	-- Put a product in the basket. See Quest.evaluateAdd for the results.
	Remotes.AddToBasket.OnServerInvoke = function(player, productId)
		local st = stateOf(player)
		local p = type(productId) == "string" and PRODUCTS[productId]
		if not st or not p or st.finished or st.questDone then
			return nil
		end
		if not nearProduct(player, p.id) then
			return nil
		end
		local res = Quest.evaluateAdd(st.q, st.filled, p)
		if res.result == "tooLow" then
			st.mistakes += 1
		elseif res.result == "added" then
			st.filled[res.index] = p.id
			st.score += 20
			rebuildCartContents(player)
		end
		res.grade = p.ns.grade
		res.basketDone = Quest.basketDone(st.filled)
		res.state = st
		push(player)
		return res
	end

	-- Hand the full basket to Spike. Returns { stars = {bool, bool, bool}, state }.
	Remotes.CompleteQuest.OnServerInvoke = function(player)
		local st = stateOf(player)
		if not st or st.finished then
			return nil
		end
		if not st.questDone then
			if not Quest.basketDone(st.filled) then
				return nil
			end
			local stars = Quest.stars(st)
			local count = 0
			for _, on in stars do
				if on then
					count += 1
				end
			end
			st.stars[st.q] = count
			st.score += 50 * count
			st.questDone = true
			st.lastStars = stars
			push(player)
			task.spawn(save, player)
		end
		return { stars = st.lastStars, state = st }
	end

	-- After the quest-complete screen: next quest, or the grand finale.
	Remotes.NextQuest.OnServerInvoke = function(player)
		local st = stateOf(player)
		if not st or not st.questDone then
			return nil
		end
		st.questDone = false
		st.lastStars = false
		local kind
		if st.q < #GameData.QUESTS then
			st.q += 1
			st.filled = Quest.emptyBasket(st.q)
			st.mistakes, st.gR, st.gT = 0, 0, 0
			kind = "quest"
		else
			st.finished = true
			kind = "final"
		end
		rebuildCartContents(player)
		push(player)
		task.spawn(save, player)
		return { kind = kind, state = st }
	end

	Remotes.ResetProgress.OnServerInvoke = function(player)
		local st = stateOf(player)
		if not st then
			return nil
		end
		local fresh = Progress.fresh(st.lang)
		ensureBasket(fresh)
		states[player] = fresh
		rebuildCartContents(player)
		push(player)
		task.spawn(save, player)
		return fresh
	end
end

---------------------------------------------------------------- players

local function onPlayerAdded(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Parent = stats
	local stars = Instance.new("IntValue")
	stars.Name = "Stars"
	stars.Parent = stats
	stats.Parent = player

	player.CharacterAdded:Connect(function(character)
		buildCart(player, character)
	end)

	local st, loaded = Progress.load(player)
	if not player.Parent then
		return
	end
	ensureBasket(st)
	states[player] = st
	canSave[player] = loaded
	updateLeaderstats(player, st)
	if player.Character then
		task.spawn(buildCart, player, player.Character)
	end
end

local function onPlayerRemoving(player)
	save(player)
	states[player] = nil
	canSave[player] = nil
	carts[player] = nil
end

function Gameplay.start(storeFolder)
	store = storeFolder
	bindRemotes()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			save(player)
		end
	end)
	task.spawn(runDoors)
	-- Autosave every two minutes
	task.spawn(function()
		while true do
			task.wait(120)
			for _, player in Players:GetPlayers() do
				task.spawn(save, player)
			end
		end
	end)
end

return Gameplay
