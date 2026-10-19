extends SceneTree
## Draws the placeholder art and sounds in assets/Generated/ (fish, crops, ores,
## tools, mine tiles, enemies, props, UI icons, sound effects). Run from the project folder:
##   godot --headless --path . -s tools/generate_assets.gd
## then re-import. Replace any of the files with real art when it exists.

const OUT := "res://assets/Generated/"
const INK := Color(0.17, 0.12, 0.17)
const HALO := Color(0.96, 0.93, 0.84)
const MIX_RATE := 22050

var _plants: Image
var _materials: Image


func _initialize() -> void:
	seed(1234)
	_plants = Image.load_from_file(ProjectSettings.globalize_path("res://assets/Objects/Basic_Plants.png"))
	_plants.convert(Image.FORMAT_RGBA8)
	_materials = Image.load_from_file(ProjectSettings.globalize_path("res://assets/Objects/Basic_tools_and_meterials.png"))
	_materials.convert(Image.FORMAT_RGBA8)
	_make_fish()
	_make_crops()
	_make_items()
	_make_tools()
	_make_mine()
	_make_enemies()
	_make_props()
	_make_icons()
	_make_sounds()
	print("Generated assets.")
	quit()


# --- Drawing helpers ---

func _img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


func _save(img: Image, name: String) -> void:
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))


