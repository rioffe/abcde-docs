-- Fonts for all text in the game.
--
-- Nunito covers Latin Extended (ā, ē, ņ, š…) and Cyrillic, so Latvian and
-- Russian render in the same face as English. (Fredoka One, used before,
-- has neither, so Roblox drew those letters in a thin fallback font.)
-- Nunito is also the body font of the web version.

local NUNITO = "rbxasset://fonts/families/Nunito.json"

return {
	display = Font.new(NUNITO, Enum.FontWeight.Heavy),
	body = Font.new(NUNITO, Enum.FontWeight.Bold),
}
