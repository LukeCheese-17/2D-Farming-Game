# Requirements — 2D Creepy Cozy Farm

A top-down 2D farming game built in Godot 4.6 (GDScript) with a **horror atmosphere and no monster**.
Fired from a dead-end job and left homeless, you spend the last of your money on cheap land: a
run-down farm. A landline rings, and the man who sold it to you posts quests on the village board
and pays you for them. You farm, fish and raise animals, put what you make in the shipping box, and
everything in the box is sold each time you sleep. The whole time, it should feel like something is watching you.

The core loops are:
- **Farming:** plant → water → wait → harvest
- **Earning:** gather (farm / fish / animals) → shipping box → sleep → get paid
- **Quests:** main quest on the board → complete it → call him → get paid; two small daily notes on the board

## 1. Player movement

| ID | Requirement |
|----|-------------|
| MOV-1 | The player moves in 8 directions (up, down, left, right, and the four diagonals) using WASD and the arrow keys. |
| MOV-2 | Diagonal movement is normalized, so moving diagonally is not faster than moving straight. |
| MOV-3 | The player plays an idle animation when standing still and a walk animation when moving. |
| MOV-4 | The player faces the last direction moved. Diagonals use the matching left/right animation (the sprite sheet only has 4 directions). |
| MOV-5 | The player cannot walk through water or solid objects (trees, fences, buildings). |
| MOV-6 | The camera follows the player and stays within the map bounds. |

**Done when:** the player can walk in all 8 directions at the same speed, animations match the direction, and water blocks movement.

## 2. Targeting tiles

| ID | Requirement |
|----|-------------|
| TGT-1 | Actions apply to the tile directly in front of the player (based on facing direction). |
| TGT-2 | The targeted tile is highlighted so the player knows where an action will happen. |

## 3. Planting

| ID | Requirement |
|----|-------------|
| PLT-1 | The player can till a grass tile with the hoe, turning it into tilled dirt. Only tiles marked tillable can be tilled. |
| PLT-2 | The player can plant a seed on an empty tilled tile. |
| PLT-3 | Planting uses one seed from the player's inventory; planting is blocked when the player has no seeds. |
| PLT-4 | A tile can hold only one crop at a time. |
| PLT-5 | The player plays the matching tool animation (tilling) while performing the action. |

## 4. Watering

| ID | Requirement |
|----|-------------|
| WAT-1 | The player can water a planted tile with the watering can. |
| WAT-2 | Watered soil looks visibly darker than dry soil. |
| WAT-3 | Watered status resets to dry at the start of each new day. |
| WAT-4 | A crop only advances a growth stage on days it was watered. |

## 5. Waiting (time and growth)

| ID | Requirement |
|----|-------------|
| TIM-1 | The game tracks in-game days. |
| TIM-2 | The player can end the day (for example, by sleeping in bed), which advances to the next day. |
| TIM-3 | Each crop has several growth stages (seed → sprout → growing → ripe), each shown with a different sprite from `Basic_Plants.png`. |
| TIM-4 | Each crop type defines how many watered days it needs to become ripe. |
| TIM-5 | The current day is shown on screen. |

## 6. Harvesting

| ID | Requirement |
|----|-------------|
| HRV-1 | The player can harvest a crop only when it is ripe. |
| HRV-2 | Harvesting removes the crop and adds the produce to the player's inventory. |
| HRV-3 | After harvesting, the tile stays tilled and can be planted again. |
| HRV-4 | Trying to harvest an unripe crop does nothing (or shows a short message). |

## 7. Inventory and tools (minimum)

| ID | Requirement |
|----|-------------|
| INV-1 | The player has a slot inventory: a 10-slot hotbar plus a 20-slot backpack. Items stack (up to 99); tools take one slot each. Tools, seeds, produce, fish and animal products are all items. |
| INV-2 | Keys 1-0 (or the mouse wheel) select a hotbar slot. Using the selected item does its job: hoe tills, watering can waters, seeds plant, fishing rod fishes; anything else (or an empty slot) acts as an empty hand for harvesting and collecting. |
| INV-3 | The hotbar is always on screen with icons, counts and the selected slot. Tab (or I) opens the backpack, where items are moved between slots with the mouse (click to pick up, click to put down; same items merge, different ones swap), and hovering shows the item name and sell price. A full bag refuses new items with a message. |

