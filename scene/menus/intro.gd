extends Control
## The intro after New Game, told without words: the player loses their office
## job, ends up sleeping on the street, finds a flyer for cheap land, spends the
## last of their coins on it and walks out to the run-down farm.
## Esc or Enter skips it. Everything is drawn in code; one tween plays it all.

const MAIN_SCENE := "res://scene/main/main.tscn"
const SHEET := preload("res://assets/Characters/Basic Charakter Spritesheet.png")
const EYES := preload("res://assets/Generated/eyes.png")
## Rows of the character sheet.
const FRONT := 0
const BACK := 1
const LEFT := 2
const RIGHT := 3
const INK := Color(0.15, 0.12, 0.1)
const CARDBOARD := Color(0.6, 0.45, 0.28)
const COIN := Color(0.9, 0.75, 0.25)

var _tween: Tween
var _done := false
var _time := 0.0
## Sprites walking in place: sprite -> sheet row.
var _walking: Dictionary[Sprite2D, int] = {}
var _shots: Array[Node2D] = []
var _fade := ColorRect.new()
var _wind := AudioStreamPlayer.new()
var _sfx := AudioStreamPlayer.new()

# The office
var _office := Node2D.new()
var _office_light: ColorRect
var _clock_hand: Polygon2D
var _papers: ColorRect
var _desk_box: ColorRect
var _boss := Node2D.new()
var _boss_arm: Polygon2D
var _worker: Sprite2D
# The street
var _street := Node2D.new()
var _street_sky: ColorRect
var _street_box: ColorRect
var _cup: Node2D
var _drifter: Sprite2D
var _street_flyer: Polygon2D
# The flyer
var _flyer_shot := Node2D.new()
var _coins: Array[Node2D] = []
var _tab: Node2D
var _stamp := Node2D.new()
# The road
var _road := Node2D.new()
var _road_sky: ColorRect
var _sun: Polygon2D
var _road_trees := Node2D.new()
var _walker: Sprite2D
# The farm
var _arrival := Node2D.new()
var _arrival_eyes := Sprite2D.new()
var _fogs: Array[ColorRect] = []
var _newcomer: Sprite2D
var _arrival_box: ColorRect


func _ready() -> void:
	GameState.clock_running = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	for shot: Node2D in [_office, _street, _flyer_shot, _road, _arrival]:
		shot.hide()
		add_child(shot)
		_shots.append(shot)
	_build_office()
	_build_street()
	_build_flyer()
	_build_road()
	_build_arrival()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	var hint := Label.new()
	hint.text = "Esc: skip"
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	hint.position = Vector2(590, 346)
	add_child(hint)
	_wind.stream = preload("res://assets/Generated/wind.wav")
	_wind.volume_db = -14.0
	add_child(_wind)
	add_child(_sfx)
	_play()


func _process(delta: float) -> void:
	_time += delta
	for sprite in _walking:
		sprite.frame = _walking[sprite] * 4 + int(_time * 8.0) % 4
	if _boss.visible and _boss.has_meta("walking"):
		_boss.position.y = 262 - absf(sin(_time * 10.0)) * 2.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		finish()


## Ends the intro and starts the game.
func finish() -> void:
	if _done:
		return
	_done = true
	if _tween:
		_tween.kill()
	get_tree().change_scene_to_file(MAIN_SCENE)


# --- The sequence ---