func _ellipse(img: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var d := Vector2((x + 0.5 - center.x) / radius.x, (y + 0.5 - center.y) / radius.y)
			if d.length_squared() <= 1.0:
				img.set_pixel(x, y, color)


func _poly(img: Image, points: PackedVector2Array, color: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				img.set_pixel(x, y, color)


func _rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(img, xx, yy, color)


func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, color)


func _line(img: Image, from: Vector2, to: Vector2, color: Color) -> void:
	var steps := int(maxf(absf(to.x - from.x), absf(to.y - from.y))) + 1
	for i in steps + 1:
		var p := from.lerp(to, float(i) / steps)
		_px(img, roundi(p.x), roundi(p.y), color)


## Adds a 1 px ring of colour around everything drawn so far.
func _outline(img: Image, color: Color) -> void:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for o: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var p := Vector2i(x, y) + o
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and src.get_pixelv(p).a > 0.0:
					img.set_pixel(x, y, color)
					break


## The dark outline plus the pale halo the bought icons have.
func _icon_edges(img: Image) -> void:
	_outline(img, INK)
	_outline(img, HALO)


func _noise(img: Image, rect: Rect2i, amount: float) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				var n := randf_range(-amount, amount)
				img.set_pixel(x, y, Color(c.r + n, c.g + n, c.b + n, c.a))


func _region(src: Image, x: int, y: int, w := 16, h := 16) -> Image:
	return src.get_region(Rect2i(x, y, w, h))


## Recolours the grey metal parts of a tool icon.
func _tint_metal(img: Image, tint: Color) -> Image:
	var out := img.duplicate() as Image
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			if c.a > 0.0 and c.s < 0.22 and c.v > 0.3 and c.v < 0.92:
				out.set_pixel(x, y, Color(tint.r * c.v * 1.35, tint.g * c.v * 1.35, tint.b * c.v * 1.35, c.a))
	return out


# --- Fish ---

func _make_fish() -> void:
	# name, body, belly, fin, length, height, style
	var fish := [
		["grey_minnow", Color(0.55, 0.6, 0.55), Color(0.78, 0.8, 0.74), Color(0.42, 0.48, 0.44), 9.0, 4.0, ""],
		["bog_carp", Color(0.5, 0.45, 0.28), Color(0.7, 0.64, 0.42), Color(0.38, 0.32, 0.2), 12.0, 7.0, ""],
		["black_koi", Color(0.16, 0.15, 0.18), Color(0.85, 0.82, 0.78), Color(0.25, 0.22, 0.26), 11.0, 6.0, "spots"],
		["river_trout", Color(0.62, 0.58, 0.6), Color(0.85, 0.7, 0.7), Color(0.45, 0.42, 0.45), 12.0, 5.0, "dots"],
		["silver_dace", Color(0.72, 0.75, 0.8), Color(0.9, 0.9, 0.92), Color(0.55, 0.58, 0.64), 10.0, 4.0, ""],
		["whisker_cat", Color(0.3, 0.3, 0.32), Color(0.55, 0.52, 0.5), Color(0.22, 0.22, 0.24), 12.0, 6.0, "whiskers"],
		["glass_eel", Color(0.7, 0.82, 0.88, 0.75), Color(0.85, 0.92, 0.95, 0.75), Color(0.6, 0.72, 0.8, 0.75), 14.0, 3.0, "eel"],
		["drowned_pike", Color(0.38, 0.45, 0.35), Color(0.62, 0.66, 0.52), Color(0.3, 0.36, 0.28), 14.0, 5.0, "stripes"],
		["weeping_gar", Color(0.48, 0.5, 0.42), Color(0.68, 0.7, 0.6), Color(0.36, 0.38, 0.3), 13.0, 3.0, "snout"],
		["bone_fish", Color(0.88, 0.86, 0.8), Color(0.88, 0.86, 0.8), Color(0.75, 0.72, 0.66), 12.0, 6.0, "bones"],
	]
	for f: Array in fish:
		var img := _img(16, 16)
		var length: float = f[4]
		var height: float = f[5]
		var style: String = f[6]
		var center := Vector2(8.5, 8.0)
		if style == "bones":
			_line(img, Vector2(3, 8), Vector2(12, 8), f[1])
			for x in range(5, 11, 2):
				_line(img, Vector2(x, 5), Vector2(x, 11), f[1])
			_ellipse(img, Vector2(12.5, 8), Vector2(2.5, 3), f[1])
			_px(img, 13, 7, INK)
			_poly(img, PackedVector2Array([Vector2(1, 5), Vector2(4, 8), Vector2(1, 11)]), f[3])
		elif style == "eel":
			for x in range(2, 15):
				var y := 8.0 + sin(x * 0.8) * 1.5
				_rect(img, x, roundi(y) - 1, 1, 3, f[1])
			_px(img, 13, roundi(8.0 + sin(13 * 0.8) * 1.5) - 1, INK)
		else:
			_poly(img, PackedVector2Array([
				Vector2(center.x - length / 2.0 + 1, center.y),
				Vector2(center.x - length / 2.0 - 3, center.y - height / 2.0 - 1),
				Vector2(center.x - length / 2.0 - 3, center.y + height / 2.0 + 1)]), f[3])
			_ellipse(img, center, Vector2(length / 2.0, height / 2.0), f[1])
			_ellipse(img, center + Vector2(0, height * 0.25), Vector2(length / 2.6, height / 4.0), f[2])
			_rect(img, int(center.x) - 1, int(center.y - height / 2.0) - 1, 3, 1, f[3])
			match style:
				"spots":
					_rect(img, 7, 6, 2, 2, f[2])
					_rect(img, 10, 7, 1, 2, f[2])
				"dots":
					for p: Vector2i in [Vector2i(6, 7), Vector2i(8, 6), Vector2i(10, 7)]:
						_px(img, p.x, p.y, Color(0.35, 0.3, 0.32))
				"stripes":
					for x in range(5, 12, 2):
						_line(img, Vector2(x, 6), Vector2(x, 8), f[3])
				"whiskers":
					_line(img, Vector2(13, 9), Vector2(15, 11), INK)
					_line(img, Vector2(13, 8), Vector2(15, 7), INK)
				"snout":
					_rect(img, int(center.x + length / 2.0), int(center.y), 3, 1, f[1])
			_px(img, int(center.x + length / 2.0) - 2, int(center.y) - 1, INK)
		_outline(img, INK)
		_save(img, "fish_" + f[0])


# --- Crops ---

func _mound(img: Image) -> void:
	_ellipse(img, Vector2(8, 14.5), Vector2(5, 1.6), Color(0.62, 0.48, 0.34))


func _leaf(img: Image, base: Vector2, tip: Vector2, color: Color) -> void:
	_line(img, base, tip, color)
	_line(img, base + Vector2(1, 0), tip + Vector2(1, 0), color.darkened(0.15))


func _make_crops() -> void:
	var green := Color(0.45, 0.62, 0.32)
	var dark_green := Color(0.32, 0.46, 0.25)
	# Carrot
	var carrot := Color(0.88, 0.5, 0.2)
	for stage in 4:
		var img := _img(16, 16)
		_mound(img)
		var h := 3 + stage * 2
		for i in 2 + stage:
			_leaf(img, Vector2(7 + i % 2, 13), Vector2(4 + i * 2, 13 - h + (i % 2)), green if i % 2 else dark_green)
		if stage == 3:
			_rect(img, 6, 12, 4, 2, carrot)
		_outline(img, INK)
		_save(img, "crop_carrot_%d" % stage)
	var produce := _img(16, 16)
	_poly(produce, PackedVector2Array([Vector2(4, 12), Vector2(10, 4), Vector2(12, 6)]), carrot)
	_line(produce, Vector2(9, 6), Vector2(8, 8), carrot.darkened(0.25))
	_leaf(produce, Vector2(11, 5), Vector2(13, 2), green)
	_leaf(produce, Vector2(11, 5), Vector2(14, 5), dark_green)
	_icon_edges(produce)
	_save(produce, "carrot")
	_seed_bag(produce, "carrot_seeds")

	# Pumpkin
	var orange := Color(0.85, 0.5, 0.2)
	for stage in 4:
		var img := _img(16, 16)
		_mound(img)
		if stage == 0:
			_leaf(img, Vector2(8, 13), Vector2(6, 10), green)
			_leaf(img, Vector2(8, 13), Vector2(10, 10), dark_green)
		else:
			_ellipse(img, Vector2(5, 11), Vector2(3, 2), dark_green)
			_ellipse(img, Vector2(11, 11), Vector2(3, 2), green)
			if stage == 2:
				_ellipse(img, Vector2(8, 11), Vector2(2.5, 2), Color(0.55, 0.6, 0.3))
			if stage == 3:
				_ellipse(img, Vector2(8, 10), Vector2(5, 4), orange)
				_line(img, Vector2(8, 7), Vector2(8, 13), orange.darkened(0.25))
				_rect(img, 8, 5, 1, 2, Color(0.4, 0.3, 0.2))
		_outline(img, INK)
		_save(img, "crop_pumpkin_%d" % stage)
	produce = _img(16, 16)
	_ellipse(produce, Vector2(8, 9.5), Vector2(6, 4.5), orange)
	_line(produce, Vector2(6, 6), Vector2(6, 13), orange.darkened(0.2))
	_line(produce, Vector2(10, 6), Vector2(10, 13), orange.darkened(0.2))
	_rect(produce, 8, 3, 1, 3, Color(0.4, 0.3, 0.2))
	_icon_edges(produce)
	_save(produce, "pumpkin")
	_seed_bag(produce, "pumpkin_seeds")

	# Pale turnip
	var bulb := Color(0.88, 0.84, 0.86)
	var purple := Color(0.62, 0.42, 0.6)
	for stage in 4:
		var img := _img(16, 16)
		_mound(img)
		var h := 2 + stage * 2
		_leaf(img, Vector2(8, 13), Vector2(5, 13 - h), green)
		_leaf(img, Vector2(8, 13), Vector2(10, 13 - h - 1), dark_green)
		if stage >= 2:
			_leaf(img, Vector2(8, 13), Vector2(12, 13 - h + 1), green)
		if stage == 3:
			_ellipse(img, Vector2(8.5, 12.5), Vector2(3, 2), purple)
		_outline(img, INK)
		_save(img, "crop_turnip_%d" % stage)
	produce = _img(16, 16)
	_ellipse(produce, Vector2(8, 10), Vector2(4.5, 4), bulb)
	_ellipse(produce, Vector2(8, 8), Vector2(4, 2), purple)
	_line(produce, Vector2(8, 14), Vector2(8, 15), bulb.darkened(0.2))
	_leaf(produce, Vector2(7, 6), Vector2(5, 2), green)
	_leaf(produce, Vector2(8, 6), Vector2(11, 2), dark_green)
	_icon_edges(produce)
	_save(produce, "turnip")
	_seed_bag(produce, "turnip_seeds")

	# Flower seed packets: a dot of the flower's colour on a bag.
	var flowers := {"tulip_seeds": Color(0.92, 0.8, 0.3), "bluebell_seeds": Color(0.35, 0.45, 0.8),
		"rose_seeds": Color(0.85, 0.45, 0.55), "sunflower_seeds": Color(0.95, 0.75, 0.2)}
	for name: String in flowers:
		var dot := _img(16, 16)
		_ellipse(dot, Vector2(8, 8), Vector2(5, 5), flowers[name])
		_ellipse(dot, Vector2(8, 8), Vector2(2, 2), Color(0.5, 0.35, 0.2))
		_seed_bag(dot, name)


## A seed packet with a small picture of what it grows.
func _seed_bag(picture: Image, name: String) -> void:
	var bag := _region(_plants, 0, 16)
	var paper := bag.get_pixel(8, 4)
	for y in range(5, 13):
		for x in range(4, 12):
			if bag.get_pixel(x, y).a > 0.0:
				bag.set_pixel(x, y, paper)
	var small := picture.duplicate() as Image
	small.resize(8, 8, Image.INTERPOLATE_NEAREST)
	bag.blend_rect(small, Rect2i(0, 0, 8, 8), Vector2i(4, 5))
	_save(bag, name)


# --- Materials, food ---

func _make_items() -> void:
	var stone := _region(_materials, 0, 16)
	var ores := {"copper_ore": Color(0.85, 0.5, 0.28), "iron_ore": Color(0.62, 0.38, 0.32), "gold_ore": Color(0.97, 0.82, 0.32)}
	for name: String in ores:
		var img := stone.duplicate() as Image
		for p: Vector2i in [Vector2i(5, 8), Vector2i(6, 8), Vector2i(9, 7), Vector2i(10, 10), Vector2i(7, 11), Vector2i(11, 9)]:
			img.set_pixelv(p, ores[name])
		_save(img, name)

	var crystal := _img(16, 16)
	var ice := Color(0.65, 0.85, 0.95)
	_poly(crystal, PackedVector2Array([Vector2(5, 14), Vector2(4, 6), Vector2(6, 3), Vector2(8, 6), Vector2(8, 14)]), ice)
	_poly(crystal, PackedVector2Array([Vector2(8, 14), Vector2(9, 7), Vector2(11, 5), Vector2(12, 8), Vector2(12, 14)]), ice.darkened(0.15))
	_line(crystal, Vector2(5, 7), Vector2(5, 12), Color.WHITE)
	_icon_edges(crystal)
	_save(crystal, "frost_crystal")

	var heart := _img(16, 16)
	var red := Color(0.62, 0.1, 0.14)
	_poly(heart, PackedVector2Array([Vector2(8, 3), Vector2(13, 8), Vector2(8, 14), Vector2(3, 8)]), red)
	_poly(heart, PackedVector2Array([Vector2(8, 5), Vector2(10, 8), Vector2(8, 11), Vector2(6, 8)]), Color(0.85, 0.25, 0.3))
	_px(heart, 7, 6, Color(1, 0.7, 0.7))
	_icon_edges(heart)
	_save(heart, "heartstone")

	var bone := _img(16, 16)
	var bone_color := Color(0.9, 0.87, 0.78)
	_line(bone, Vector2(4, 11), Vector2(11, 4), bone_color)
	_line(bone, Vector2(5, 11), Vector2(11, 5), bone_color)
	for p: Vector2 in [Vector2(3.5, 11), Vector2(4.5, 12.5), Vector2(11.5, 3.5), Vector2(12.5, 4.5)]:
		_ellipse(bone, p, Vector2(1.5, 1.5), bone_color)
	_icon_edges(bone)
	_save(bone, "bone")

	var bread := _img(16, 16)
	_ellipse(bread, Vector2(8, 9), Vector2(6, 4), Color(0.72, 0.5, 0.28))
	_ellipse(bread, Vector2(8, 8), Vector2(5, 2.5), Color(0.82, 0.62, 0.36))
	for x in [5, 8, 11]:
		_line(bread, Vector2(x, 7), Vector2(x - 1, 9), Color(0.6, 0.4, 0.22))
	_icon_edges(bread)
	_save(bread, "bread")

	var flask := _img(16, 16)
	_ellipse(flask, Vector2(8, 10), Vector2(4.5, 4.5), Color(0.55, 0.4, 0.28))
	_ellipse(flask, Vector2(8, 10), Vector2(3, 3), Color(0.35, 0.55, 0.75))
	_rect(flask, 7, 3, 3, 3, Color(0.55, 0.4, 0.28))
	_rect(flask, 7, 2, 3, 1, Color(0.35, 0.25, 0.2))
	_px(flask, 7, 9, Color(0.75, 0.88, 0.95))
	_icon_edges(flask)
	_save(flask, "water_flask")

	var stew := _img(16, 16)
	_ellipse(stew, Vector2(8, 9), Vector2(6, 3), Color(0.45, 0.42, 0.45))
	_ellipse(stew, Vector2(8, 8), Vector2(5, 1.5), Color(0.72, 0.42, 0.25))
	_rect(stew, 4, 9, 9, 3, Color(0.45, 0.42, 0.45))
	_px(stew, 6, 8, Color(0.9, 0.6, 0.3))
	_px(stew, 10, 8, Color(0.5, 0.7, 0.35))
	_icon_edges(stew)
	_save(stew, "stew")

	var bouquet := _img(16, 16)
	_line(bouquet, Vector2(8, 14), Vector2(8, 8), Color(0.35, 0.5, 0.28))
	_line(bouquet, Vector2(8, 14), Vector2(5, 8), Color(0.35, 0.5, 0.28))
	_line(bouquet, Vector2(8, 14), Vector2(11, 8), Color(0.35, 0.5, 0.28))
	for p: Array in [[Vector2(5, 6), Color(0.85, 0.45, 0.55)], [Vector2(8, 5), Color(0.92, 0.8, 0.3)], [Vector2(11, 6), Color(0.4, 0.5, 0.85)]]:
		_ellipse(bouquet, p[0], Vector2(2, 2), p[1])
	_rect(bouquet, 6, 11, 5, 2, Color(0.8, 0.75, 0.6))
	_icon_edges(bouquet)
	_save(bouquet, "bouquet")


# --- Tools ---

func _make_tools() -> void:
	var axe := _region(_materials, 16, 0)
	# The bought sheet's third tool is the hoe, so the pickaxe is drawn here.
	var pickaxe := _img(16, 16)
	_line(pickaxe, Vector2(3, 13), Vector2(10, 6), Color(0.55, 0.36, 0.24))
	_line(pickaxe, Vector2(4, 13), Vector2(11, 6), Color(0.45, 0.28, 0.2))
	var metal := Color(0.6, 0.62, 0.6)
	for p: Vector2i in [Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 4), Vector2i(9, 4), Vector2i(10, 5),
			Vector2i(11, 5), Vector2i(11, 6), Vector2i(12, 7), Vector2i(12, 8), Vector2i(13, 9), Vector2i(13, 10)]:
		_px(pickaxe, p.x, p.y, metal)
		_px(pickaxe, p.x, p.y + 1, metal.darkened(0.25))
	_icon_edges(pickaxe)
	_save(pickaxe, "pickaxe")
	var tiers := {"copper": Color(0.85, 0.52, 0.3), "iron": Color(0.78, 0.8, 0.86), "gold": Color(0.97, 0.8, 0.35)}
	for tier: String in tiers:
		_save(_tint_metal(axe, tiers[tier]), tier + "_axe")
		_save(_tint_metal(pickaxe, tiers[tier]), tier + "_pickaxe")
	var swords := {"rusty_sword": Color(0.58, 0.45, 0.38), "copper_sword": Color(0.85, 0.52, 0.3),
		"iron_sword": Color(0.8, 0.82, 0.88), "gold_sword": Color(0.97, 0.8, 0.35)}
	for name: String in swords:
		var img := _img(16, 16)
		var blade: Color = swords[name]
		for i in 8:
			_px(img, 5 + i, 10 - i, blade)
			_px(img, 6 + i, 10 - i, blade.darkened(0.2))
		_px(img, 13, 2, blade.lightened(0.3))
		_line(img, Vector2(3, 9), Vector2(6, 12), Color(0.45, 0.35, 0.25))
		_line(img, Vector2(4, 12), Vector2(2, 14), Color(0.4, 0.26, 0.2))
		_line(img, Vector2(3, 12), Vector2(1, 14), Color(0.4, 0.26, 0.2))
		_icon_edges(img)
		_save(img, name)


