# Spike's Nutri Quest (Roblox)

A Roblox version of the web game in [`../game`](../game). Spike the porcupine chef
runs the ABCDE Market and teaches kids to read the Nutri-Score letters A to E while
they shop for six home-cooking quests. Latvian, Russian and English.

## Run it

You need [Roblox Studio](https://create.roblox.com/) and [Rokit](https://github.com/rojo-rbx/rokit).

```bash
cd roblox_game
rokit install          # installs Rojo 7.7.1 (and the Luau CLI) from rokit.toml
rojo plugin install    # once: adds the Rojo plugin to Studio
rojo serve
```

In Studio: open a new **Baseplate** place, click **Plugins → Rojo → Connect**, then **Play**.

To save progress between sessions in Studio, turn on
**Game Settings → Security → Enable Studio Access to API Services**.
Without it the game still runs, but progress resets each time.

## Sounds

The web game's sound effects are recreated as WAV files in `assets/sounds/`
by `python3 tools/make_sounds.py` (same notes, wave shapes and envelopes).
Roblox can only play audio uploaded to Roblox, so to use them:

1. In Studio, open **View → Asset Manager → Bulk Import** and pick the ten
   `assets/sounds/nutri_*.wav` files.
2. Right-click each uploaded sound → **Copy Asset ID**, and paste it into
   `Sfx.IDS` in `src/client/Sfx.luau` (e.g. `open = "rbxassetid://1234567890"`).

Until then the game plays the same melodies on Roblox's built-in volume-slider
chime, re-pitched note by note.

## How it plays

- Walk with W A S D, the arrow keys or the thumbstick. A shopping cart rolls in front of you.
- Walk up to a product and press **E** (or tap the button) to look closer and
  guess its Nutri-Score letter (+10 for exact, +5 for one off). The A–E keys work too.
- Put products that meet the quest's letter in your basket (+20).
- Bring the full basket to Spike at his kitchen for up to three stars per quest.
- ★ (or **H**) lights up the shelves you still need and draws a golden guide beam.
- The top bar shows points and letters found, and switches language, sound and help.

## Layout

```
src/shared/   Config, GameData (sections, 74 products, 6 quests), NutriScore rules,
              Quest rules, Text (all three languages)
src/server/   StoreBuilder + SpikeBuilder (build the market from parts),
              Gameplay (remotes, carts, doors, leaderstats), Progress (DataStore)
src/client/   init.client (game flow), Ui (all screens), WorldFx (Spike's animation,
              hints, confetti, camera), Sfx
```

The server owns every player's progress and checks each guess and basket move.
The client only shows things and asks.
