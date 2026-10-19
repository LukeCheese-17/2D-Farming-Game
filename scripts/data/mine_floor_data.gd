class_name MineFloorData
extends Resource
## One floor of the mine: its look, what its rocks give, and what lives there.

@export var display_name: String
## Column in assets/Generated/mine_tiles.png and mine_rocks.png.
@export var biome := 0
## Swings of a basic pickaxe needed per rock.
@export var rock_hardness := 2
## Every rock gives this.
@export var stone: ItemData
## Ore rocks also give this.
@export var ore: ItemData
@export_range(0.0, 1.0) var ore_chance := 0.25
## A rarer second ore.
@export var rare_ore: ItemData
@export_range(0.0, 1.0) var rare_chance := 0.05
@export var rock_count := 30
@export var enemies: Array[EnemyData] = []
@export var enemy_count := 4
## Shown when arriving on the floor.
@export var arrival_text := ""