func _play() -> void:
	var t := create_tween()
	_tween = t
	# The office: the same desk and the same clock, day after day.
	t.tween_callback(_show_shot.bind(_office))
	t.tween_property(_fade, "color:a", 0.0, 1.2)
	t.tween_property(_clock_hand, "rotation", TAU * 5.0, 4.5)
	t.parallel().tween_property(_papers, "size:y", 48.0, 4.5)
	t.parallel().tween_property(_papers, "position:y", 214.0 - 48.0, 4.5)
	t.parallel().tween_method(_flicker, 0.0, 1.0, 4.5)
	# The boss comes over, drops a box on the desk and points at the door.
	t.tween_callback(_boss.set_meta.bind("walking", true))
	t.tween_property(_boss, "position:x", 470.0, 1.6)
	t.tween_callback(_boss.remove_meta.bind("walking"))
	t.tween_property(_desk_box, "position:y", 190.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.6)
	t.tween_property(_boss_arm, "rotation", PI / 2.0, 0.35)
	t.tween_interval(0.5)
	t.tween_callback(_face.bind(_worker, FRONT))
	t.tween_interval(1.4)
	# The worker takes the box and leaves.
	t.tween_callback(_desk_box.hide)
	t.tween_callback(_box(_worker).show)
	t.tween_callback(_walk.bind(_worker, LEFT))
	t.tween_property(_worker, "position:x", 70.0, 2.6)
	t.tween_callback(_play_sound.bind("door_creak"))
	t.tween_property(_fade, "color:a", 1.0, 0.8)
	t.tween_interval(0.6)

	# The street: nowhere to go.
	t.tween_callback(_show_shot.bind(_street))
	t.tween_callback(_wind.play)
	t.tween_callback(_walk.bind(_drifter, LEFT))
	t.tween_property(_fade, "color:a", 0.0, 1.0)
	t.parallel().tween_property(_drifter, "position:x", 372.0, 3.0)
	t.tween_callback(_face.bind(_drifter, FRONT))
	t.tween_callback(_box(_drifter).hide)
	t.tween_callback(_street_box.show)
	t.tween_interval(0.8)
	# Days and nights go by under the lamp.
	t.tween_callback(_lie_down)
	t.tween_property(_street_box, "size", Vector2(64, 6), 0.8)
	t.parallel().tween_property(_street_box, "position", Vector2(340, 264), 0.8)
	for night in 3:
		t.tween_property(_street_sky, "color", Color(0.32, 0.28, 0.33), 0.9)
		t.tween_property(_street_sky, "color", Color(0.04, 0.05, 0.09), 0.9)
		if night == 0:
			t.tween_callback(_cup.show)
	# A flyer blows down the street and lands on them.
	t.tween_property(_street_flyer, "position", Vector2(392, 258), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_street_flyer, "rotation", TAU * 4.0, 2.4).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.5)
	t.tween_callback(_sit_up)
	t.tween_interval(1.0)
	t.tween_property(_fade, "color:a", 1.0, 0.6)

	# The flyer: cheap land. They count what's left and call.
	t.tween_callback(_show_shot.bind(_flyer_shot))
	t.tween_property(_fade, "color:a", 0.0, 0.6)
	t.tween_interval(2.4)
	for coin in _coins:
		t.tween_callback(_play_sound.bind("ui_select"))
		t.tween_property(coin, "position:y", coin.get_meta("rest"), 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.9)
	t.tween_property(_tab, "position:y", _tab.position.y + 50.0, 0.6).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_tab, "modulate:a", 0.0, 0.6)
	t.tween_interval(0.8)
	t.tween_callback(_stamp.show)
	t.tween_callback(_play_sound.bind("pick"))
	t.tween_property(_stamp, "scale", Vector2.ONE, 0.18).from(Vector2(2.5, 2.5))
	t.parallel().tween_property(_stamp, "modulate:a", 0.9, 0.18).from(0.0)
	t.tween_callback(_shake.bind(_flyer_shot))
	t.tween_interval(1.6)
	t.tween_property(_fade, "color:a", 1.0, 0.8)

	# The road out of town, as the trees get darker.
	t.tween_callback(_show_shot.bind(_road))
	t.tween_callback(_walk.bind(_walker, RIGHT))
	t.tween_property(_fade, "color:a", 0.0, 1.0)
	t.parallel().tween_property(_road_trees, "position:x", -1500.0, 7.0)
	t.parallel().tween_property(_road_sky, "color", Color(0.1, 0.07, 0.12), 7.0)
	t.parallel().tween_property(_sun, "position:y", 250.0, 7.0)
	t.tween_property(_fade, "color:a", 1.0, 0.8)

	# The farm.
	t.tween_callback(_show_shot.bind(_arrival))
	t.tween_callback(_walk.bind(_newcomer, RIGHT))
	for fog in _fogs:
		t.parallel().tween_property(fog, "position:x", fog.position.x + 120.0, 14.0)
	t.parallel().tween_property(_fade, "color:a", 0.0, 1.5)
	t.parallel().tween_property(_newcomer, "position:x", 330.0, 3.6)
	t.tween_callback(_face.bind(_newcomer, BACK))
	t.tween_callback(_box(_newcomer).hide)
	t.tween_callback(_arrival_box.show)
	t.tween_interval(1.8)
	# Something in the trees is watching. When they turn to look, it's gone.
	t.tween_property(_arrival_eyes, "modulate:a", 0.85, 1.2)
	t.tween_interval(0.9)
	t.tween_callback(_face.bind(_newcomer, RIGHT))
	t.tween_property(_arrival_eyes, "modulate:a", 0.0, 0.1)
	t.tween_interval(1.4)
	t.tween_callback(_face.bind(_newcomer, BACK))
	t.tween_interval(0.6)
	t.tween_property(_fade, "color:a", 1.0, 2.0)
	t.tween_callback(finish)


