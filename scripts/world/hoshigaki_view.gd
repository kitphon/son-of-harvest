class_name HoshigakiView
extends Node2D
## The drying persimmon strings (hoshigaki) in the flat view (rules: HoshigakiRules,
## data/hoshigaki.json; pictures: HoshigakiArt, the `small` ones; the 3D view's is HoshigakiLayer).
## They hang from the row under a painted roof's bottom eave (the farmhouse: FarmView.roof_rect;
## the village houses HoshigakiRules.village_hangs picks: their roof picture, the prop's box less a
## pixel all round, as MapView draws it), clear of the doors on the roof's front row, at whole
## pixels, shifted a pixel sideways by the wind's swing. They take the world's light like the
## story props (FlatLight). Shown only while HoshigakiRules.hangs_now.

const T := 16

var map: MapData
var farm: FarmGrid
var _spots: Array[Dictionary] = []
var _t := 0.0


func setup(m: MapData, f: FarmGrid = null) -> HoshigakiView:
	map = m
	farm = f
	name = "Hoshigaki"
	_spots = spots_for(m, f)
	refresh()
	return self


func _ready() -> void:
	add_to_group(FlatLight.GROUP)


## Where the strings hang on map `m` (the farmhouse when `f` is the farm's grid).
static func spots_for(m: MapData, f: FarmGrid = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not HoshigakiRules.outdoors(m):
		return out
	var cfg := HoshigakiRules.config()
	if m.farm:
		if f == null:
			return out
		var r := FarmView.roof_rect(f, "house")
		if not r.has_area():
			return out
		var bare: Array = []
		var row := int(r.end.y) / T - 1
		for x in range(int(r.position.x) / T, int(r.end.x) / T):
			if f.fixed_at(Vector2i(x, row)) != "house":   # the door drawn on the roof's front row
				bare.append(Vector2i(x * T, x * T + T))
		return HoshigakiRules.flat_spots(int(r.position.x), int(r.end.x), int(r.end.y), bare, cfg)
	for p in m.props:
		if str(p.kind) != "village_house" or not HoshigakiRules.village_hangs(Vector2i(p.cell)):
			continue
		var inner := Rect2(Vector2(p.cell * T), Vector2(p.size * T)).grow(-1)
		var front := int(p.cell.y) + int(p.size.y) - 1
		var bare: Array = []
		for door in m.doors:
			for c: Vector2i in door.cells:
				if c.y == front and c.x >= int(p.cell.x) and c.x < int(p.cell.x) + int(p.size.x):
					bare.append(Vector2i(c.x * T, c.x * T + T))
		out.append_array(HoshigakiRules.flat_spots(int(inner.position.x), int(inner.end.x), int(inner.end.y), bare, cfg))
	return out


func _process(delta: float) -> void:
	_t += delta
	refresh()


func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	visible = not _spots.is_empty() and HoshigakiRules.hangs_now(game, map)
	if visible:
		queue_redraw()


## The strings showing now: [{key: the picture, pos: its top-left pixel}].
func shown() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if not visible or game == null:
		return out
	var cfg := HoshigakiRules.config()
	var st := HoshigakiRules.stage(HoshigakiRules.days_now(game, cfg), cfg)
	var wind: float = game.wind_strength()
	var rx := HoshigakiArt.rope_x(true)
	for s in _spots:
		var shift := HoshigakiRules.flat_shift(wind, _t, float(s.phase), cfg)
		out.append({"key": HoshigakiRules.art_key(int(s.fruit), st, true),
			"pos": Vector2(int(s.x) - rx + shift, int(s.y)), "spot": s})
	return out


func _draw() -> void:
	for it in shown():
		var tex := PlaceholderArt.tex(it.key)
		var pos: Vector2 = it.pos
		var feet := Vector2(pos.x + tex.get_width() / 2.0, pos.y + tex.get_height() - 1)
		draw_texture(tex, pos, FlatLight.at(feet, tex.get_height(), FlatLight.field_px()))
