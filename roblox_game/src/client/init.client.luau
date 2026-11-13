-- Client game flow: title → Spike's intro → quests → finale.
--
-- Modes: title | dialog | play | card | complete | final | help
-- Movement and prompts are only on in "play". The server owns progress;
-- this script asks it to do things and shows the answers.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local GameData = require(Shared.GameData)
local Quest = require(Shared.Quest)
local Text = require(Shared.Text)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Sfx = require(script.Sfx)
local Ui = require(script.Ui)
local WorldFx = require(script.WorldFx)

local player = Players.LocalPlayer

local state = nil
local lang = "en"
local mode = "title"
local modeBeforeHelp = "play"
local dlg = nil -- { lines, i, onDone, text, total, shown, openedAt }
local card = nil -- { p, guess, openedAt }
local hintUntil = 0
local busy = false -- a server request is in flight
local clock = 0

local function t(key, vars)
	return Text.get(lang, key, vars)
end

local function now()
	return os.clock()
end

local function basketDone()
	return state ~= nil and Quest.basketDone(state.filled)
end

local function totalStars()
	local n = 0
	for _, v in state.stars do
		n += v
	end
	return n
end

---------------------------------------------------------------- movement lock

local controls = nil
task.spawn(function()
	local ok, playerModule = pcall(function()
		return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	end)
	if ok and playerModule then
		controls = playerModule:GetControls()
		if mode ~= "play" then
			controls:Disable()
		end
	end
end)

local function renderAll()
	if not state then
		return
	end
	Ui.renderHUD(state, Sfx.enabled)
	Ui.setHudVisible(mode ~= "title" and not state.finished, mode ~= "title")
	WorldFx.localize(lang, state)
end

local function setMode(newMode)
	mode = newMode
	local playing = newMode == "play"
	if controls then
		if playing then
			controls:Enable()
		else
			controls:Disable()
		end
	end
	ProximityPromptService.Enabled = playing
	if newMode == "title" then
		WorldFx.setCameraMode("title")
	elseif newMode == "dialog" then
		WorldFx.setCameraMode("spike")
	elseif newMode ~= "help" then
		WorldFx.setCameraMode("follow")
	end
	renderAll()
end

-- Calls a server RemoteFunction, ignoring double clicks while one is pending.
local function ask(remote, ...)
	if busy then
		return nil
	end
	busy = true
	local ok, result = pcall(remote.InvokeServer, remote, ...)
	busy = false
	if not ok then
		warn("[NutriQuest]", remote.Name, "failed:", result)
		return nil
	end
	return result
end

---------------------------------------------------------------- dialog

local function lesson(key)
	local lines = {}
	for i in Text.lesson(lang, key) do
		table.insert(lines, function()
			return Text.lesson(lang, key)[i]
		end)
	end
	return lines
end

local function showLine(keepTyped)
	local line = dlg.lines[dlg.i]
	if type(line) == "function" then
		line = line()
	end
	local text, scale = line, nil
	if type(line) == "table" then
		text, scale = line.t, line.scale
	end
	dlg.text = text
	dlg.total = utf8.len(text) or #text
	dlg.shown = if keepTyped then dlg.total else 0
	local isLast = dlg.i == #dlg.lines
	Ui.setDialog(t("spike"), text, scale, if isLast then t("go") else t("next"), math.floor(dlg.shown))
end

local function showDialog(lines, onDone)
	dlg = { lines = lines, i = 1, onDone = onDone, openedAt = now() }
	setMode("dialog")
	Ui.showDialog(true)
	showLine(false)
end

local function advance()
	if not dlg or now() - dlg.openedAt < 0.25 then
		return
	end
	if dlg.shown < dlg.total then
		dlg.shown = dlg.total
		Ui.setDialogVisible(-1)
		return
	end
	dlg.i += 1
	if dlg.i > #dlg.lines then
		local onDone = dlg.onDone
		dlg = nil
		Ui.showDialog(false)
		setMode("play")
		if onDone then
			onDone()
		end
		return
	end
	showLine(false)
end

---------------------------------------------------------------- quests

local function startQuest()
	local q = GameData.QUESTS[state.q]
	showDialog(lesson(q.id), function()
		hintUntil = now() + 9
		Ui.toast(t("hintOn"), nil, 3.5)
	end)
end

local function completeQuest()
	local result = ask(Remotes.CompleteQuest)
	if not result then
		return
	end
	state = result.state
	WorldFx.party(3)
	Sfx.play("fanfare")
	WorldFx.burstAtSpike(120)
	setMode("complete")
	Ui.showComplete(state.q, result.stars, state.score)
end

local function talkToSpike()
	Sfx.play("open")
	if basketDone() then
		showDialog({
			function()
				return t("peek")
			end,
			function()
				return t("yay")
			end,
		}, completeQuest)
	else
		local n = Quest.remaining(state.filled)
		hintUntil = now() + 15
		Sfx.play("hint")
		showDialog({
			function()
				return t("more", { n = n })
			end,
		})
	end