# --- Mine ---

const BIOMES := [
	# floor, wall, ore colour
	[Color(0.33, 0.28, 0.25), Color(0.19, 0.15, 0.14), Color(0.85, 0.5, 0.28)],
	[Color(0.25, 0.3, 0.22), Color(0.12, 0.17, 0.11), Color(0.62, 0.38, 0.32)],
	[Color(0.42, 0.38, 0.32), Color(0.24, 0.21, 0.17), Color(0.97, 0.82, 0.32)],
	[Color(0.26, 0.32, 0.4), Color(0.11, 0.16, 0.24), Color(0.65, 0.88, 0.97)],
	[Color(0.3, 0.13, 0.13), Color(0.15, 0.05, 0.06), Color(0.9, 0.2, 0.25)],
]


func _make_mine() -> void:
	# Columns are the five floors. Rows: floor, floor variant, wall.
	var tiles := _img(16 * 5, 16 * 3)
	for b in BIOMES.size():
		var floor_color: Color = BIOMES[b][0]
		var wall_color: Color = BIOMES[b][1]
		for row in 2:
			_rect(tiles, b * 16, row * 16, 16, 16, floor_color)
			_noise(tiles, Rect2i(b * 16, row * 16, 16, 16), 0.03)
			for i in 3 + row * 3:
				var p := Vector2i(b * 16 + randi_range(1, 14), row * 16 + randi_range(1, 14))
				tiles.set_pixelv(p, floor_color.darkened(0.3))
				if row == 1 and b == 2:
					tiles.set_pixelv(p + Vector2i(1, 0), Color(0.78, 0.74, 0.66))
				if row == 1 and b == 1:
					tiles.set_pixelv(p + Vector2i(0, 1), Color(0.35, 0.45, 0.25))
		_rect(tiles, b * 16, 32, 16, 16, wall_color)
		_noise(tiles, Rect2i(b * 16, 32, 16, 16), 0.025)
		_rect(tiles, b * 16, 32, 16, 3, wall_color.lightened(0.18))
		_line(tiles, Vector2(b * 16 + 4, 38), Vector2(b * 16 + 7, 43), wall_color.darkened(0.4))
		_line(tiles, Vector2(b * 16 + 11, 36), Vector2(b * 16 + 10, 41), wall_color.darkened(0.4))
		if b == 3:
			_line(tiles, Vector2(b * 16 + 2, 33), Vector2(b * 16 + 6, 33), Color(0.7, 0.85, 0.95))
		if b == 4:
			_line(tiles, Vector2(b * 16 + 3, 44), Vector2(b * 16 + 12, 39), Color(0.5, 0.08, 0.1))
	_save(tiles, "mine_tiles")

	# Rocks: row 0 plain, row 1 with ore.
	var rocks := _img(16 * 5, 32)
	for b in BIOMES.size():
		for row in 2:
			var img := _img(16, 16)
			var color: Color = (BIOMES[b][0] as Color).lightened(0.25)
			_ellipse(img, Vector2(8, 10), Vector2(6, 4.5), color)
			_ellipse(img, Vector2(7, 8.5), Vector2(4, 2.5), color.lightened(0.15))
			_noise(img, Rect2i(0, 0, 16, 16), 0.03)
			if row == 1:
				for p: Vector2i in [Vector2i(5, 9), Vector2i(9, 8), Vector2i(10, 11), Vector2i(6, 12), Vector2i(12, 10)]:
					img.set_pixelv(p, BIOMES[b][2])
			_outline(img, INK)
			rocks.blit_rect(img, Rect2i(0, 0, 16, 16), Vector2i(b * 16, row * 16))
	_save(rocks, "mine_rocks")

	var down := _img(16, 16)
	_ellipse(down, Vector2(8, 8), Vector2(6, 5), Color(0.03, 0.02, 0.03))
	for y in range(5, 13, 2):
		_line(down, Vector2(5, y), Vector2(10, y), Color(0.5, 0.36, 0.24))
	_line(down, Vector2(5, 3), Vector2(5, 13), Color(0.45, 0.3, 0.2))
	_line(down, Vector2(10, 3), Vector2(10, 13), Color(0.45, 0.3, 0.2))
	_outline(down, INK)
	_save(down, "ladder_down")

	var up := _img(16, 16)
	_line(up, Vector2(4, 0), Vector2(4, 15), Color(0.55, 0.4, 0.26))
	_line(up, Vector2(11, 0), Vector2(11, 15), Color(0.55, 0.4, 0.26))
	for y in range(2, 16, 3):
		_line(up, Vector2(5, y), Vector2(10, y), Color(0.62, 0.46, 0.3))
	_outline(up, INK)
	_save(up, "ladder_up")

	var sconce := _img(8, 8)
	_rect(sconce, 3, 4, 2, 4, Color(0.4, 0.3, 0.2))
	_ellipse(sconce, Vector2(4, 3), Vector2(2, 2.5), Color(1.0, 0.75, 0.35))
	_px(sconce, 4, 3, Color(1, 0.95, 0.7))
	_save(sconce, "torch")