func _show_shot(shot: Node2D) -> void:
	for s in _shots:
		s.visible = s == shot
	_walking.clear()


func _walk(sprite: Sprite2D, row: int) -> void:
	_walking[sprite] = row


func _face(sprite: Sprite2D, row: int) -> void:
	_walking.erase(sprite)
	sprite.frame = row * 4


func _flicker(_progress: float) -> void:
	_office_light.modulate.a = 0.35 if randf() < 0.05 else 1.0


func _lie_down() -> void:
	_drifter.rotation = -PI / 2.0
	_drifter.position = Vector2(372, 258)


func _sit_up() -> void:
	_drifter.rotation = 0.0
	_drifter.position = Vector2(372, 248)
	_face(_drifter, FRONT)
	_street_flyer.position = Vector2(384, 252)
	_street_flyer.rotation = 0.2


func _shake(node: Node2D) -> void:
	var t := create_tween()
	for x: float in [5.0, -4.0, 3.0, -1.0, 0.0]:
		t.tween_property(node, "position:x", x, 0.04)


func _play_sound(sound: String) -> void:
	_sfx.stream = load("res://assets/Generated/%s.wav" % sound)
	_sfx.play()


# --- Building the shots ---

func _rect(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


func _poly(parent: Node, points: Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array(points)
	poly.color = color
	parent.add_child(poly)
	return poly


func _circle(parent: Node, center: Vector2, radius: float, color: Color) -> Polygon2D:
	var points := []
	for i in 20:
		points.append(center + Vector2.from_angle(TAU * i / 20.0) * radius)
	return _poly(parent, points, color)


func _label(parent: Node, text: String, pos: Vector2, width: float, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(width, font_size + 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


## The player character, facing row, with a cardboard box they can carry (hidden).
func _person(parent: Node, pos: Vector2, row: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = SHEET
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.frame = row * 4
	sprite.scale = Vector2(3, 3)
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)
	var box := _rect(sprite, Vector2(-5, 2), Vector2(10, 6), CARDBOARD)
	box.name = "Box"
	box.hide()
	return sprite


func _build_office() -> void:
	var o := _office
	_rect(o, Vector2(0, 0), Vector2(640, 250), Color(0.3, 0.33, 0.31))
	_rect(o, Vector2(0, 250), Vector2(640, 110), Color(0.2, 0.2, 0.22))
	_rect(o, Vector2(0, 246), Vector2(640, 4), Color(0.16, 0.17, 0.17))
	_office_light = _rect(o, Vector2(220, 8), Vector2(200, 6), Color(0.85, 0.92, 0.85))
	# Cubicles stretching back, all the same.
	for i in 6:
		_rect(o, Vector2(i * 110 - 20, 150), Vector2(90, 96), Color(0.36, 0.38, 0.4))
		_rect(o, Vector2(i * 110 + 10, 128), Vector2(30, 22), Color(0.12, 0.13, 0.14))
	# The door out.
	_rect(o, Vector2(36, 128), Vector2(56, 122), Color(0.25, 0.18, 0.12))
	_rect(o, Vector2(80, 188), Vector2(5, 5), Color(0.7, 0.6, 0.3))
	# The clock.
	var clock := Node2D.new()
	clock.position = Vector2(520, 60)
	o.add_child(clock)
	_circle(clock, Vector2.ZERO, 20, Color(0.15, 0.15, 0.15))
	_circle(clock, Vector2.ZERO, 17, Color(0.9, 0.9, 0.85))
	_clock_hand = _poly(clock, [Vector2(-1.5, 0), Vector2(0, -14), Vector2(1.5, 0)], Color(0.1, 0.1, 0.1))
	# The desk, the monitor and the papers.
	_rect(o, Vector2(270, 214), Vector2(190, 10), Color(0.42, 0.36, 0.3))
	_rect(o, Vector2(278, 224), Vector2(8, 26), Color(0.3, 0.26, 0.22))
	_rect(o, Vector2(444, 224), Vector2(8, 26), Color(0.3, 0.26, 0.22))
	_rect(o, Vector2(335, 166), Vector2(66, 46), Color(0.1, 0.1, 0.12))
	_rect(o, Vector2(339, 170), Vector2(58, 36), Color(0.45, 0.7, 0.75))
	_rect(o, Vector2(363, 206), Vector2(10, 8), Color(0.1, 0.1, 0.12))
	_papers = _rect(o, Vector2(290, 210), Vector2(30, 4), Color(0.92, 0.92, 0.88))
	_desk_box = _rect(o, Vector2(405, -40), Vector2(40, 24), CARDBOARD)
	# The boss: a dark suit and a red tie.
	_boss.position = Vector2(720, 262)
	o.add_child(_boss)
	_rect(_boss, Vector2(-13, -62), Vector2(26, 62), Color(0.1, 0.1, 0.13))
	_rect(_boss, Vector2(-2, -60), Vector2(4, 18), Color(0.6, 0.1, 0.1))
	_circle(_boss, Vector2(0, -72), 10, Color(0.7, 0.66, 0.6))
	_boss_arm = _poly(_boss, [Vector2(-3, 0), Vector2(3, 0), Vector2(3, 30), Vector2(-3, 30)], Color(0.1, 0.1, 0.13))
	_boss_arm.position = Vector2(-13, -56)
	_worker = _person(o, Vector2(370, 236), BACK)


func _build_street() -> void:
	var s := _street
	_street_sky = _rect(s, Vector2.ZERO, Vector2(640, 270), Color(0.04, 0.05, 0.09))
	# Buildings, most windows dark.
	var x := -10
	var i := 0
	while x < 640:
		var w := 60 + (i * 37) % 50
		var h := 90 + (i * 53) % 110
		_rect(s, Vector2(x, 270 - h), Vector2(w, h), Color(0.07, 0.07, 0.1))
		for wy in range(270 - h + 12, 250, 22):
			for wx in range(x + 8, x + w - 10, 16):
				if (wx * 7 + wy * 3 + i) % 9 == 0:
					_rect(s, Vector2(wx, wy), Vector2(6, 8), Color(0.8, 0.7, 0.4, 0.7))
		x += w + 4
		i += 1
	_rect(s, Vector2(0, 270), Vector2(640, 90), Color(0.1, 0.1, 0.12))
	_rect(s, Vector2(0, 268), Vector2(640, 3), Color(0.2, 0.2, 0.22))
	# The streetlamp.
	_poly(s, [Vector2(372, 132), Vector2(300, 272), Vector2(444, 272)], Color(1, 0.9, 0.6, 0.12))
	_rect(s, Vector2(400, 130), Vector2(5, 140), Color(0.15, 0.15, 0.17))
	_rect(s, Vector2(362, 124), Vector2(43, 5), Color(0.15, 0.15, 0.17))
	_rect(s, Vector2(364, 129), Vector2(16, 4), Color(1, 0.92, 0.65))
	_street_box = _rect(s, Vector2(346, 248), Vector2(36, 22), CARDBOARD)
	_street_box.hide()
	_cup = Node2D.new()
	_cup.position = Vector2(318, 268)
	s.add_child(_cup)
	_rect(_cup, Vector2(-4, -10), Vector2(9, 10), Color(0.85, 0.85, 0.8))
	_circle(_cup, Vector2(0, -11), 2, COIN)
	_cup.hide()
	_drifter = _person(s, Vector2(700, 248), LEFT)
	_box(_drifter).show()
	_street_flyer = _poly(s, [Vector2(-5, -7), Vector2(5, -7), Vector2(5, 7), Vector2(-5, 7)], Color(0.92, 0.9, 0.82))
	_street_flyer.position = Vector2(700, 110)
	# Rain.
	var rain := CPUParticles2D.new()
	var drop := GradientTexture2D.new()
	drop.width = 1
	drop.height = 7
	drop.fill_to = Vector2(0, 1)
	drop.gradient = Gradient.new()
	drop.gradient.set_color(0, Color(1, 1, 1, 0))
	drop.gradient.set_color(1, Color.WHITE)
	rain.texture = drop
	rain.amount = 160
	rain.lifetime = 0.9
	rain.preprocess = 1.0
	rain.position = Vector2(320, -10)
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(360, 4)
	rain.direction = Vector2(-0.15, 1)
	rain.spread = 0.0
	rain.gravity = Vector2.ZERO
	rain.initial_velocity_min = 380.0
	rain.initial_velocity_max = 420.0
	rain.color = Color(0.6, 0.7, 0.9, 0.35)
	s.add_child(rain)


func _build_flyer() -> void:
	var f := _flyer_shot
	_rect(f, Vector2.ZERO, Vector2(640, 360), Color(0.08, 0.08, 0.09))
	var paper := Node2D.new()
	paper.position = Vector2(300, 180)
	paper.rotation = -0.03
	f.add_child(paper)
	_rect(paper, Vector2(-120, -160), Vector2(240, 320), Color(0.9, 0.88, 0.8))
	_label(paper, "LAND FOR SALE", Vector2(-120, -150), 240, 22, INK)
	# A little drawing of a farm.
	_rect(paper, Vector2(-95, -30), Vector2(190, 14), Color(0.4, 0.6, 0.3))
	for row in 3:
		_rect(paper, Vector2(-90, -27 + row * 4), Vector2(180, 1), Color(0.3, 0.45, 0.2))
	_rect(paper, Vector2(-55, -76), Vector2(54, 46), Color(0.55, 0.38, 0.25))
	_poly(paper, [Vector2(-62, -76), Vector2(-28, -104), Vector2(6, -76)], Color(0.55, 0.2, 0.15))
	_rect(paper, Vector2(-34, -54), Vector2(12, 24), Color(0.3, 0.2, 0.12))
	_rect(paper, Vector2(-50, -68), Vector2(10, 9), Color(0.75, 0.85, 0.9))
	_rect(paper, Vector2(53, -64), Vector2(6, 34), Color(0.35, 0.22, 0.12))
	_circle(paper, Vector2(56, -72), 16, Color(0.3, 0.55, 0.28))
	_circle(paper, Vector2(78, -108), 9, Color(0.95, 0.8, 0.3))
	# The price: cheap.
	_label(paper, "CHEAP!", Vector2(-120, -6), 240, 26, Color(0.75, 0.12, 0.1))
	_circle(paper, Vector2(-26, 50), 11, COIN)
	_label(paper, "300", Vector2(-14, 38), 50, 20, INK)
	# Tear-off phone number tabs along the bottom.
	_rect(paper, Vector2(-120, 92), Vector2(240, 1), Color(0.6, 0.58, 0.52))
	for i in 8:
		var tab := Node2D.new()
		tab.position = Vector2(-114 + i * 29, 96)
		paper.add_child(tab)
		_rect(tab, Vector2(0, 0), Vector2(24, 60), Color(0.88, 0.86, 0.78))
		var number := _label(tab, "555-0134", Vector2(5, 56), 56, 8, INK)
		number.rotation = -PI / 2.0
		if i == 3:
			_tab = tab
	# All the money they have left.
	for spot: Vector2 in [Vector2(480, 300), Vector2(496, 300), Vector2(512, 300), Vector2(488, 293), Vector2(504, 293), Vector2(496, 286)]:
		var coin := Node2D.new()
		coin.position = Vector2(spot.x, -30)
		coin.set_meta("rest", spot.y)
		f.add_child(coin)
		_circle(coin, Vector2.ZERO, 8, Color(0.6, 0.45, 0.15))
		_circle(coin, Vector2.ZERO, 6.5, COIN)
		_coins.append(coin)
	# SOLD.
	_stamp.position = Vector2(300, 170)
	_stamp.rotation = -0.35
	_stamp.hide()
	f.add_child(_stamp)
	var red := Color(0.8, 0.1, 0.1)
	var border := Line2D.new()
	border.points = PackedVector2Array([Vector2(-70, -28), Vector2(70, -28), Vector2(70, 28), Vector2(-70, 28)])
	border.closed = true
	border.width = 4.0
	border.default_color = red
	_stamp.add_child(border)
	_label(_stamp, "SOLD", Vector2(-70, -26), 140, 36, red)


func _build_road() -> void:
	var r := _road
	_road_sky = _rect(r, Vector2.ZERO, Vector2(640, 270), Color(0.55, 0.3, 0.25))
	_sun = _circle(r, Vector2(480, 0), 22, Color(1, 0.6, 0.3))
	_sun.position.y = 140
	_poly(r, [Vector2(0, 270), Vector2(0, 220), Vector2(120, 190), Vector2(260, 215), Vector2(400, 180),
		Vector2(540, 210), Vector2(640, 195), Vector2(640, 270)], Color(0.18, 0.12, 0.14))
	r.add_child(_road_trees)
	# Healthy trees near town, then bare and twisted ones the further out they get.
	for i in 26:
		var tx := i * 90.0 + 40.0
		var tree := Node2D.new()
		tree.position = Vector2(tx, 270)
		_road_trees.add_child(tree)
		if i < 9:
			_rect(tree, Vector2(-3, -30), Vector2(6, 30), Color(0.2, 0.13, 0.1))
			_circle(tree, Vector2(0, -42), 18, Color(0.14, 0.24, 0.14))
		else:
			var dark := Color(0.06, 0.05, 0.07)
			var h := 60.0 + (i * 23) % 40
			_poly(tree, [Vector2(-4, 0), Vector2(-2, -h), Vector2(2, -h), Vector2(4, 0)], dark)
			_poly(tree, [Vector2(-1, -h * 0.6), Vector2(-22, -h * 0.9), Vector2(-20, -h * 0.95), Vector2(1, -h * 0.68)], dark)
			_poly(tree, [Vector2(1, -h * 0.75), Vector2(18, -h * 1.05), Vector2(20, -h), Vector2(1, -h * 0.82)], dark)
			_poly(tree, [Vector2(-1, -h * 0.4), Vector2(14, -h * 0.55), Vector2(14, -h * 0.5), Vector2(1, -h * 0.45)], dark)
	_rect(r, Vector2(0, 270), Vector2(640, 90), Color(0.16, 0.13, 0.11))
	_rect(r, Vector2(0, 276), Vector2(640, 18), Color(0.28, 0.22, 0.17))
	_walker = _person(r, Vector2(300, 266), RIGHT)
	_box(_walker).show()


func _build_arrival() -> void:
	var a := _arrival
	_rect(a, Vector2.ZERO, Vector2(640, 360), Color(0.04, 0.05, 0.07))
	_circle(a, Vector2(120, 60), 16, Color(0.85, 0.85, 0.75))
	_rect(a, Vector2(84, 62), Vector2(80, 8), Color(0.1, 0.11, 0.14))
	var points := [Vector2(0, 262), Vector2(0, 220)]
	for i in 33:
		points.append(Vector2(i * 20, 205 + (i * 37 % 23) - (14 if i % 3 == 0 else 0)))
	points.append_array([Vector2(640, 220), Vector2(640, 262)])
	_poly(a, points, Color(0.015, 0.02, 0.025))
	_arrival_eyes.texture = EYES
	_arrival_eyes.position = Vector2(590, 222)
	_arrival_eyes.modulate = Color(1, 0.9, 0.7, 0.0)
	a.add_child(_arrival_eyes)
	_rect(a, Vector2(0, 258), Vector2(640, 102), Color(0.08, 0.09, 0.07))
	for i in 40:
		var wx := (i * 71) % 640
		var wy := 266 + (i * 29) % 80
		_poly(a, [Vector2(wx, wy), Vector2(wx + 2, wy - 7), Vector2(wx + 4, wy)], Color(0.12, 0.16, 0.1))
	# The house: sagging roof, boarded windows, a board across the door.
	var wall := Color(0.17, 0.14, 0.12)
	var board := Color(0.32, 0.24, 0.16)
	_rect(a, Vector2(400, 160), Vector2(150, 100), wall)
	_poly(a, [Vector2(390, 162), Vector2(440, 112), Vector2(500, 122), Vector2(560, 162)], Color(0.1, 0.08, 0.08))
	_poly(a, [Vector2(470, 130), Vector2(488, 128), Vector2(482, 142)], Color(0.04, 0.05, 0.07))
	for wx: float in [418.0, 508.0]:
		_rect(a, Vector2(wx, 186), Vector2(24, 22), Color(0.02, 0.02, 0.03))
		var plank := _rect(a, Vector2(wx - 3, 194), Vector2(30, 4), board)
		plank.rotation = 0.25 if wx < 450 else -0.2
	_rect(a, Vector2(464, 214), Vector2(22, 46), Color(0.06, 0.05, 0.05))
	var door_board := _rect(a, Vector2(460, 232), Vector2(30, 4), board)
	door_board.rotation = -0.3
	# A broken fence and the sign.
	for i in 11:
		var post := _rect(a, Vector2(360 + i * 24, 262), Vector2(4, 18), board)
		post.rotation = ((i * 17) % 7 - 3) * 0.04
	for i in [0, 1, 2, 5, 6, 8]:
		_rect(a, Vector2(360 + i * 24, 268), Vector2(24, 3), board)
	_rect(a, Vector2(338, 236), Vector2(4, 40), board)
	_rect(a, Vector2(320, 226), Vector2(40, 16), Color(0.85, 0.82, 0.72))
	_label(a, "SOLD", Vector2(320, 226), 40, 10, Color(0.75, 0.1, 0.1))
	_newcomer = _person(a, Vector2(-40, 262), RIGHT)
	_box(_newcomer).show()
	_arrival_box = _rect(a, Vector2(300, 270), Vector2(36, 22), CARDBOARD)
	_arrival_box.hide()
	for i in 3:
		var fog := _rect(a, Vector2(-200 + i * 260, 248 + i * 16), Vector2(420, 18), Color(0.6, 0.65, 0.7, 0.07))
		_fogs.append(fog)


## The box a person sprite carries.
func _box(person: Sprite2D) -> ColorRect:
	return person.get_node("Box") as ColorRect
