-- Server entry point: build the market, then start the game rules.
local StoreBuilder = require(script.StoreBuilder)
local Gameplay = require(script.Gameplay)

local store = StoreBuilder.build()
Gameplay.start(store)
