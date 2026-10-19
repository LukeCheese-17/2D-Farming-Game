class_name FishingRing
extends Control
## Fishing minigame: a needle sweeps around a dial. Press the tool key while it's
## inside the lit zone; land enough hits in a row to catch the fish. A miss, or
## letting the needle go round too many times, lets the fish go.

signal finished(success: bool)

const RADIUS := 22.0
const ZONE_WIDTH := 6.0
## Full turns allowed for each hit before the fish escapes.
const MAX_TURNS := 3.0
const BACKGROUND := Color(0.05, 0.04, 0.06, 0.85)
const RIM := Color(0.55, 0.5, 0.5)
const ZONE := Color(0.55, 0.85, 0.5)
const NEEDLE := Color(1.0, 0.95, 0.85)
const PIP_EMPTY := Color(0.3, 0.28, 0.28)

var _fish: FishData
var _angle := 0.0
var _zone_start := 0.0
var _turned := 0.0
var _hits := 0
var _flash := 0.0


func _ready() -> void:
	hide()
	set_process(false)


func start(fish: FishData) -> void:
	_fish = fish
	_hits = 0
	_angle = -90.0
	_place_zone()
	show()
	set_process(true)


func _process(delta: float) -> void:
	var step := _fish.needle_speed * delta
	_angle = fposmod(_angle + step, 360.0)
	_turned += step
	_flash = maxf(0.0, _flash - delta)
	if _turned > 360.0 * MAX_TURNS:
		_finish(false)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("use_tool"):
		return
	get_viewport().set_input_as_handled()
	if not _needle_in_zone():
		_finish(false)
		return
	_hits += 1
	_flash = 0.15
	if _hits >= _fish.hits_needed:
		_finish(true)
	else:
		_place_zone()


## Moves the zone somewhere the needle won't reach for at least a quarter turn.
func _place_zone() -> void:
	_zone_start = fposmod(_angle + randf_range(90.0, 270.0 - _fish.zone_degrees), 360.0)
	_turned = 0.0


func _needle_in_zone() -> bool:
	return fposmod(_angle - _zone_start, 360.0) <= _fish.zone_degrees


func _finish(success: bool) -> void:
	hide()
	set_process(false)
	finished.emit(success)


func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, RADIUS + 5.0, BACKGROUND)
	draw_arc(center, RADIUS, 0.0, TAU, 48, RIM, 1.0)
	var zone_color := Color.WHITE if _flash > 0.0 else ZONE
	draw_arc(center, RADIUS, deg_to_rad(_zone_start), deg_to_rad(_zone_start + _fish.zone_degrees), 16, zone_color, ZONE_WIDTH)
	draw_line(center, center + Vector2.from_angle(deg_to_rad(_angle)) * (RADIUS + 3.0), NEEDLE, 2.0)
	draw_circle(center, 2.0, NEEDLE)
	var pips_left := center.x - (_fish.hits_needed - 1) * 4.0
	for i in _fish.hits_needed:
		draw_circle(Vector2(pips_left + i * 8.0, center.y + RADIUS + 11.0), 2.5, ZONE if i < _hits else PIP_EMPTY)
