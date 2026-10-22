extends SceneTree
## Draws the placeholder art and sounds in assets/Generated/ (fish, crops, ores,
## tools, mine tiles, enemies, props, UI icons, sound effects). Run from the project folder:
##   godot --headless --path . -s tools/generate_assets.gd
## then re-import. The music loop takes a little while. Replace any of the files with real art when it exists.

const OUT := "res://assets/Generated/"
const INK := Color(0.17, 0.12, 0.17)
const HALO := Color(0.96, 0.93, 0.84)
const MIX_RATE := 22050
# Weathered fence wood, lightest (sawn tops) to the outline.
const FENCE_TOP := Color(0.76, 0.68, 0.54)
const FENCE_LIGHT := Color(0.65, 0.54, 0.4)
const FENCE_MID := Color(0.55, 0.44, 0.32)
const FENCE_DARK := Color(0.43, 0.33, 0.26)
const FENCE_EDGE := Color(0.32, 0.24, 0.19)
const GRASS_BLADE := Color("78a158")

var _plants: Image
var _materials: Image
## For paths, fences and grass edges, so they don't shift the other assets' random looks.
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	seed(1234)
	_rng.seed = 1234
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
	_make_player_looks()
	_make_nature()
	_make_human()
	_make_houses()
	_make_music()
	_make_ranch()
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


# --- Player looks (ART-1) ---

## Original colour -> new colour for each look. The outline colour is also used for
## the eyes; with "glow_eyes" the eyes get their own colour.
const LOOKS := {
	"updated": {"F3F2C0": "F6EBC8", "5C4E92": "3B2F4F", "DDD5DE": "E2C29C", "766DAA": "8C3B3B",
		"E8B5AC": "F09A9A", "F3D8C5": "F7D5B5", "EAE178": "F2C14E"},
	"halloween": {"F3F2C0": "E8892E", "5C4E92": "2E1A33", "DDD5DE": "3A2A40", "766DAA": "7A3FA0",
		"E8B5AC": "C2410C", "F3D8C5": "F0A050", "EAE178": "9BE564"},
	"black": {"F3F2C0": "34303D", "5C4E92": "120F17", "DDD5DE": "4A4458", "766DAA": "8C1F2E",
		"E8B5AC": "6B4E5E", "F3D8C5": "4A4458", "EAE178": "EAE178", "glow_eyes": "EAE178"},
}


func _make_player_looks() -> void:
	var sheets := {"sheet": "Basic Charakter Spritesheet.png", "actions": "Basic Charakter Actions.png"}
	for kind: String in sheets:
		var src := Image.load_from_file(ProjectSettings.globalize_path("res://assets/Characters/" + sheets[kind]))
		src.convert(Image.FORMAT_RGBA8)
		for look: String in LOOKS:
			var palette: Dictionary = LOOKS[look]
			var img := src.duplicate() as Image
			for y in img.get_height():
				for x in img.get_width():
					var c := src.get_pixel(x, y)
					if c.a == 0.0:
						continue
					var key := c.to_html(false).to_upper()
					if not palette.has(key):
						continue
					var color := Color(palette[key])
					if key == "5C4E92" and palette.has("glow_eyes") and _is_inside(src, x, y):
						color = Color(palette.glow_eyes)
					img.set_pixel(x, y, Color(color, c.a))
			_save(img, "player_%s_%s" % [look, kind])


## True if (x, y) sits inside the face (an eye) rather than on the outline: drawn
## above and below, with fur (not outline) on both sides.
func _is_inside(img: Image, x: int, y: int) -> bool:
	for o: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var p := Vector2i(x, y) + o
		if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
			return false
		var c := img.get_pixelv(p)
		if c.a == 0.0 or (o.y == 0 and c.to_html(false).to_upper() == "5C4E92"):
			return false
	return true


# --- Nature (ART-3) ---

## Colours of assets/Objects/dead_tree.png, which sets the style for all nature:
## flat two-tone wood, hanging moss, dark grass at the roots, no outlines.
const WOOD := Color("7d5022")
const WOOD_DARK := Color("532e26")
const MOSS := Color("839e5c")
const MOSS_LIGHT := Color("b6dc7f")
const ROOT_GRASS := Color("065c00")