## 8. Atmosphere — horror, no monster

On the surface (farm, village, woods) the horror comes from mood and suggestion only. Nothing ever attacks, chases or appears there.
The mine (MIN) is the one exception: it has enemies.

| ID | Requirement |
|----|-------------|
| ATM-1 | **There is no monster on the surface.** No creature, enemy or figure is ever shown above ground, and there is no combat there. Enemies exist only in the mine (MIN-3). |
| ATM-2 | The game constantly suggests the player is being watched, using small, deniable cues. Examples: something just at the edge of the screen that is gone when you look, eyes in the dark tree line, footsteps that stop when you stop, objects moved slightly overnight, animals all turning to stare at the same spot. |
| ATM-3 | Cues are subtle and rare enough to stay unsettling, not jump-scares. They should be easy to miss. |
| ATM-4 | The visual mood is muted and lonely (for example: desaturated colours, a dark vignette, fog or dimming toward the edges of the map), while keeping the cozy pixel-art style readable. |
| ATM-5 | Evening and night feel noticeably more uneasy than daytime (darker lighting, more frequent cues). |

## 9. The house

| ID | Requirement |
|----|-------------|
| HSE-1 | The player lives in a run-down house on the farm (worn, broken or patched-up look), built from the wooden house tilesets. |
| HSE-2 | The player can enter and leave the house. |
| HSE-3 | The bed (where the player sleeps to end the day, TIM-2) and the landline phone are inside the house. |

## 10. Landline

| ID | Requirement |
|----|-------------|
| PHN-1 | A landline phone in the house rings at times, with a ringing sound and a visual cue (for example, the phone shaking and a "ring" icon). |
| PHN-2 | The player answers by walking to the phone and pressing the interact key. |
| PHN-3 | On the first morning the man who sold the land calls: "So you're the one that bought this land... I'll send you some quests on that board in the village center. Come back to me when you've got a quest done and I'll send you the cash. Also call me if you ever need more supplies." His call puts the first main quest on the board (QST-3). If missed, he calls again the next morning. |
| PHN-4 | After that, the player uses the phone to call him. If the current main quest is done, he pays its reward and the next main quest goes up. |
| PHN-5 | Calling him also lets the player order basic supplies (seeds, bread, water); orders are left at the door the next morning. |
| PHN-7 | The caller's lines stay short and slightly off, adding to the uneasy mood (ATM-2), without ever revealing who or what he is. |
| PHN-8 | Phone calls only start from 06:00 (the start of the day). |

## 11. Money and the shipping box

| ID | Requirement |
|----|-------------|
| SHP-1 | The player has money, shown on screen. |
| SHP-2 | There is a shipping box outside the house. Holding a sellable item in the hotbar and pressing the interact key puts the whole stack in. |
| SHP-3 | Every time the player sleeps, everything in the shipping box is sold and the money is added. |
| SHP-4 | Each item type has a sell price, defined as data (like crops in TEC-4). |
| SHP-5 | After sleeping, the player sees what was sold and how much they earned. |

## 12. Fishing

| ID | Requirement |
|----|-------------|
| FSH-1 | The player can fish with the fishing rod by facing water and using the tool. |
| FSH-2 | After casting, there is a wait, then a bite starts a timing-ring minigame: a needle sweeps around a dial and the player presses Space while it is in the lit zone. Enough hits in a row land the fish; a miss, or waiting too long, lets it go. Harder fish have a smaller zone, a faster needle and need more hits. |
| FSH-3 | A caught fish goes into the inventory. There are at least two fish types, defined as data. |
| FSH-4 | Fish can be shipped and sold, and can be asked for in quests. |
| FSH-5 | There is a wide variety of fish (at least 10), each with its own difficulty, price and where/when it can be caught (e.g. pond vs river, day vs night). |

