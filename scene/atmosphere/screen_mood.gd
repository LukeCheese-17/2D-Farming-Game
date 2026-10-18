extends CanvasLayer
## Mood for the whole game world: muted colours, a dark vignette, and light that
## turns warm at dusk and cold and dark at night. Also plays the wind.

const DAY_TINT := Color(0.92, 0.9, 0.88)
const DUSK_TINT := Color(0.88, 0.64, 0.56)
const NIGHT_TINT := Color(0.28, 0.31, 0.48)
## A dim lamp keeps the house a little warmer at night.
const INDOOR_NIGHT_TINT := Color(0.55, 0.46, 0.4)
const EVENING := 17 * 60
## How fast the tint follows the clock (it moves in 10-minute steps).
const BLEND_SPEED := 1.5

@export var player: Player

var _tint := DAY_TINT

@onready var _material: ShaderMaterial = $Screen.material
@onready var _wind: AudioStreamPlayer = $Wind


func _process(delta: float) -> void:
	var darkness := GameState.get_darkness()
	var night_tint := INDOOR_NIGHT_TINT if player.indoors else NIGHT_TINT
	var target: Color
	if GameState.minutes >= EVENING and darkness < 0.5:
		target = DAY_TINT.lerp(DUSK_TINT, darkness * 2.0)
	elif GameState.minutes >= EVENING:
		target = DUSK_TINT.lerp(night_tint, (darkness - 0.5) * 2.0)
	else:
		target = DAY_TINT.lerp(night_tint, darkness)
	_tint = _tint.lerp(target, minf(1.0, delta * BLEND_SPEED))
	_material.set_shader_parameter("tint", _tint)
	_material.set_shader_parameter("desaturation", lerpf(0.3, 0.5, darkness))
	_material.set_shader_parameter("vignette", lerpf(0.35, 0.8, darkness))
	_wind.volume_db = -26.0 if player.indoors else lerpf(-20.0, -11.0, darkness)