## Makes nature.png, the atlas the map uses: "Basic Grass Biom things 1.png" redrawn in
## the dead tree's style. Same tile positions, plus the picked apple tree (0,5, 2x2)
## and the big dead tree (2,5, 3x3).
func _make_nature() -> void:
	var src := Image.load_from_file(ProjectSettings.globalize_path("res://assets/Objects/Basic Grass Biom things 1.png"))
	src.convert(Image.FORMAT_RGBA8)
	var img := _img(src.get_width(), src.get_height() + 48)
	img.blit_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i.ZERO)
	# Small and medium dead trees; the trunk base sits in the cell below the tile's own.
	_clear(img, Rect2i(0, 0, 16, 32))
	_style_tree(img, Vector2(8, 29), 18, [[0.45, Vector2(-6, -6)], [0.7, Vector2(6, -7)], [1.0, Vector2(-3, -6)], [1.0, Vector2(3, -8)]], 2)
	_clear(img, Rect2i(16, 0, 32, 32))
	_style_tree(img, Vector2(32, 30), 22, [[0.35, Vector2(-13, -5)], [0.5, Vector2(13, -8)], [0.7, Vector2(-9, -9)],
		[0.85, Vector2(8, -9)], [1.0, Vector2(-3, -7)], [1.0, Vector2(4, -9)]], 3)
	# The apple tree stays alive, with the same wood and grass.
	_restyle_trunk(img, Rect2i(48, 0, 32, 32))
	_grass_tufts(img, Vector2(64, 29), 4)
	# Bushes become twigs (the berry bush keeps its berries).
	_clear(img, Rect2i(0, 48, 32, 16))
	_style_bush(img, Vector2(8, 62), true)
	_style_bush(img, Vector2(24, 62), false)
	# Stumps and the log, rocks, weeds: the same flat colours.
	for r: Rect2i in [Rect2i(48, 32, 16, 16), Rect2i(64, 32, 16, 16), Rect2i(80, 32, 16, 16)]:
		_recolor(img, r, [Color("a0703a"), WOOD, WOOD_DARK], 0.0)
	for r: Rect2i in [Rect2i(112, 16, 16, 16), Rect2i(128, 16, 16, 16), Rect2i(80, 64, 16, 16), Rect2i(96, 64, 16, 16)]:
		_recolor(img, r, [Color("9a978c"), Color("77746a"), Color("4f4c46")], 0.3)
	for r: Rect2i in [Rect2i(80, 16, 16, 16), Rect2i(96, 16, 16, 16)]:
		_recolor(img, r, [MOSS_LIGHT, MOSS, ROOT_GRASS], 0.0)
	# The apple tree with its apples picked off.
	var picked := img.get_region(Rect2i(48, 0, 32, 32))
	for y in 32:
		for x in 32:
			var c := picked.get_pixel(x, y)
			if c.a > 0.0 and _is_berry(c):
				picked.set_pixel(x, y, _leaf_near(picked, x, y))
	img.blit_rect(picked, Rect2i(0, 0, 32, 32), Vector2i(0, 80))
	# The big dead tree, trunk centred on the tile.
	var tree := Image.load_from_file(ProjectSettings.globalize_path("res://assets/Objects/dead_tree.png"))
	tree.convert(Image.FORMAT_RGBA8)
	img.blend_rect(tree, Rect2i(Vector2i.ZERO, tree.get_size()), Vector2i(32, 80 + 48 - tree.get_height()))
	_save(img, "nature")


func _clear(img: Image, rect: Rect2i) -> void:
	img.fill_rect(rect, Color(0, 0, 0, 0))


func _is_leaf(c: Color) -> bool:
	return c.a > 0.0 and c.h > 0.18 and c.h < 0.5 and c.s > 0.12


func _is_berry(c: Color) -> bool:
	return c.a > 0.0 and (c.h < 0.04 or c.h > 0.9) and c.s > 0.35


## The colour of the nearest leaf pixel on the same row, to paint over a picked apple.
func _leaf_near(img: Image, x: int, y: int) -> Color:
	for d in range(1, 8):
		for xx: int in [x - d, x + d]:
			if xx >= 0 and xx < img.get_width() and _is_leaf(img.get_pixel(xx, y)):
				return img.get_pixel(xx, y)
	return Color(0.45, 0.62, 0.42)


## A line of wood `width` pixels thick, lit on the left/top and dark on the right/bottom.
func _branch(img: Image, from: Vector2, to: Vector2, width: int) -> void:
	var steps := int(maxf(absf(to.x - from.x), absf(to.y - from.y))) + 1
	var upright := absf(to.y - from.y) >= absf(to.x - from.x)
	for i in steps + 1:
		var p := from.lerp(to, float(i) / steps).round()
		for w in width:
			var color := FENCE_DARK if w == width - 1 and width > 1 else WOOD
			if width == 1:
				color = WOOD if i % 3 != 2 else FENCE_DARK
			if upright:
				_px(img, int(p.x) + w - width / 2, int(p.y), color)
			else:
				_px(img, int(p.x), int(p.y) + w - width / 2, color)


## Moss hanging from a point: a dark tip and a lighter strand below.
func _moss(img: Image, at: Vector2i, length: int) -> void:
	for i in length:
		_px(img, at.x, at.y + i, MOSS if i == 0 or i % 3 == 1 else MOSS_LIGHT)


func _grass_tufts(img: Image, base: Vector2, count: int) -> void:
	for i in count:
		var x := int(base.x) + randi_range(-5, 5)
		var h := randi_range(1, 3)
		for j in h:
			_px(img, x, int(base.y) - j + 1, ROOT_GRASS)


## A dead tree: a tapering trunk from base up `height` pixels, and branches
## [share of the height they leave the trunk at, offset to their tip], with moss.
func _style_tree(img: Image, base: Vector2, height: int, branches: Array, trunk_width: int) -> void:
	var top := base + Vector2(randf_range(-1, 1), -height)
	_branch(img, base, base.lerp(top, 0.5), trunk_width)
	_branch(img, base.lerp(top, 0.5), top, maxi(trunk_width - 1, 1))
	_branch(img, base + Vector2(-1, 0), base + Vector2(-3, 1), 1)
	_branch(img, base + Vector2(1, 0), base + Vector2(3, 1), 1)
	for b: Array in branches:
		var start := base.lerp(top, b[0])
		var tip: Vector2 = start + b[1]
		var bend := start.lerp(tip, 0.5) + Vector2(0, randf_range(-1.5, 0.5))
		_branch(img, start, bend, 2 if b[1].length() > 6.0 else 1)
		_branch(img, bend, tip, 1)
		_branch(img, tip, tip + Vector2(signf(b[1].x), -2), 1)
		if randf() < 0.7:
			_moss(img, Vector2i(bend.round()) + Vector2i(0, 1), randi_range(2, 5))
	_grass_tufts(img, base, 5)