## 13. Animals

| ID | Requirement |
|----|-------------|
| ANM-1 | The player raises farm animals: at least chickens and cows (sprites exist in `assets/Characters`). |
| ANM-2 | Animals live in a fenced area or coop and wander around it. |
| ANM-3 | Animals produce goods once per day (chickens → eggs, cows → milk), which the player collects with the hand. |
| ANM-4 | Animal products can be shipped and sold, and can be asked for in quests. |

## 14. Technical requirements

| ID | Requirement |
|----|-------------|
| TEC-1 | Engine: Godot 4.6, GDScript, 640×360 viewport with integer scaling and nearest filtering (already configured). |
| TEC-2 | Ground uses `TileMapLayer` nodes with the shared `game_tile_set.tres`. |
| TEC-3 | The tileset has a physics layer for blocking tiles and a custom data layer (`can_till: bool`) for tillable ground. |
| TEC-4 | Crop types are defined as data (e.g. a `Resource` per crop: name, stage sprites, days to grow, produce) so new crops can be added without new code. The same applies to fish, animals, sellable items and quests. |
| TEC-5 | Input uses named actions in the Input Map (`move_up`, `move_down`, `move_left`, `move_right`, `use_tool`, `interact`, `hotbar_1`…`hotbar_10`, `hotbar_next`, `hotbar_previous`, `backpack`), not hard-coded keys. |
| TEC-6 | Characters and objects y-sort so the player can walk behind trees and in front of them. |

## 15. Map revamp

| ID | Requirement |
|----|-------------|
| MAP-1 | The map is redesigned to be bigger and better: farm, woods, river/pond, the way to the mine and the abandoned village. |
| MAP-2 | Areas are connected so the player can walk between them (or travel through map exits). |

## 16. Food and water

| ID | Requirement |
|----|-------------|
| NED-1 | The player has food and water meters, shown on screen, that go down over time. |
| NED-2 | The player eats food items and drinks water to refill them. |
| NED-3 | Low food or water has consequences (e.g. slower movement, fainting). |
| NED-4 | Food also restores some health (stew and bread the most); eating when it would do nothing is refused. |

## 17. Tools: axe and pickaxe

| ID | Requirement |
|----|-------------|
| TOL-1 | An axe cuts down trees, giving wood. |
| TOL-2 | A pickaxe breaks rocks, giving stone (and ore in the mine). |
| TOL-3 | Crops can be harvested and animal products collected while holding any tool, not only an empty hand. |

## 18. The mine

| ID | Requirement |
|----|-------------|
| MIN-1 | There is a mine with 5 floors, giving the player more to do during the day. |
| MIN-2 | Each floor is a different biome with its own look, rocks and materials. |
| MIN-3 | Each floor has its own terrifying enemies. The player can fight them and can be hurt. |
| MIN-4 | Mine materials (stone, ores, etc.) are used by the blacksmith (VIL-3) and to rebuild the village. |

## 19. The abandoned village

| ID | Requirement |
|----|-------------|
| VIL-1 | There is an abandoned village that the player rebuilds by completing quests and handing in materials. Each rebuilt building opens a feature. |
| VIL-2 | Blacksmith: makes better tools using materials from the mine. |
| VIL-3 | Flower shop. |
| VIL-4 | General store: a proper seed shop with a wider variety of seeds. |

## 20. Quests

| ID | Requirement |
|----|-------------|
| QST-1 | Quests are defined as data: main quests in `data/quests/main` (in order), daily notes in `data/quests`. |
| QST-2 | The quest board in the village center shows one main quest and two daily notes. |
| QST-3 | The main quest only changes when the last one is completed and paid for by phone. Main quests can ask for items (left at the board), a rebuilt village building, or a mine floor reached. |
| QST-4 | The two daily notes are picked at random every morning, ask for items handed in at the board, and pay a small amount of cash on the spot. |

## 21. Menus, UI and saving