# --- Enemies (mine only) ---

func _frames(frame_images: Array[Image], name: String) -> void:
	var w := frame_images[0].get_width()
	var h := frame_images[0].get_height()
	var sheet := _img(w * frame_images.size(), h)
	for i in frame_images.size():
		sheet.blit_rect(frame_images[i], Rect2i(0, 0, w, h), Vector2i(i * w, 0))
	_save(sheet, name)


func _make_enemies() -> void:
	# Pale crawler: a grub with too many legs.
	var crawler: Array[Image] = []
	for f in 2:
		var img := _img(16, 16)
		var flesh := Color(0.86, 0.8, 0.78)
		for s in 4:
			var x := 3.0 + s * 3.0
			var y := 10.0 + (sin(s + f * 1.5) * 0.8)
			for leg in [-1, 1]:
				_px(img, int(x) + leg * (f if s % 2 else 1 - f), 13, INK)
			_ellipse(img, Vector2(x, y), Vector2(2.5, 2.5 - s * 0.2), flesh.darkened(s * 0.06))
		for p: Vector2i in [Vector2i(2, 9), Vector2i(3, 8), Vector2i(2, 10), Vector2i(4, 9)]:
			img.set_pixelv(p, Color(0.08, 0.04, 0.05))
		_outline(img, INK)
		crawler.append(img)
	_frames(crawler, "enemy_crawler")

	# Root eye: an eyeball growing out of roots.
	var eye: Array[Image] = []
	for f in 2:
		var img := _img(16, 16)
		for r in 4:
			_line(img, Vector2(8, 10), Vector2(2 + r * 4 + f, 15), Color(0.35, 0.28, 0.2))
		_ellipse(img, Vector2(8, 7), Vector2(5, 5), Color(0.9, 0.86, 0.82))
		_line(img, Vector2(4, 5), Vector2(6, 7), Color(0.7, 0.2, 0.2))
		_line(img, Vector2(12, 9), Vector2(10, 7), Color(0.7, 0.2, 0.2))
		_ellipse(img, Vector2(8 + f, 7), Vector2(2, 2), Color(0.25, 0.35, 0.2))
		_px(img, 8 + f, 7, Color(0.02, 0.02, 0.02))
		_outline(img, INK)
		eye.append(img)
	_frames(eye, "enemy_root_eye")

	# Rattler: a low thing made of bones.
	var rattler: Array[Image] = []
	for f in 2:
		var img := _img(16, 16)
		var bone := Color(0.88, 0.85, 0.76)
		_line(img, Vector2(3, 9), Vector2(11, 9), bone)
		for x in range(4, 11, 2):
			_line(img, Vector2(x, 8), Vector2(x, 11), bone)
		for leg: int in [4, 10]:
			_line(img, Vector2(leg, 11), Vector2(leg - 1 + f * 2, 14), bone)
		_ellipse(img, Vector2(12.5, 8), Vector2(2.5, 2), bone)
		_px(img, 13, 8, Color(0.6, 0.05, 0.05))
		_outline(img, INK)
		rattler.append(img)
	_frames(rattler, "enemy_rattler")

	# The still one: tall, thin, with a blank pale face.
	var still: Array[Image] = []
	for f in 2:
		var img := _img(16, 24)
		var black := Color(0.04, 0.04, 0.06)
		_rect(img, 6, 7, 4, 15, black)
		_line(img, Vector2(6, 9), Vector2(3, 18), black)
		_line(img, Vector2(9, 9), Vector2(12, 18), black)
		_ellipse(img, Vector2(8 + f * 0.5, 4), Vector2(2.5, 3.5), Color(0.86, 0.86, 0.88))
		_outline(img, Color(0.25, 0.28, 0.35))
		still.append(img)
	_frames(still, "enemy_still_one")

	# Mouthless: a red mass covered in eyes.
	var mouthless: Array[Image] = []
	for f in 2:
		var img := _img(24, 24)
		_ellipse(img, Vector2(12, 14), Vector2(9 + f, 8 - f * 0.5), Color(0.55, 0.12, 0.14))
		_ellipse(img, Vector2(12, 12), Vector2(6, 4), Color(0.65, 0.2, 0.2))
		for p: Vector2i in [Vector2i(8, 11), Vector2i(14, 10), Vector2i(11, 15), Vector2i(17, 14), Vector2i(6, 15)]:
			_ellipse(img, Vector2(p) + Vector2(0.5, 0.5), Vector2(1.5, 1.5 - f * 0.8), Color(0.95, 0.9, 0.7))
			_px(img, p.x, p.y, Color(0.05, 0.02, 0.02))
		_outline(img, INK)
		mouthless.append(img)
	_frames(mouthless, "enemy_mouthless")


