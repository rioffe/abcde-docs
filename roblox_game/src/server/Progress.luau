-- Loads and saves each player's progress with DataStoreService.
--
-- In Studio, saving only works if "Enable Studio Access to API Services" is on
-- (Game Settings → Security). Without it the game still runs; progress just
-- isn't kept between sessions.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Progress = {}

local VERSION = 1
local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("SpikeNutriQuest_v1")
	end)
	if ok then
		store = result
	elseif RunService:IsStudio() then
		warn("[NutriQuest] DataStore unavailable, progress will not be saved:", result)
	end
end

local function key(player)
	return "player_" .. player.UserId
end

function Progress.fresh(lang)
	return {
		v = VERSION,
		lang = lang or false, -- false until the player picks or we detect one
		q = 1, -- current quest (1-based)
		introDone = false,
		filled = {}, -- product id per basket slot, false when empty
		score = 0,
		stars = {}, -- stars earned per quest
		discovered = {}, -- [productId] = true once its letter was guessed
		mistakes = 0, -- wrong picks this quest
		gR = 0, -- right guesses this quest (0.5 for "close")
		gT = 0, -- total guesses this quest
		finished = false,
		questDone = false, -- quest completed, waiting for "Next quest"
		lastStars = false,
	}
end

-- Returns the saved state (or a fresh one) and whether loading succeeded.
-- If loading failed we must not save later, or we'd overwrite real progress.
function Progress.load(player)
	if not store then
		return Progress.fresh(), false
	end
	local ok, data = pcall(function()
		return store:GetAsync(key(player))
	end)
	if not ok then
		warn("[NutriQuest] Could not load progress for", player.Name, data)
		return Progress.fresh(), false
	end
	if type(data) ~= "table" or data.v ~= VERSION then
		return Progress.fresh(), true
	end
	for k, v in Progress.fresh() do
		if data[k] == nil then
			data[k] = v
		end
	end
	return data, true
end

function Progress.save(player, state, canSave)
	if not store or not canSave then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(key(player), state)
	end)
	if not ok then
		warn("[NutriQuest] Could not save progress for", player.Name, err)
	end
end

return Progress
