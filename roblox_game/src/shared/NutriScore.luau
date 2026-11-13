-- Nutri-Score (2023/2024 rules, simplified for teaching): not-so-good points
-- minus good points. A straight port of nutri() from the web game.

local NutriScore = {}

local TH = {
	en = { 335, 670, 1005, 1340, 1675, 2010, 2345, 2680, 3015, 3350 },
	su = { 3.4, 6.8, 10, 14, 17, 20, 24, 27, 31, 34, 37, 41, 44, 48, 51 },
	sf = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
	sa = { 0.2, 0.4, 0.6, 0.8, 1, 1.2, 1.4, 1.6, 1.8, 2, 2.2, 2.4, 2.6, 2.8, 3, 3.2, 3.4, 3.6, 3.8, 4 },
	pr = { 2.4, 4.8, 7.2, 9.6, 12, 14, 17 },
	fi = { 3, 4.1, 5.2, 6.3, 7.4 },
	bEn = { 30, 90, 150, 210, 240, 270, 300, 330, 360, 390 },
	bSu = { 0.5, 2, 3.5, 5, 6, 7, 8, 9, 10, 11 },
	bPr = { 1.2, 1.5, 1.8, 2.1, 2.4, 2.7, 3 },
	fEn = { 120, 240, 360, 480, 600, 720, 840, 960, 1080, 1200 },
	fRa = { 10, 16, 22, 28, 34, 40, 46, 52, 58, 64 },
}

-- Keys in a fixed order so "biggest minus / plus" ties resolve the same way every time.
NutriScore.BAD_KEYS = { "energy", "sugar", "satfat", "salt", "sweet" }
NutriScore.GOOD_KEYS = { "protein", "fiber", "fvl" }

local function pts(value, thresholds)
	local i = 0
	while i < #thresholds and value > thresholds[i + 1] do
		i += 1
	end
	return i
end

local function sum(t)
	local s = 0
	for _, v in t do
		s += v
	end
	return s
end

local function fvlPoints(fvl, isDrink)
	if fvl > 80 then
		return if isDrink then 6 else 5
	elseif fvl > 60 then
		return if isDrink then 4 else 2
	elseif fvl > 40 then
		return if isDrink then 2 else 1
	end
	return 0
end

-- Nutrient values per 100 g / 100 ml, with zero defaults.
function NutriScore.nutrients(product)
	local n = { kj = 0, sug = 0, sf = 0, salt = 0, fib = 0, pro = 0, fvl = 0, fat = 0, sweet = false }
	if product.n then
		for k, v in product.n do
			n[k] = v
		end
	end
	return n
end

function NutriScore.compute(product)
	local n = NutriScore.nutrients(product)
	local cat = product.cat or "food"

	if cat == "water" then
		return {
			grade = "A", S = 0, N = 0, P = 0, bad = {}, good = {},
			proteinCounted = true, proteinRaw = 0, water = true, cat = cat,
		}
	end

	local bad, good = {}, {}
	local proteinCounted = true

	if cat == "drink" then
		bad.energy = pts(n.kj, TH.bEn)
		bad.sugar = pts(n.sug, TH.bSu)
		bad.satfat = pts(n.sf, TH.sf)
		bad.salt = pts(n.salt, TH.sa)
		if n.sweet then
			bad.sweet = 4
		end
		good.protein = pts(n.pro, TH.bPr)
		good.fiber = pts(n.fib, TH.fi)
		good.fvl = fvlPoints(n.fvl, true)
	elseif cat == "fat" then
		bad.energy = pts(n.sf * 37, TH.fEn)
		bad.satfat = pts(if n.fat > 0 then n.sf / n.fat * 100 else 0, TH.fRa)
		bad.sugar = pts(n.sug, TH.su)
		bad.salt = pts(n.salt, TH.sa)
		good.protein = pts(n.pro, TH.pr)
		good.fiber = pts(n.fib, TH.fi)
		good.fvl = fvlPoints(n.fvl, false)
		if sum(bad) >= 7 then
			proteinCounted = false
		end
	else
		bad.energy = pts(n.kj, TH.en)
		bad.sugar = pts(n.sug, TH.su)
		bad.satfat = pts(n.sf, TH.sf)
		bad.salt = pts(n.salt, TH.sa)
		good.protein = pts(n.pro, TH.pr)
		good.fiber = pts(n.fib, TH.fi)
		good.fvl = fvlPoints(n.fvl, false)
		if cat ~= "cheese" and sum(bad) >= 11 then
			proteinCounted = false
		end
	end

	local proteinRaw = good.protein
	if not proteinCounted then
		good.protein = 0
	end

	local N, P = sum(bad), sum(good)
	local S = N - P
	local grade
	if cat == "drink" then
		grade = if S <= 2 then "B" elseif S <= 6 then "C" elseif S <= 9 then "D" else "E"
	elseif cat == "fat" then
		grade = if S <= -6 then "A" elseif S <= 2 then "B" elseif S <= 10 then "C" elseif S <= 18 then "D" else "E"
	else
		grade = if S <= 0 then "A" elseif S <= 2 then "B" elseif S <= 10 then "C" elseif S <= 18 then "D" else "E"
	end

	return {
		grade = grade, S = S, N = N, P = P, bad = bad, good = good,
		proteinCounted = proteinCounted, proteinRaw = proteinRaw, cat = cat,
	}
end

return NutriScore