# --- Props ---

func _make_props() -> void:
	var cave := _img(48, 32)
	var rock := Color(0.42, 0.4, 0.38)
	_ellipse(cave, Vector2(24, 20), Vector2(23, 13), rock)
	_ellipse(cave, Vector2(14, 14), Vector2(10, 9), rock.lightened(0.08))
	_ellipse(cave, Vector2(34, 15), Vector2(10, 8), rock.darkened(0.05))
	_noise(cave, Rect2i(0, 0, 48, 32), 0.04)
	_ellipse(cave, Vector2(24, 27), Vector2(9, 10), Color(0.02, 0.01, 0.02))
	_rect(cave, 13, 30, 22, 2, Color(0, 0, 0, 0))
	_line(cave, Vector2(15, 18), Vector2(15, 31), Color(0.38, 0.28, 0.2))
	_line(cave, Vector2(33, 18), Vector2(33, 31), Color(0.38, 0.28, 0.2))
	_line(cave, Vector2(14, 18), Vector2(34, 18), Color(0.45, 0.33, 0.22))
	_outline(cave, INK)
	_save(cave, "cave_entrance")

	var board := _img(32, 32)
	var wood := Color(0.45, 0.32, 0.22)
	_rect(board, 5, 12, 2, 18, wood.darkened(0.2))
	_rect(board, 25, 12, 2, 18, wood.darkened(0.2))
	_rect(board, 3, 6, 26, 15, wood)
	_noise(board, Rect2i(3, 6, 26, 15), 0.03)
	_rect(board, 3, 5, 26, 1, wood.lightened(0.2))
	for n: Rect2i in [Rect2i(6, 8, 6, 7), Rect2i(14, 9, 5, 6), Rect2i(21, 8, 5, 8)]:
		_rect(board, n.position.x, n.position.y, n.size.x, n.size.y, Color(0.85, 0.82, 0.72))
		_line(board, Vector2(n.position.x + 1, n.position.y + 2), Vector2(n.end.x - 2, n.position.y + 2), Color(0.45, 0.42, 0.4))
		_px(board, n.position.x + n.size.x / 2, n.position.y, Color(0.6, 0.15, 0.15))
	_outline(board, INK)
	_save(board, "quest_board")

	var well := _img(32, 32)
	var stone := Color(0.5, 0.48, 0.46)
	_rect(well, 7, 4, 2, 18, wood)
	_rect(well, 23, 4, 2, 18, wood)
	_poly(well, PackedVector2Array([Vector2(3, 6), Vector2(16, 0), Vector2(29, 6), Vector2(27, 8), Vector2(5, 8)]), Color(0.42, 0.25, 0.2))
	_ellipse(well, Vector2(16, 23), Vector2(11, 6), stone)
	_noise(well, Rect2i(0, 16, 32, 16), 0.04)
	_ellipse(well, Vector2(16, 21), Vector2(8, 3), Color(0.06, 0.08, 0.1))
	_line(well, Vector2(16, 8), Vector2(16, 19), Color(0.6, 0.55, 0.45))
	_outline(well, INK)
	_save(well, "well")

	var sign := _img(16, 16)
	_rect(sign, 7, 7, 2, 8, wood.darkened(0.2))
	_rect(sign, 2, 3, 12, 5, wood)
	_line(sign, Vector2(4, 5), Vector2(11, 5), wood.darkened(0.35))
	_outline(sign, INK)
	_save(sign, "signpost")

	var rubble := _img(16, 16)
	_ellipse(rubble, Vector2(6, 11), Vector2(4, 3), stone)
	_ellipse(rubble, Vector2(11, 12), Vector2(3, 2), stone.darkened(0.1))
	_line(rubble, Vector2(3, 7), Vector2(13, 10), wood)
	_line(rubble, Vector2(4, 13), Vector2(12, 6), wood.darkened(0.15))
	_outline(rubble, INK)
	_save(rubble, "rubble")

	var scaffold := _img(32, 32)
	for x: int in [3, 15, 27]:
		_rect(scaffold, x, 4, 2, 27, wood.lightened(0.1))
	for y: int in [8, 18, 28]:
		_rect(scaffold, 2, y, 28, 2, wood)
	_line(scaffold, Vector2(4, 9), Vector2(16, 19), wood.darkened(0.2))
	_outline(scaffold, INK)
	_save(scaffold, "scaffold")

	var path := _img(64, 16)
	for v in 4:
		_rect(path, v * 16, 0, 16, 16, Color(0.52, 0.43, 0.32))
		_noise(path, Rect2i(v * 16, 0, 16, 16), 0.035)
		for i in 4 + v:
			path.set_pixel(v * 16 + randi_range(0, 15), randi_range(0, 15), Color(0.4, 0.33, 0.25))
		if v == 3:
			_ellipse(path, Vector2(v * 16 + 9, 8), Vector2(2, 1.5), Color(0.6, 0.58, 0.55))
	_save(path, "path")

	var anvil := _img(16, 16)
	_poly(anvil, PackedVector2Array([Vector2(2, 5), Vector2(14, 5), Vector2(12, 8), Vector2(5, 8)]), Color(0.35, 0.36, 0.4))
	_rect(anvil, 6, 8, 4, 4, Color(0.3, 0.3, 0.34))
	_rect(anvil, 4, 12, 8, 2, Color(0.35, 0.36, 0.4))
	_icon_edges(anvil)
	_save(anvil, "anvil")


