# Requirements — 2D Creepy Cozy Farm

A top-down 2D farming game built in Godot 4.6 (GDScript) with a **horror atmosphere and no monster**.
You live alone in a run-down house. A landline rings, and a man on the other end gives you jobs
for money. You farm, fish and raise animals, put what you make in the shipping box, and everything
in the box is sold each time you sleep. The whole time, it should feel like something is watching you.

The core loops are:
- **Farming:** plant → water → wait → harvest
- **Earning:** gather (farm / fish / animals) → shipping box → sleep → get paid
- **Jobs:** phone rings → take a task → complete it → get paid

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
| INV-1 | The player has a simple inventory holding seeds, harvested produce, fish and animal products, with counts. |
| INV-2 | The player can switch between the hoe, watering can, seeds, fishing rod, and empty hand (for harvesting and picking things up) with number keys. |
| INV-3 | The selected tool/item and item counts are shown on screen. |

## 8. Atmosphere — horror, no monster

The horror comes from mood and suggestion only. Nothing ever attacks, chases or appears.

| ID | Requirement |
|----|-------------|
| ATM-1 | **There is no monster.** No creature, enemy or figure is ever shown, and there is no combat, damage or death. |
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

## 10. Landline and jobs

| ID | Requirement |
|----|-------------|
| PHN-1 | A landline phone in the house rings at times, with a ringing sound and a visual cue (for example, the phone shaking and a "ring" icon). |
| PHN-2 | The player answers by walking to the phone and pressing the interact key. |
| PHN-3 | The caller is a man who gives the player a task for money, shown as dialogue text. Example: "Ship 10 wheat by day 5. I'll pay 200." |
| PHN-4 | A task asks for items the player can farm, fish or get from animals, an amount, and a deadline (day). |
| PHN-5 | The current task (what, how many, progress, deadline, reward) is shown on screen. |
| PHN-6 | When the task's items are shipped (see SHP) before the deadline, the reward money is paid out. |
| PHN-7 | The caller's lines stay short and slightly off, adding to the uneasy mood (ATM-2), without ever revealing who or what he is. |

## 11. Money and the shipping box

| ID | Requirement |
|----|-------------|
| SHP-1 | The player has money, shown on screen. |
| SHP-2 | There is a shipping box outside the house. The player can put items from their inventory into it with the interact key. |
| SHP-3 | Every time the player sleeps, everything in the shipping box is sold and the money is added. |
| SHP-4 | Each item type has a sell price, defined as data (like crops in TEC-4). |
| SHP-5 | After sleeping, the player sees what was sold and how much they earned. |

## 12. Fishing

| ID | Requirement |
|----|-------------|
| FSH-1 | The player can fish with the fishing rod by facing water and using the tool. |
| FSH-2 | After casting, there is a wait, then a bite signal; the player must react in time to catch the fish. |
| FSH-3 | A caught fish goes into the inventory. There are at least two fish types, defined as data. |
| FSH-4 | Fish can be shipped and sold, and can be asked for in phone tasks. |

## 13. Animals

| ID | Requirement |
|----|-------------|
| ANM-1 | The player raises farm animals: at least chickens and cows (sprites exist in `assets/Characters`). |
| ANM-2 | Animals live in a fenced area or coop and wander around it. |
| ANM-3 | Animals produce goods once per day (chickens → eggs, cows → milk), which the player collects with the hand. |
| ANM-4 | Animal products can be shipped and sold, and can be asked for in phone tasks. |

## 14. Technical requirements

| ID | Requirement |
|----|-------------|
| TEC-1 | Engine: Godot 4.6, GDScript, 640×360 viewport with integer scaling and nearest filtering (already configured). |
| TEC-2 | Ground uses `TileMapLayer` nodes with the shared `game_tile_set.tres`. |
| TEC-3 | The tileset has a physics layer for blocking tiles and a custom data layer (`can_till: bool`) for tillable ground. |
| TEC-4 | Crop types are defined as data (e.g. a `Resource` per crop: name, stage sprites, days to grow, produce) so new crops can be added without new code. The same applies to fish, animals, sellable items and phone tasks. |
| TEC-5 | Input uses named actions in the Input Map (`move_up`, `move_down`, `move_left`, `move_right`, `use_tool`, `interact`, `tool_1`…`tool_5`), not hard-coded keys. |
| TEC-6 | Characters and objects y-sort so the player can walk behind trees and in front of them. |

## Open questions

Things the vision doesn't settle yet. Each has a **provisional answer** chosen so the game could be built
(2026-10-19); change any of them and the game can be adjusted.

- **What is money for?** *Provisional:* buying seeds. Using the phone when it isn't ringing lets you order 5 wheat seeds for 40g; they're left at the door the next morning. (Without this, the starting seeds run out and farming stops.)
- **Do animals need care?** *Provisional:* no. Each animal has one product per day.
- **What happens when a phone task's deadline is missed?** *Provisional:* the job is lost with no reward, and the caller mentions it on his next call ("You let me down").
- **Is there an ending or a story?** *Provisional:* not yet. The caller repeats his jobs after the sixth.
- **Sound:** *Provisional:* simple generated placeholder sounds (phone ring, footsteps, wind, splash, bite, door creak) in `assets/Generated/`. Replace them with real recordings when available.

Other choices made while building:
- The camera is zoomed in 2x, so you only see the area around you (helps the "something is out there" feeling).
- A day runs from 06:00; 10 in-game minutes pass every 7 seconds. Staying up until 02:00 makes you pass out and wake up in bed.
- Some nights the phone rings and no one speaks (PHN-7 / ATM-2).

## Out of scope (for now)

Saving/loading, seasons, crafting, and any visible NPCs (the caller is only a voice on the phone).

## Done when (full loop)

Starting a new game, the player can:
1. Walk to grass, till it, plant a seed, water it, sleep enough times for it to ripen, and harvest it.
2. Catch a fish, and collect an egg or milk from an animal.
3. Answer the ringing phone and receive a task.
4. Put items in the shipping box, sleep, and see them sold for money, with the task paid out when completed.

All while the farm feels quietly watched, and nothing ever appears.