end

local function nextQuest()
	local result = ask(Remotes.NextQuest)
	if not result then
		return
	end
	state = result.state
	Ui.hideComplete()
	if result.kind == "quest" then
		setMode("play")
		startQuest()
	else
		renderAll()
		showDialog(lesson("final"), function()
			setMode("final")
			Ui.showFinal(totalStars(), state.score)
			WorldFx.party(4)
			Sfx.play("fanfare")
			WorldFx.burstAtSpike(160)
		end)
	end
end

local function beginIntro()
	showDialog(lesson("intro"), function()
		task.spawn(function()
			ask(Remotes.FinishIntro)
		end)
		state.introDone = true
		startQuest()
	end)
end

---------------------------------------------------------------- product card

local function openCard(productId)
	local p = GameData.PRODUCT_BY_ID[productId]
	if not p then
		return
	end
	card = { p = p, guess = if state.discovered[p.id] then "seen" else nil, openedAt = now() }
	setMode("card")
	Sfx.play("open")
	Ui.showCard(card)
end

local function closeCard()
	if mode ~= "card" then
		return
	end
	Ui.hideCard()
	card = nil
	setMode("play")
end

local function guess(letter)
	if not card or card.guess then
		return
	end
	local current = card
	local result = ask(Remotes.Guess, current.p.id, letter)
	if not result or card ~= current then
		return
	end
	state = result.state
	if result.seen then
		current.guess = "seen"
	else
		current.guess = letter
		if result.diff == 0 then
			Sfx.play("right")
			Ui.pop("+10")
			WorldFx.burstAtProduct(current.p.id, 20)
		elseif result.diff == 1 then
			Sfx.play("near")
			Ui.pop("+5")
		else
			Sfx.play("miss")
		end
	end
	renderAll()
	Ui.renderCard(current)
end

local function tryAdd()
	if not card then
		return
	end
	local p = card.p
	local result = ask(Remotes.AddToBasket, p.id)
	if not result then
		return
	end
	state = result.state
	local name = Text.name(lang, p.nm)
	if result.result == "dupe" then
		Sfx.play("miss")
		Ui.toast(t("dupe", { name = name }), "bad")
		renderAll()
		return
	end
	closeCard()
	if result.result == "full" or result.result == "notNeeded" then
		Sfx.play("miss")
		Ui.toast(t(result.result), nil)
	elseif result.result == "tooLow" then
		Sfx.play("wrong")
		WorldFx.shake()
		Ui.toast(t("tooLow", { name = name, g = p.ns.grade, need = result.need }), "bad", 5.2)
	elseif result.result == "added" then
		Sfx.play("add")
		Ui.pop("+20")
		WorldFx.burstAtProduct(p.id, 28)
		if result.basketDone then
			task.delay(0.35, function()
				Sfx.play("hint")
				Ui.toast(t("basketDone"), "good", 5)
			end)
		else
			Ui.toast(t("added", { name = name, g = p.ns.grade }), "good", 2.8)
		end
	end
	renderAll()
end

---------------------------------------------------------------- help, language, title

local function openHelp()
	if mode == "help" then
		return
	end
	modeBeforeHelp = mode
	setMode("help")
	Ui.showHelp()
end

local function closeHelp()
	if mode ~= "help" then
		return
	end
	Ui.hideHelp()
	setMode(modeBeforeHelp)
end

local function setLang(newLang)
	if not Text.isLang(newLang) then
		return
	end
	lang = newLang
	Ui.setLang(lang)
	task.spawn(function()
		pcall(Remotes.SetLanguage.InvokeServer, Remotes.SetLanguage, lang)
	end)
	renderAll()
	if dlg then
		showLine(true)
	end
	if card then
		Ui.renderCard(card)
	end
	Ui.renderHelp()
	Ui.renderComplete()
	Ui.renderFinal()
	if state then
		Ui.renderTitle(state)
	end
end

local function onPlay()
	if mode ~= "title" then
		return
	end
	if state.finished then
		local fresh = ask(Remotes.ResetProgress)
		if not fresh then
			return
		end
		state = fresh
	end
	Ui.showTitle(false)
	setMode("play")
	if not state.introDone then
		beginIntro()
	elseif basketDone() then
		Ui.toast(t("basketDone"), "good", 4)
	else
		hintUntil = now() + 6
		Ui.toast(t("hintOn"), nil, 3)
	end
end

local function onNewGame()
	local fresh = ask(Remotes.ResetProgress)
	if fresh then
		state = fresh
		Ui.renderTitle(state)
		renderAll()
	end
end

local function onAgain()
	local fresh = ask(Remotes.ResetProgress)
	if not fresh then
		return
	end
	state = fresh
	Ui.hideFinal()
	setMode("play")
	beginIntro()
end

