-- Shared constants: colours, positions and scale.
--
-- The web version was built in metres. Everything here is in metres too and
-- is multiplied by SCALE when placed in the Roblox world (a Roblox avatar is
-- about 5 studs tall, which matches the 1.4 m kid in the web game).

local Config = {}

Config.SCALE = 3.5 -- studs per metre

Config.NS = { "A", "B", "C", "D", "E" }

Config.NS_COLORS = {
	A = Color3.fromHex("#038141"),
	B = Color3.fromHex("#85bb2f"),
	C = Color3.fromHex("#fecb02"),
	D = Color3.fromHex("#ee8100"),
	E = Color3.fromHex("#e63e11"),
}

Config.UI = {
	ink = Color3.fromHex("#1d2340"),
	panel = Color3.fromHex("#ffffff"),
	panel2 = Color3.fromHex("#eef5ff"),
	sky = Color3.fromHex("#bfe6f7"),
	accent = Color3.fromHex("#2b6cf2"),
	quill = Color3.fromHex("#7a4b2c"),
	muted = Color3.fromHex("#5a6487"),
	good = Color3.fromHex("#038141"),
	bad = Color3.fromHex("#e63e11"),
	doneRow = Color3.fromHex("#e4f6e8"),
	zero = Color3.fromHex("#c9d1e3"),
	line = Color3.fromHex("#d6dff0"),
	gold = Color3.fromHex("#ffbf00"),
	starOff = Color3.fromHex("#d6dbe8"),
	pink = Color3.fromHex("#ff6fa5"),
}

-- World positions in metres.
Config.SPIKE_POS = Vector3.new(-10, 0, 8.4)
Config.KITCHEN_POS = Vector3.new(-10, 0, 7)

-- Pivots inside Spike's model, relative to his feet, in metres. Spike faces +Z.
Config.SPIKE_HEAD = Vector3.new(0, 1.18, 0.52)
Config.SPIKE_QUILLS = Vector3.new(0, 0.82, 0)
Config.SPIKE_SPOON = Vector3.new(0.55, 0.8, 0.45)

-- Order the language button cycles through, and each language's position
-- in the { English, Latvian, Russian } name arrays.
Config.LANG_CYCLE = { "lv", "ru", "en" }
Config.LANG_INDEX = { en = 1, lv = 2, ru = 3 }

return Config