func _style_bush(img: Image, base: Vector2, berries: bool) -> void:
	var tips := [Vector2(-6, -7), Vector2(5, -8), Vector2(-2, -11), Vector2(2, -6), Vector2(-5, -3), Vector2(6, -3)]
	for tip: Vector2 in tips:
		_branch(img, base, base + tip, 1)
		if berries and randf() < 0.8:
			_px(img, int(base.x + tip.x), int(base.y + tip.y) + 1, Color("b8323a"))
			_px(img, int(base.x + tip.x) + 1, int(base.y + tip.y) + 1, Color("7a1f2a"))
	_moss(img, Vector2i(base + Vector2(-3, -5)), 3)
	_grass_tufts(img, base + Vector2(0, 1), 3)


## Brown trunk pixels become the style's two wood colours.
func _restyle_trunk(img: Image, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and c.h > 0.03 and c.h < 0.16 and c.s > 0.3:
				img.set_pixel(x, y, WOOD if c.v > 0.55 else FENCE_DARK)


## Flattens a sprite to three colours (light, mid, dark) by brightness, drops the pale
## halo, and with moss > 0 puts moss on some top edges.
func _recolor(img: Image, rect: Rect2i, colors: Array, moss: float) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			if c.s < 0.15 and c.v > 0.85:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var l := c.get_luminance()
			img.set_pixel(x, y, colors[0] if l > 0.6 else (colors[1] if l > 0.35 else colors[2]))
	if moss <= 0.0:
		return
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			if img.get_pixel(x, y).a > 0.0:
				if randf() < moss:
					img.set_pixel(x, y, MOSS if randf() < 0.5 else MOSS_LIGHT)
				break


# --- Human look (ART-1) ---

## Drawn over the cat's frames: same feet position, and the cat's tools and paws
## (as hands) are kept on top so every action still lines up.
const HUMAN_COLORS := {"o": "2b2232", "h": "5a3a2a", "H": "7a5238", "s": "f1c7a0", "S": "d9a47e",
	"e": "2b2232", "w": "e8dcc0", "b": "4c6a8c", "B": "3a5270", "k": "4a3426"}
const HUMAN_FRONT: Array[String] = ["...oooooo...", "..ohhhhhho..", ".ohhHHhhhho.", ".ohhhhhhhho.",
	".ohssssssho.", ".osesssseso.", ".ossssssSso.", "..osssssso..", "..oowbbwoo..", ".oswbbbbwso.",
	".oswbbbbwso.", ".osobbbboso.", "..oobbbboo..", "...obbBbo..."]
const HUMAN_BACK: Array[String] = ["...oooooo...", "..ohhhhhho..", ".ohhHHhhhho.", ".ohhhhhhhho.",
	".ohhhhhhhho.", ".ohhhhhhhho.", ".ohhhhhhHho.", "..ohhhhhho..", "..oowbbwoo..", ".oswbbbbwso.",
	".oswbbbbwso.", ".osobbbboso.", "..oobbbboo..", "...obbBbo..."]
const HUMAN_SIDE: Array[String] = ["...ooooo....", "..ohhhhho...", ".ohhhHhhho..", ".ohhhhhhso..",
	".ohhhsssso..", ".ohhsssseo..", ".ohhsssssso.", "..ohsssSso..", "...owwbwo...", "...owsbbo...",
	"...owsbbo...", "...oosbbo...", "...obbbbo...", "....obbo...."]
const HUMAN_LEGS := {
	"stand": ["...obbobbo..", "...obbobbo..", "...okkokko..", "...ooooooo.."],
	"step_l": ["...obbobbo..", "...okkobbo..", "...ooookko..", "......oooo.."],
	"step_r": ["...obbobbo..", "...obbokko..", "...okkoooo..", "...oooo....."],
	"side": ["....obbo....", "....obbo....", "....okkko...", "....ooooo..."],
	"side_step": ["...obbbbo...", "..obo..obo..", "..oko..okko.", "..ooo..oooo."],
}
const CAT_COLORS: Array[String] = ["F3F2C0", "5C4E92", "DDD5DE", "766DAA", "E8B5AC", "F3D8C5", "EAE178"]


func _make_human() -> void:
	var sheets := {"sheet": "Basic Charakter Spritesheet.png", "actions": "Basic Charakter Actions.png"}
	for kind: String in sheets:
		var src := Image.load_from_file(ProjectSettings.globalize_path("res://assets/Characters/" + sheets[kind]))
		src.convert(Image.FORMAT_RGBA8)
		var out := _img(src.get_width(), src.get_height())
		for row in src.get_height() / 48:
			for col in src.get_width() / 48:
				var frame := src.get_region(Rect2i(col * 48, row * 48, 48, 48))
				var legs := "stand"
				if kind == "sheet" and col >= 2:
					legs = ("step_l" if col == 2 else "step_r")
				out.blit_rect(_human_frame(frame, ["front", "back", "left", "right"][row % 4], legs),
					Rect2i(0, 0, 48, 48), Vector2i(col * 48, row * 48))
		_save(out, "player_human_" + kind)


func _human_frame(cat: Image, facing: String, legs: String) -> Image:
	# Split the cat's pixels into connected blobs: the biggest is the body, the rest are paws.
	var blob := {}
	var blobs: Array = []
	for y in 48:
		for x in 48:
			if blob.has(Vector2i(x, y)) or not _is_cat(cat.get_pixel(x, y)):
				continue
			var cells: Array[Vector2i] = []
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			blob[Vector2i(x, y)] = blobs.size()
			while not queue.is_empty():
				var c: Vector2i = queue.pop_back()
				cells.append(c)
				for ox in range(-1, 2):
					for oy in range(-1, 2):
						var n := c + Vector2i(ox, oy)
						if n.x >= 0 and n.y >= 0 and n.x < 48 and n.y < 48 and not blob.has(n) and _is_cat(cat.get_pixelv(n)):
							blob[n] = blobs.size()
							queue.append(n)
			blobs.append(cells)
	var body: Array = []
	for cells: Array in blobs:
		if cells.size() > body.size():
			body = cells
	var out := _img(48, 48)
	if body.is_empty():
		return out
	var left := 48
	var right := 0
	var bottom := 0
	for c: Vector2i in body:
		left = mini(left, c.x)
		right = maxi(right, c.x)
		bottom = maxi(bottom, c.y)
	var side := facing == "left" or facing == "right"
	var top_rows: Array[String] = HUMAN_SIDE if side else (HUMAN_BACK if facing == "back" else HUMAN_FRONT)
	var leg_rows: Array = HUMAN_LEGS["side_step" if legs != "stand" else "side"] if side else HUMAN_LEGS[legs]
	var rows: Array[String] = []
	rows.append_array(top_rows)
	for r: String in leg_rows:
		rows.append(r)
	var x0 := (left + right + 1) / 2 - 6
	var y0 := bottom + 1 - rows.size()
	for y in rows.size():
		var line: String = rows[y]
		if facing == "left":
			line = line.reverse()
		for x in line.length():
			if line[x] != ".":
				_px(out, x0 + x, y0 + y, Color(HUMAN_COLORS[line[x]]))
	# The cat's tools on top, and its loose paws as hands.
	for y in 48:
		for x in 48:
			var c := cat.get_pixel(x, y)
			if c.a == 0.0:
				continue
			if not _is_cat(c):
				out.set_pixel(x, y, c)
			elif blobs[blob[Vector2i(x, y)]] != body:
				var key := c.to_html(false).to_upper()
				out.set_pixel(x, y, Color(HUMAN_COLORS["o"] if key == "5C4E92" else HUMAN_COLORS["s"]))
	return out


func _is_cat(c: Color) -> bool:
	return c.a > 0.0 and c.to_html(false).to_upper() in CAT_COLORS

# --- Houses (ART-2) ---

## The farmhouse and the village houses: 64x80, the bottom edge is the ground line.
## Window and door sit where house_exterior.tscn and village_building.gd board them up.
func _make_houses() -> void:
	_save(_house(Color(0.5, 0.29, 0.25)), "house_farm")
	_save(_house(Color(0.33, 0.36, 0.42)), "house_village")


func _house(roof: Color) -> Image:
	var img := _img(64, 80)
	var wood := Color(0.56, 0.41, 0.29)
	var stone := Color(0.5, 0.48, 0.46)
	# Chimney behind the roof.
	_rect(img, 44, 2, 8, 16, stone)
	_noise(img, Rect2i(44, 2, 8, 16), 0.05)
	_rect(img, 43, 1, 10, 2, stone.darkened(0.25))
	# Walls: vertical planks over a stone footing, in shadow under the eaves.
	_rect(img, 1, 46, 62, 34, wood)
	for x in range(1, 63):
		if x % 5 == 0:
			_rect(img, x, 46, 1, 31, wood.darkened(0.22))
	_noise(img, Rect2i(1, 46, 62, 31), 0.025)
	for knot: Vector2i in [Vector2i(8, 58), Vector2i(23, 52), Vector2i(54, 61), Vector2i(27, 70)]:
		_px(img, knot.x, knot.y, wood.darkened(0.35))
	_rect(img, 1, 46, 62, 3, wood.darkened(0.4))
	_rect(img, 0, 76, 64, 4, stone)
	for x in range(0, 64, 6):
		_rect(img, x, 76, 1, 4, stone.darkened(0.25))
	_noise(img, Rect2i(0, 76, 64, 4), 0.04)
	# Roof: rows of shingles, each row a little lighter toward the eaves.
	_poly(img, PackedVector2Array([Vector2(7, 6), Vector2(57, 6), Vector2(64, 47), Vector2(0, 47)]), roof)
	for row in range(0, 11):
		var y := 8 + row * 4
		var shade := roof.lightened(row * 0.012)
		for x in 64:
			if img.get_pixel(x, y).a > 0.0 and img.get_pixel(x, y - 1).a > 0.0:
				_px(img, x, y, shade.darkened(0.3))
				if (x + row * 3) % 7 == 0:
					_px(img, x, y + 1, shade.darkened(0.3))
					_px(img, x, y + 2, shade.darkened(0.2))
	_noise(img, Rect2i(0, 6, 64, 41), 0.03)
	_rect(img, 7, 5, 50, 2, roof.darkened(0.35))
	_rect(img, 0, 46, 64, 2, roof.darkened(0.45))
	# Window with a frame and sill.
	_rect(img, 2, 66, 13, 10, wood.darkened(0.45))
	_rect(img, 3, 67, 11, 8, Color(0.15, 0.17, 0.23))
	_rect(img, 8, 67, 1, 8, wood.darkened(0.45))
	_rect(img, 3, 70, 11, 1, wood.darkened(0.45))
	_px(img, 4, 68, Color(0.45, 0.5, 0.58))
	_px(img, 5, 68, Color(0.35, 0.4, 0.48))
	_rect(img, 1, 76, 15, 1, wood.lightened(0.1))
	# Door with a frame, planks and a handle.
	_rect(img, 32, 63, 17, 13, wood.darkened(0.5))
	_rect(img, 33, 64, 15, 12, Color(0.42, 0.28, 0.2))
	for x: int in [37, 41, 45]:
		_rect(img, x, 64, 1, 12, Color(0.34, 0.22, 0.16))
	_px(img, 45, 70, Color(0.85, 0.7, 0.35))
	_rect(img, 33, 66, 15, 1, Color(0.34, 0.22, 0.16))
	_outline(img, INK)
	return img


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

	var plain := _img(64, 16)
	for v in 4:
		_rect(plain, v * 16, 0, 16, 16, Color(0.52, 0.43, 0.32))
		_noise(plain, Rect2i(v * 16, 0, 16, 16), 0.035)
		for i in 4 + v:
			plain.set_pixel(v * 16 + randi_range(0, 15), randi_range(0, 15), Color(0.4, 0.33, 0.25))
		if v == 3:
			_ellipse(plain, Vector2(v * 16 + 9, 8), Vector2(2, 1.5), Color(0.6, 0.58, 0.55))
	# Column = which sides join more path (1 up, 2 right, 4 down, 8 left), row = variant.
	var path := _img(256, 64)
	var tuft := Color("a4c263")
	for v in 4:
		for sides in 16:
			var insets := [_ragged_edge(), _ragged_edge(), _ragged_edge(), _ragged_edge()]
			for y in 16:
				for x in 16:
					var depth := _path_depth(x, y, sides, insets)
					if depth < 0.0:
						continue
					var color := plain.get_pixel(v * 16 + x, y)
					if depth < 1.0:
						color = color.darkened(0.16)
						# Grass creeping over the worn edge.
						if _rng.randf() < 0.22:
							color = tuft
					elif depth < 2.0:
						color = color.darkened(0.07)
					path.set_pixel(sides * 16 + x, v * 16 + y, color)
	_save(path, "path")

	var anvil := _img(16, 16)
	_poly(anvil, PackedVector2Array([Vector2(2, 5), Vector2(14, 5), Vector2(12, 8), Vector2(5, 8)]), Color(0.35, 0.36, 0.4))
	_rect(anvil, 6, 8, 4, 4, Color(0.3, 0.3, 0.34))
	_rect(anvil, 4, 12, 8, 2, Color(0.35, 0.36, 0.4))
	_icon_edges(anvil)
	_save(anvil, "anvil")


## How far each pixel along a tile side the path edge wanders in, 0-2 px. It is 1 at
## both ends so the edge lines up with the next tile.
func _ragged_edge() -> Array[float]:
	var insets: Array[float] = []
	var inset := 1.0
	for i in 16:
		inset = clampf(inset + _rng.randf_range(-0.7, 0.7), 0.0, 2.0)
		insets.append(1.0 if i == 0 or i == 15 else inset)
	return insets


## For a pixel of a path tile: how far it is inside the path, negative when cut away.
## Sides that don't join more path get a worn, ragged edge; corners between two of them are rounded.
func _path_depth(x: int, y: int, sides: int, insets: Array) -> float:
	const RADIUS := 6.0
	var open_up := sides & 1 == 0
	var open_right := sides & 2 == 0
	var open_down := sides & 4 == 0
	var open_left := sides & 8 == 0
	var corner := Vector2(-1, -1)
	if x < RADIUS and y < RADIUS and open_left and open_up:
		corner = Vector2(RADIUS, RADIUS)
	elif x >= 16 - RADIUS and y < RADIUS and open_right and open_up:
		corner = Vector2(16 - RADIUS, RADIUS)
	elif x >= 16 - RADIUS and y >= 16 - RADIUS and open_right and open_down:
		corner = Vector2(16 - RADIUS, 16 - RADIUS)
	elif x < RADIUS and y >= 16 - RADIUS and open_left and open_down:
		corner = Vector2(RADIUS, 16 - RADIUS)
	if corner.x >= 0.0:
		return RADIUS - Vector2(x + 0.5, y + 0.5).distance_to(corner) - _rng.randf_range(0.0, 1.2)
	var depth := 99.0
	if open_up:
		depth = minf(depth, y - insets[0][x])
	if open_down:
		depth = minf(depth, 15 - y - insets[1][x])
	if open_left:
		depth = minf(depth, x - insets[2][y])
	if open_right:
		depth = minf(depth, 15 - x - insets[3][y])
	return depth


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
	_wav(_sound(1.6, func(_t: float, p: float, s: Dictionary) -> float:
		s.low = lerpf(s.low, randf_range(-1, 1), 0.45)
		var syllables := pow(sin(p * PI * 5.0), 2.0)
		return s.low * syllables * sin(p * PI) * 0.35), "whisper")


## A slow, slightly out-of-tune music box over a low hum (ATM-6). Loops seamlessly.
func _make_music() -> void:
	const LENGTH := 32.0
	# Seconds and frequencies: A minor with a flat second that never quite resolves.
	var notes := [
		[0.0, 659.26], [1.5, 523.25], [3.0, 440.0], [6.0, 466.16],
		[8.0, 659.26], [9.5, 587.33], [11.0, 440.0], [14.0, 349.23],
		[16.0, 659.26], [17.5, 523.25], [19.0, 440.0], [20.5, 622.25],
		[24.0, 587.33], [25.5, 466.16], [27.0, 440.0], [29.0, 392.0],
	]
	for note: Array in notes:
		note[1] *= randf_range(0.992, 0.998)
	var count := int(LENGTH * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	for i in count:
		var t := float(i) / MIX_RATE
		var wow := 1.0 + 0.004 * sin(TAU * t * 4.0 / LENGTH)
		var bell := 0.0
		for note: Array in notes:
			var dt: float = t - note[0]
			if dt < 0.0:
				dt += LENGTH  # The tail of a note from the end of the loop.
			if dt > 6.0:
				continue
			var f: float = note[1] * wow
			var env := exp(-dt * 1.1) * minf(dt * 200.0, 1.0)
			bell += (sin(TAU * f * dt) + 0.3 * sin(TAU * f * 2.0 * dt) + 0.15 * sin(TAU * f * 3.01 * dt) * exp(-dt * 3.0)) * env
		var swell := 0.5 + 0.5 * sin(TAU * t / 16.0)
		var hum := (sin(TAU * 110.0 * t) + 0.6 * sin(TAU * 165.0 * t)) * 0.5 \
			+ sin(TAU * 116.5625 * t) * 0.35 * (0.5 - 0.5 * cos(TAU * t / LENGTH))
		out[i] = bell * 0.16 + hum * 0.08 * (0.6 + 0.4 * swell)
	_wav(out, "music", true)

# --- Fences and grass edges: weathered wood, ragged grass ---

## Same layout as Fences.png. Column: 0 no rails, 1 rails right, 2 both sides, 3 left.
## Row: 0 joins down, 1 up and down, 2 up, 3 alone.
func _make_fences() -> void:
	var img := _img(64, 64)
	for ty in 4:
		for tx in 4:
			var o := Vector2i(tx * 16, ty * 16)
			if tx == 1 or tx == 2:
				_fence_rails(img, o.x + 10, o.y)
			if tx == 2 or tx == 3:
				_fence_rails(img, o.x, o.y)
			if ty < 2:
				_rect(img, o.x + 7, o.y + 11, 2, 5, FENCE_MID)
				_rect(img, o.x + 7, o.y + 11, 1, 5, FENCE_LIGHT)
			if ty == 1 or ty == 2:
				_rect(img, o.x + 7, o.y, 2, 2, FENCE_MID)
				_rect(img, o.x + 7, o.y, 1, 2, FENCE_LIGHT)
			# A rough post, a little shorter or taller, with a split top and a knot.
			var top := 1 + _rng.randi_range(0, 1)
			_rect(img, o.x + 6, o.y + top, 4, 11 - top, FENCE_MID)
			_rect(img, o.x + 6, o.y + top, 1, 11 - top, FENCE_LIGHT)
			_rect(img, o.x + 9, o.y + top, 1, 11 - top, FENCE_DARK)
			_rect(img, o.x + 6, o.y + top, 4, 2, FENCE_TOP)
			_px(img, o.x + 7 + _rng.randi_range(0, 1), o.y + top, FENCE_DARK)
			_px(img, o.x + 7 + _rng.randi_range(0, 1), o.y + top + 4 + _rng.randi_range(0, 3), FENCE_DARK)
	_wood_grain(img)
	_outline(img, FENCE_EDGE)
	for ty in 4:
		for tx in 4:
			var o := Vector2i(tx * 16, ty * 16)
			# Moss low on the post, a shadow and grass at its foot.
			for i in 3:
				_px(img, o.x + 6 + _rng.randi_range(0, 3), o.y + 8 + _rng.randi_range(0, 2), MOSS)
			for x in range(6, 10):
				if img.get_pixel(o.x + x, o.y + 12).a == 0.0:
					img.set_pixel(o.x + x, o.y + 12, Color(0, 0, 0, 0.22))
			_px(img, o.x + 5, o.y + 11, GRASS_BLADE)
			_px(img, o.x + 5, o.y + 10, GRASS_BLADE)
			_px(img, o.x + 10, o.y + 11, GRASS_BLADE)
	_save(img, "fences")


func _fence_rails(img: Image, x: int, y: int) -> void:
	for rail_y: int in [4, 8]:
		_rect(img, x, y + rail_y, 6, 2, FENCE_MID)
		_rect(img, x, y + rail_y, 6, 1, FENCE_LIGHT)


## Grain streaks and blotches so the wood doesn't look painted.
func _wood_grain(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var n := _rng.randf_range(-0.03, 0.03)
			if _rng.randf() < 0.1:
				n -= 0.07
			img.set_pixel(x, y, Color(c.r + n, c.g + n, c.b + n * 0.8, c.a))


## Grass.png with softer edge bands, a ragged rim and blades poking out over the
## ground or water. Only edges inside a tile change, so the tiles still join up.
func _make_grass() -> void:
	var src := Image.load_from_file(ProjectSettings.globalize_path("res://assets/Tilesets/Grass.png"))
	src.convert(Image.FORMAT_RGBA8)
	var img := src.duplicate() as Image
	var rim := Color("78a158")
	var band := Color("a4c263")
	var fill := Color("c0d470")
	var w := src.get_width()
	var h := src.get_height()
	var at := func(x: int, y: int, from: Vector2i) -> Color:
		# Outside the tile counts as more grass: the neighbouring tile carries on.
		if x < 0 or y < 0 or x >= w or y >= h or x / 16 != from.x / 16 or y / 16 != from.y / 16:
			return fill
		return src.get_pixel(x, y)
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			var p := Vector2i(x, y)
			if c == band:
				for o: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					if at.call(x + o.x, y + o.y, p) == fill and _rng.randf() < 0.3:
						img.set_pixel(x, y, fill)
			elif c == rim:
				var outer := false
				for o: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n: Color = at.call(x + o.x, y + o.y, p)
					if n.a == 0.0:
						outer = true
						var q := p + o
						# A blade or two of grass sticking out.
						if _rng.randf() < 0.2:
							img.set_pixelv(q, rim)
							var q2 := q + o
							if _rng.randf() < 0.5 and at.call(q2.x, q2.y, p).a == 0.0 and q2.x / 16 == x / 16 and q2.y / 16 == y / 16:
								img.set_pixelv(q2, rim)
				if not outer:
					img.set_pixel(x, y, band if _rng.randf() < 0.7 else rim)
				elif _rng.randf() < 0.1:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
	_save(img, "grass")


# --- Ranch: gates, the new animals and what they give (ANM-5..ANM-8) ---

func _make_ranch() -> void:
	# Gates, 2x2 tiles: closed and open, across (top row) and up-down (bottom row).
	var gate := _img(32, 32)
	var light := FENCE_TOP
	var mid := FENCE_MID
	var dark := FENCE_DARK
	for x: int in [0, 14, 16, 30]:
		_rect(gate, x, 2, 2, 10, dark)
		_rect(gate, x, 2, 2, 1, light)
	_rect(gate, 2, 4, 12, 2, mid)
	_rect(gate, 2, 8, 12, 2, mid)
	_line(gate, Vector2(2, 9), Vector2(13, 5), dark)
	_rect(gate, 2, 4, 12, 1, FENCE_LIGHT)
	_rect(gate, 2, 8, 12, 1, FENCE_LIGHT)
	# Open: swung towards you, seen edge-on.
	_rect(gate, 18, 5, 3, 9, mid)
	_rect(gate, 18, 5, 3, 1, light)
	_line(gate, Vector2(19, 6), Vector2(19, 13), dark)
	for y: int in [16, 30]:
		_rect(gate, 5, y, 6, 2, dark)
		_rect(gate, 21, y, 6, 2, dark)
		_rect(gate, 5, y, 6, 1, light)
	_rect(gate, 6, 18, 4, 12, mid)
	_line(gate, Vector2(6, 19), Vector2(9, 28), dark)
	_rect(gate, 6, 18, 1, 12, FENCE_LIGHT)
	_rect(gate, 23, 18, 8, 3, mid)
	_rect(gate, 23, 18, 8, 1, FENCE_LIGHT)
	_wood_grain(gate)
	_outline(gate, FENCE_EDGE)
	_save(gate, "gate")
	_make_fences()
	_make_grass()

	# Animals: idle, idle, walk, walk, facing right, feet on the bottom row.
	var duck: Array[Image] = []
	for f in 4:
		var img := _img(16, 16)
		var bob := 1 if f == 1 else 0
		var white := Color(0.88, 0.87, 0.82)
		_ellipse(img, Vector2(7, 11), Vector2(5, 3.5), white)
		_ellipse(img, Vector2(11, 6 + bob), Vector2(2.5, 2.5), white)
		_rect(img, 10, 7 + bob, 2, 3, white)
		_line(img, Vector2(4, 11), Vector2(8, 12), Color(0.7, 0.68, 0.64))
		_rect(img, 13, 6 + bob, 2, 1, Color(0.85, 0.5, 0.2))
		_px(img, 11, 5 + bob, INK)
		var step := 1 if f == 3 else 0
		_px(img, 6 - step, 15, Color(0.85, 0.5, 0.2))
		_px(img, 8 + step, 15, Color(0.85, 0.5, 0.2))
		_outline(img, INK)
		duck.append(img)
	_frames(duck, "animal_duck")

	var sheep: Array[Image] = []
	for f in 4:
		var img := _img(24, 20)
		var bob := 1 if f == 1 else 0
		var legs := Color(0.2, 0.18, 0.2)
		var step := 1 if f == 3 else 0
		for x: int in [6, 9, 14, 17]:
			var lift := step if (x == 6 or x == 14) else 0
			_rect(img, x + (step if x in [9, 17] else 0), 14, 2, 5 - lift, legs)
		var wool := Color(0.84, 0.82, 0.78)
		_ellipse(img, Vector2(11, 11), Vector2(8, 5), wool)
		for c: Vector2 in [Vector2(6, 8), Vector2(11, 6.5), Vector2(15, 8), Vector2(5, 12)]:
			_ellipse(img, c, Vector2(3, 3), wool)
		_noise(img, Rect2i(0, 0, 24, 20), 0.04)
		_ellipse(img, Vector2(19, 9 + bob), Vector2(3, 3), Color(0.24, 0.21, 0.23))
		_px(img, 17, 6 + bob, Color(0.24, 0.21, 0.23))
		# A pale eye, slightly too big.
		_px(img, 20, 8 + bob, Color(0.86, 0.8, 0.5))
		_outline(img, INK)
		sheep.append(img)
	_frames(sheep, "animal_sheep")

	var goat: Array[Image] = []
	for f in 4:
		var img := _img(24, 20)
		var bob := 1 if f == 1 else 0
		var coat := Color(0.55, 0.5, 0.45)
		var step := 1 if f == 3 else 0
		for x: int in [6, 9, 13, 16]:
			_rect(img, x + (step if x in [9, 16] else 0), 13, 1, 6 - (step if x in [6, 13] else 0), coat.darkened(0.3))
		_ellipse(img, Vector2(11, 11), Vector2(7, 3.5), coat)
		_noise(img, Rect2i(0, 0, 24, 20), 0.03)
		_rect(img, 16, 6 + bob, 2, 5, coat)
		_ellipse(img, Vector2(19, 6 + bob), Vector2(3, 2.2), coat.lightened(0.05))
		_line(img, Vector2(18, 4 + bob), Vector2(15, 1 + bob), Color(0.3, 0.27, 0.25))
		_px(img, 21, 8 + bob, coat.darkened(0.4))
		_px(img, 21, 9 + bob, coat.darkened(0.4))
		_px(img, 4, 9, coat.darkened(0.2))
		# Goat eyes: a flat dark bar on yellow.
		_px(img, 19, 5 + bob, Color(0.85, 0.72, 0.3))
		_px(img, 20, 5 + bob, Color(0.1, 0.08, 0.08))
		_outline(img, INK)
		goat.append(img)
	_frames(goat, "animal_goat")

	# What they give.
	var wool_icon := _img(16, 16)
	for c: Vector2 in [Vector2(6, 9), Vector2(10, 9), Vector2(8, 6), Vector2(8, 11)]:
		_ellipse(wool_icon, c, Vector2(3.5, 3), Color(0.88, 0.86, 0.8))
	_noise(wool_icon, Rect2i(0, 0, 16, 16), 0.05)
	_icon_edges(wool_icon)
	_save(wool_icon, "wool")

	var duck_egg := _img(16, 16)
	_ellipse(duck_egg, Vector2(8, 9), Vector2(4, 5), Color(0.74, 0.85, 0.8))
	for p: Vector2i in [Vector2i(6, 7), Vector2i(9, 10), Vector2i(7, 12), Vector2i(10, 6)]:
		_px(duck_egg, p.x, p.y, Color(0.5, 0.58, 0.55))
	_px(duck_egg, 6, 6, Color(0.9, 0.96, 0.92))
	_icon_edges(duck_egg)
	_save(duck_egg, "duck_egg")

	var goat_milk := _img(16, 16)
	_rect(goat_milk, 5, 6, 6, 8, Color(0.9, 0.88, 0.82))
	_rect(goat_milk, 6, 3, 4, 3, Color(0.9, 0.88, 0.82))
	_rect(goat_milk, 6, 2, 4, 1, Color(0.45, 0.32, 0.22))
	_rect(goat_milk, 5, 9, 6, 3, Color(0.55, 0.5, 0.45))
	_px(goat_milk, 7, 10, Color(0.85, 0.72, 0.3))
	_icon_edges(goat_milk)
	_save(goat_milk, "goat_milk")

	# Crated animals, as sold in the feed store: the animal peeking over a crate.
	var crates := {
		"chicken": ["res://assets/Characters/Free Chicken Sprites.png", Rect2i(0, 0, 16, 16)],
		"cow": ["res://assets/Characters/Free Cow Sprites.png", Rect2i(0, 0, 32, 32)],
		"duck": ["res://assets/Generated/animal_duck.png", Rect2i(0, 0, 16, 16)],
		"sheep": ["res://assets/Generated/animal_sheep.png", Rect2i(0, 0, 24, 20)],
		"goat": ["res://assets/Generated/animal_goat.png", Rect2i(0, 0, 24, 20)],
	}
	for name: String in crates:
		var sheet := Image.load_from_file(ProjectSettings.globalize_path(crates[name][0]))
		sheet.convert(Image.FORMAT_RGBA8)
		var frame := sheet.get_region(crates[name][1])
		frame = frame.get_region(frame.get_used_rect())
		var fit := minf(14.0 / frame.get_width(), 11.0 / frame.get_height())
		if fit < 1.0:
			frame.resize(maxi(1, roundi(frame.get_width() * fit)), maxi(1, roundi(frame.get_height() * fit)), Image.INTERPOLATE_NEAREST)
		var icon := _img(16, 16)
		icon.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i((16 - frame.get_width()) / 2, 11 - frame.get_height()))
		_rect(icon, 1, 10, 14, 5, mid)
		_rect(icon, 1, 10, 14, 1, light)
		_line(icon, Vector2(1, 14), Vector2(14, 11), dark)
		_rect(icon, 1, 10, 1, 5, dark)
		_rect(icon, 14, 10, 1, 5, dark)
		_icon_edges(icon)
		_save(icon, "crate_" + name)