local function onHint()
	if mode ~= "play" then
		return
	end
	Sfx.play("hint")
	hintUntil = now() + 12
	Ui.toast(if basketDone() then t("basketDone") else t("hintOn"), nil, 3.2)
end

---------------------------------------------------------------- input

local LETTER_KEYS = {
	[Enum.KeyCode.A] = "A",
	[Enum.KeyCode.B] = "B",
	[Enum.KeyCode.C] = "C",
	[Enum.KeyCode.D] = "D",
	[Enum.KeyCode.E] = "E",
}

UserInputService.InputBegan:Connect(function(input, processed)
	local key = input.KeyCode
	if mode == "dialog" then
		if key == Enum.KeyCode.Space or key == Enum.KeyCode.Return or key == Enum.KeyCode.E then
			advance()
		elseif not processed and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			advance()
		end
	elseif mode == "card" then
		-- Ignore the key press that opened the card (it may have been E).
		if card and not card.guess and not processed and now() - card.openedAt > 0.35 and LETTER_KEYS[key] then
			task.spawn(guess, LETTER_KEYS[key])
		elseif key == Enum.KeyCode.Backspace then
			closeCard()
		end
	elseif mode == "help" then
		if key == Enum.KeyCode.Backspace then
			closeHelp()
		end
	elseif mode == "title" then
		if key == Enum.KeyCode.Return and not processed then
			task.spawn(onPlay)
		end
	elseif mode == "play" then
		if key == Enum.KeyCode.H and not processed then
			onHint()
		end
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if mode ~= "play" or not state then
		return
	end
	if prompt:GetAttribute("Spike") then
		talkToSpike()
		return
	end
	local productId = prompt:GetAttribute("ProductId")
	if productId then
		openCard(productId)
	end
end)

---------------------------------------------------------------- start

local store = workspace:WaitForChild("Store")
while not store:GetAttribute("Ready") do
	store:GetAttributeChangedSignal("Ready"):Wait()
end
local spikeTemplate = store:WaitForChild("Spike"):Clone()
for _, d in spikeTemplate:GetDescendants() do
	if d:IsA("ProximityPrompt") or d:IsA("Highlight") then
		d:Destroy()
	end
end

WorldFx.init(store)
Ui.init({
	onPlay = function()
		task.spawn(onPlay)
	end,
	onNewGame = function()
		task.spawn(onNewGame)
	end,
	onLang = setLang,
	onCycleLang = function()
		local i = table.find(Config.LANG_CYCLE, lang) or 0
		setLang(Config.LANG_CYCLE[i % #Config.LANG_CYCLE + 1])
	end,
	onHint = onHint,
	onSound = function()
		Sfx.enabled = not Sfx.enabled
		renderAll()
	end,
	onHelp = function()
		if mode == "help" then
			closeHelp()
		else
			openHelp()
		end
	end,
	onCloseHelp = closeHelp,
	onDialogNext = advance,
	onGuess = function(letter)
		task.spawn(guess, letter)
	end,
	onAdd = function()
		task.spawn(tryAdd)
	end,
	onBack = function()
		Sfx.play("close")
		closeCard()
	end,
	onCloseCard = closeCard,
	onNextQuest = function()
		task.spawn(nextQuest)
	end,
	onAgain = function()
		task.spawn(onAgain)
	end,
}, spikeTemplate)

Remotes.StateChanged.OnClientEvent:Connect(function(newState)
	state = newState
	renderAll()
end)

state = Remotes.GetState:InvokeServer()
if not state then
	warn("[NutriQuest] Could not load progress; starting fresh")
	state = { lang = false, q = 1, introDone = false, filled = Quest.emptyBasket(1), score = 0, stars = {}, discovered = {}, finished = false }
end

if state.lang and Text.isLang(state.lang) then
	lang = state.lang
else
	local locale = string.lower(string.sub(player.LocaleId or "en", 1, 2))
	lang = if Text.isLang(locale) then locale else "en"
	task.spawn(function()
		pcall(Remotes.SetLanguage.InvokeServer, Remotes.SetLanguage, lang)
	end)
end
Ui.setLang(lang)
Ui.renderTitle(state)
Ui.showTitle(true)
setMode("title")

RunService.RenderStepped:Connect(function(dt)
	clock += dt
	-- Typewriter for Spike's lines
	local talking = false
	if mode == "dialog" and dlg and dlg.shown < dlg.total then
		talking = true
		local before = math.floor(dlg.shown)
		dlg.shown = math.min(dlg.total, dlg.shown + dt * 42)
		local after = math.floor(dlg.shown)
		if after ~= before then
			Ui.setDialogVisible(after)
			if after % 3 == 0 then
				Sfx.play("talk")
			end
		end
	end
	WorldFx.update(dt, clock, {
		mode = mode,
		state = state,
		hintActive = mode == "play" and now() < hintUntil and not basketDone(),
		talking = talking,
	})
end)