# --- HUD icons ---

func _make_icons() -> void:
	var heart := _img(9, 8)
	_ellipse(heart, Vector2(2.5, 2.5), Vector2(2.5, 2.5), Color(0.78, 0.2, 0.22))
	_ellipse(heart, Vector2(6.5, 2.5), Vector2(2.5, 2.5), Color(0.78, 0.2, 0.22))
	_poly(heart, PackedVector2Array([Vector2(0, 3), Vector2(9, 3), Vector2(4.5, 8)]), Color(0.78, 0.2, 0.22))
	_px(heart, 2, 1, Color(1, 0.7, 0.7))
	_save(heart, "icon_health")

	var food := _img(8, 8)
	_ellipse(food, Vector2(4, 4.5), Vector2(3.5, 2.5), Color(0.82, 0.6, 0.32))
	_ellipse(food, Vector2(4, 3.5), Vector2(3, 1.5), Color(0.9, 0.72, 0.42))
	_save(food, "icon_food")

	var drop := _img(8, 8)
	_ellipse(drop, Vector2(4, 5), Vector2(2.6, 2.6), Color(0.4, 0.62, 0.88))
	_poly(drop, PackedVector2Array([Vector2(4, 0), Vector2(6.5, 4.5), Vector2(1.5, 4.5)]), Color(0.4, 0.62, 0.88))
	_px(drop, 3, 4, Color(0.8, 0.9, 1))
	_save(drop, "icon_water")


