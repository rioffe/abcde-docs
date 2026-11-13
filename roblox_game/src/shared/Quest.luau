-- Quest rules shared by the server (which enforces them) and the client
-- (which shows the list). Pure functions, no Roblox services.

local Config = require(script.Parent.Config)
local GameData = require(script.Parent.GameData)

local Quest = {}

function Quest.gradeIndex(grade)
	return table.find(Config.NS, grade)
end

-- Expands slots with a count (e.g. "3 fruits") into one entry per item.
function Quest.slotsOf(questIndex)
	local out = {}
	for _, def in GameData.QUESTS[questIndex].slots do
		for _ = 1, def.count or 1 do
			table.insert(out, def)
		end
	end
	return out
end

function Quest.emptyBasket(questIndex)
	return table.create(#Quest.slotsOf(questIndex), false)
end

function Quest.fits(slotDef, product)
	for _, tag in slotDef.tags do
		if table.find(product.tg, tag) then
			return true
		end
	end
	return false
end

function Quest.remaining(filled)
	local n = 0
	for _, id in filled do
		if not id then
			n += 1
		end
	end
	return n
end

function Quest.basketDone(filled)
	return #filled > 0 and Quest.remaining(filled) == 0
end

-- Set of section ids that still hold something the basket needs.
function Quest.neededSections(questIndex, filled)
	local out = {}
	for i, def in Quest.slotsOf(questIndex) do
		if not filled[i] then
			for _, p in GameData.PRODUCTS do
				if Quest.fits(def, p) then
					out[p.s] = true
				end
			end
		end
	end
	return out
end

-- What happens when a product goes in the basket. Returns a table with
-- result = "dupe" | "full" | "notNeeded" | "tooLow" | "added",
-- plus `need` (for tooLow) or `index` (the slot to fill, for added).
function Quest.evaluateAdd(questIndex, filled, product)
	local slots = Quest.slotsOf(questIndex)
	if table.find(filled, product.id) then
		return { result = "dupe" }
	end

	local matches = {}
	for i, def in slots do
		if not filled[i] and Quest.fits(def, product) then
			table.insert(matches, i)
		end
	end
	if #matches == 0 then
		for _, def in slots do
			if Quest.fits(def, product) then
				return { result = "full" }
			end
		end
		return { result = "notNeeded" }
	end

	local grade = Quest.gradeIndex(product.ns.grade)
	local ok = {}
	for _, i in matches do
		if grade <= Quest.gradeIndex(slots[i].max) then
			table.insert(ok, i)
		end
	end
	if #ok == 0 then
		return { result = "tooLow", need = slots[matches[1]].max }
	end

	-- Prefer a normal slot so a healthy pick doesn't use up the treat slot.
	for _, i in ok do
		if not slots[i].treat then
			return { result = "added", index = i }
		end
	end
	return { result = "added", index = ok[1] }
end

-- The three stars: finished the list, no wrong picks, good letter guesser.
function Quest.stars(state)
	return {
		true,
		state.mistakes == 0,
		state.gT == 0 or state.gR / state.gT >= 0.6,
	}
end

return Quest