| ID | Requirement |
|----|-------------|
| UI-1 | UI overhaul: a consistent, cleaner look for the HUD, hotbar, backpack, dialogue and menus. |
| UI-2 | A home (title) screen with at least New Game, Continue and Quit. The title reads "GAME" until the game has a name. |
| UI-5 | New Game plays a wordless intro (show, don't tell): the player is fired from an office job, ends up homeless, finds a flyer for cheap land, buys it with the last of their money and arrives at the run-down farm. It can be skipped. |
| UI-3 | Pressing Esc pauses the game and opens a pause menu (Resume, Options, Save, Quit to home screen). |
| UI-4 | The pause menu has options (e.g. volume, fullscreen, controls). |
| SAV-1 | The game can be saved and loaded (farm, inventory, money, day, animals, quests, village progress). |
| SAV-2 | There are three save slots. New Game and Continue ask for a slot; starting a new game on a used slot asks first. |

## Open questions

Things the vision doesn't settle yet. Each has a **provisional answer** chosen so the game could be built
(2026-10-19); change any of them and the game can be adjusted.

- **What is money for?** *Provisional:* seeds and supplies (ordered by phone or bought in the village), rebuilding the village, tools and animals.
- **Do animals need care?** *Provisional:* no. Each animal has one product per day.
- **Do quests have deadlines?** *Provisional:* main quests don't; daily notes only last the day.
- **Is there an ending or a story?** *Provisional:* the intro sets it up; after the last main quest he says the place looks alive again. No ending yet.
- **Sound:** *Provisional:* simple generated placeholder sounds (phone ring, footsteps, wind, splash, bite, door creak) in `assets/Generated/`. Replace them with real recordings when available.

Other choices made while building:
- The camera is zoomed in 2x, so you only see the area around you (helps the "something is out there" feeling).
- A day runs from 06:00; 10 in-game minutes pass every 7 seconds. Staying up until 02:00 makes you pass out and wake up in bed.
- Some nights the phone rings and no one speaks (PHN-7 / ATM-2).
- **Map:** one big connected surface map (farm in the middle, woods and pond north, river with two bridges east, village west, mine entrance south), painted by `tools/build_world.gd`. Only the farm can be tilled; grass outside it is "wild grass".
- **Needs:** food and water drop every 10 minutes and overnight. Below 20 you walk slower; at 0 you faint and wake up the next morning. Eat by using a food item; drink by using the empty hand (or any non-tool) on water, or at the village well.
- **Health:** only matters in the mine. Fainting there means waking up at home the next morning with 10% of your money gone (max 200g). Sleeping restores health.
- **Mine:** five floors (Damp Tunnels, Root Hollow, Bone Gallery, Frozen Dark, Red Deep), dug out fresh each visit; a ladder down sits at the far end of each floor. The lift at the entrance goes to any floor already reached. A rusty sword waits on floor 1 the first time. Something waits at the bottom of floor 5.
- **Village:** rebuilding a building costs materials + money and finishes overnight ("nobody heard any hammering"). General store = seeds and food; flower shop = flower seeds and bouquets; blacksmith = copper/iron/gold axes, pickaxes and swords (the new tool replaces the old one in its slot). A fourth house stays boarded up.
- **Quest board:** one main quest from `data/quests/main` plus two daily notes from `data/quests`, refreshed each morning. Items are handed in at the board. Nobody is ever seen pinning them.
- **Saving:** autosaves every morning to the current slot; the pause menu also saves. A save from before slots existed becomes slot 1.

## Out of scope (for now)

Seasons and crafting. (Saving, mine enemies and the village are now in scope — sections 15-21.)

## Done when (full loop)

Starting a new game, the player can:
1. Walk to grass, till it, plant a seed, water it, sleep enough times for it to ripen, and harvest it.
2. Catch a fish, and collect an egg or milk from an animal.
3. Answer the landowner's call, see the first main quest on the village board, complete it and call him to get paid.
4. Put items in the shipping box, sleep, and see them sold for money.

All while the farm feels quietly watched, and nothing ever appears.
