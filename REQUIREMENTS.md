# Requirements — 2D Cozy Farm

A top-down 2D farming game built in Godot 4.6 (GDScript). The core loop is:
**plant → water → wait → harvest**.

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
| INV-1 | The player has a simple inventory holding seeds and harvested produce with counts. |
| INV-2 | The player can switch between the hoe, watering can, seeds, and empty hand (for harvesting) with number keys. |
| INV-3 | The selected tool/item and item counts are shown on screen. |

## 8. Technical requirements

| ID | Requirement |
|----|-------------|
| TEC-1 | Engine: Godot 4.6, GDScript, 640×360 viewport with integer scaling and nearest filtering (already configured). |
| TEC-2 | Ground uses `TileMapLayer` nodes with the shared `game_tile_set.tres`. |
| TEC-3 | The tileset has a physics layer for blocking tiles and a custom data layer (`can_till: bool`) for tillable ground. |
| TEC-4 | Crop types are defined as data (e.g. a `Resource` per crop: name, stage sprites, days to grow, produce) so new crops can be added without new code. |
| TEC-5 | Input uses named actions in the Input Map (`move_up`, `move_down`, `move_left`, `move_right`, `use_tool`, `tool_1`…`tool_4`), not hard-coded keys. |
| TEC-6 | Characters and objects y-sort so the player can walk behind trees and in front of them. |

## Out of scope (for now)

Saving/loading, shops and money, animals, seasons, NPCs, crafting, and sound.

## Done when (full loop)

Starting a new game, the player can walk to grass, till it, plant a seed, water it, end the day enough times for it to ripen (watering each day), and harvest it, with the produce appearing in the inventory.
