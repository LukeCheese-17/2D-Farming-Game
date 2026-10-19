extends Node2D
## Ground fog drifting over the farm: thin by day, thick in the early morning and at
## night, and heavier on some days than others. Only covers the outdoor map, so the
## house stays clear.

const DAY_DENSITY := 0.12
const NIGHT_DENSITY := 0.55
## Extra fog at 6:00 that burns off by 9:00.
const MORNING_EXTRA := 0.25
const MORNING_END := 9 * 60
## How fast the density follows the clock.
const BLEND_SPEED := 0.5

@export var farm: Farm

var _density := 0.0
## Some days are foggier than others.
var _day_factor := 1.0

@onready var _sheet: ColorRect = $Sheet
@onready var _material: ShaderMaterial = _sheet.material


func _ready() -> void:
	var map := farm.get_map_rect()
	_sheet.position = map.position
	_sheet.size = map.size
	GameState.day_changed.connect(func(_day: int) -> void: _day_factor = randf_range(0.7, 1.4))
	_density = get_target_density()


## How thick the fog should be right now.
func get_target_density() -> float:
	var density := lerpf(DAY_DENSITY, NIGHT_DENSITY, GameState.get_darkness())
	if GameState.minutes < MORNING_END:
		density += MORNING_EXTRA * float(MORNING_END - GameState.minutes) / float(MORNING_END - GameState.DAY_START)
	return clampf(density * _day_factor, 0.0, 0.8)


func _process(delta: float) -> void:
	_density = lerpf(_density, get_target_density(), minf(1.0, delta * BLEND_SPEED))
	_material.set_shader_parameter("density", _density)