# --- Sounds ---

func _wav(samples: PackedFloat32Array, name: String, loop := false) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size()
	stream.save_to_wav(ProjectSettings.globalize_path(OUT + name + ".wav"))


func _sound(seconds: float, sample: Callable) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var count := int(seconds * MIX_RATE)
	out.resize(count)
	var state := {"low": 0.0}
	for i in count:
		out[i] = sample.call(float(i) / MIX_RATE, float(i) / count, state)
	return out


func _make_sounds() -> void:
	_wav(_sound(0.18, func(t: float, p: float, s: Dictionary) -> float:
		s.low = lerpf(s.low, randf_range(-1, 1), 0.25)
		return (s.low * 1.4 + sin(t * TAU * 90.0) * 0.6) * pow(1.0 - p, 3.0)), "chop")
	_wav(_sound(0.25, func(t: float, p: float, _s: Dictionary) -> float:
		return (sin(t * TAU * 1760.0) * 0.5 + sin(t * TAU * 2630.0) * 0.3 + randf_range(-0.3, 0.3) * (1.0 - p)) * pow(1.0 - p, 4.0)), "pick")
	_wav(_sound(0.16, func(_t: float, p: float, s: Dictionary) -> float:
		s.low = lerpf(s.low, randf_range(-1, 1), 0.08 + p * 0.3)
		return s.low * sin(p * PI) * 1.2), "swing")
	_wav(_sound(0.22, func(t: float, p: float, s: Dictionary) -> float:
		s.low = lerpf(s.low, randf_range(-1, 1), 0.15)
		return (s.low + sin(t * TAU * lerpf(160.0, 60.0, p))) * 0.7 * pow(1.0 - p, 2.0)), "enemy_hit")
	_wav(_sound(0.3, func(t: float, p: float, s: Dictionary) -> float:
		s.low = lerpf(s.low, randf_range(-1, 1), 0.1)
		return (sin(t * TAU * lerpf(110.0, 50.0, p)) * 0.8 + s.low * 0.5) * pow(1.0 - p, 1.5)), "hurt")
	_wav(_sound(0.9, func(t: float, p: float, s: Dictionary) -> float:
		s.low = lerpf(s.low, randf_range(-1, 1), 0.04)
		return (s.low * 1.5 * (0.6 + 0.4 * sin(t * TAU * 7.0)) + sin(t * TAU * 55.0) * 0.3) * sin(p * PI) * 0.8), "growl")
	_wav(_sound(0.35, func(_t: float, p: float, s: Dictionary) -> float:
		s.low = lerpf(s.low, randf_range(-1, 1), 0.5)
		var crunch := 1.0 if fmod(p * 4.0, 1.0) < 0.35 else 0.0
		return s.low * crunch * 0.5 * (1.0 - p * 0.5)), "eat")
	_wav(_sound(0.45, func(t: float, p: float, _s: Dictionary) -> float:
		var gulp := fmod(p * 3.0, 1.0)
		return sin(t * TAU * lerpf(300.0, 520.0, gulp)) * 0.4 * sin(gulp * PI) * (1.0 - p * 0.4)), "drink")
	_wav(_sound(0.05, func(t: float, p: float, _s: Dictionary) -> float:
		return sin(t * TAU * 880.0) * 0.25 * (1.0 - p)), "ui_move")
	_wav(_sound(0.1, func(t: float, p: float, _s: Dictionary) -> float:
		return (sin(t * TAU * 660.0) + sin(t * TAU * 990.0) * 0.5) * 0.2 * (1.0 - p)), "ui_select")
	_wav(_sound(6.0, func(t: float, _p: float, s: Dictionary) -> float:
		s.low = lerpf(s.low, randf_range(-1, 1), 0.01)
		var drip := sin(t * TAU * 1200.0) * exp(-fmod(t, 2.3) * 40.0) * 0.15 if t > 1.0 else 0.0
		return s.low * 0.9 + sin(t * TAU * 41.0) * 0.12 + drip), "mine_drone", true)
