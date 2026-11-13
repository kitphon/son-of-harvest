class_name HoshigakiLayer
extends Node3D
## The drying persimmon strings (hoshigaki) in 3D (rules: HoshigakiRules, data/hoshigaki.json;
## pictures: HoshigakiArt). They hang from the real front eave lines the roof builders listed
## (FarmWorld.eaves, Minka.note_eave): the farmhouse's on the farm, the front eave of the village
## houses HoshigakiRules.village_hangs picks elsewhere, tucked a little under the soffit and clear
## of the doors. Each string is a pivot at its top with one camera-facing sprite under it
## (FarmWorld.make_sprite, lit like the other sprites), swung about z by HoshigakiRules.sway_angle
## with the world's wind. The picture follows the days hung (fresh orange to shrunken red-brown).
## A string fades with its own house while the house turns see-through in front of the farmer
## (Occluders.fade_of_tag of the house's tag). Shown only while HoshigakiRules.hangs_now; made
## with an outdoor world (MapWorld, Main3D.new_world for the farm), none in rooms or the mine.

var map: MapData
var _strings: Array[Dictionary] = []   # {pivot, sprite, spot, tag}
var _stage := -1
var _t := 0.0


## The strings of map `m` along `eaves` (FarmWorld.eaves); `f` the farm's grid on the farm.
func _init(m: MapData, eaves: Array[Dictionary], f: FarmGrid = null) -> void:
	map = m
	name = "Hoshigaki"
	if not HoshigakiRules.outdoors(m):
		return
	var cfg := HoshigakiRules.config()
	for host in hosts_for(m, f):
		var e := eave_of(host, eaves)
		if e.is_empty():
			continue
		for s in HoshigakiRules.spots(e.a, e.b, e.out, host.bare, cfg):
			_strings.append({"spot": s, "tag": host.tag})


## The houses that hang strings on map `m`: [{tag: its Occluders tag, x0, x1: its walls' span,
## front: its front edge (z), bare: [Vector2(x0, x1)] its doors on the front row}]. The farm (with
## its grid `f`): the farmhouse; elsewhere the village houses HoshigakiRules.village_hangs picks.
static func hosts_for(m: MapData, f: FarmGrid = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not HoshigakiRules.outdoors(m):
		return out
	if m.farm:
		if f == null:
			return out
		var r := FarmView.roof_rect(f, "house")
		if not r.has_area():
			return out
		var T := 16
		var row := int(r.end.y) / T - 1
		var bare: Array = []
		for x in range(int(r.position.x) / T, int(r.end.x) / T):
			if f.fixed_at(Vector2i(x, row)) != "house":
				bare.append(Vector2(x, x + 1))
		out.append({"tag": FarmWorld.FARM_HOUSE, "x0": r.position.x / T, "x1": r.end.x / T, "front": r.end.y / T, "bare": bare})
		return out
	for p in m.props:
		if str(p.kind) != "village_house" or not HoshigakiRules.village_hangs(Vector2i(p.cell)):
			continue
		var front := int(p.cell.y) + int(p.size.y)
		var bare: Array = []
		for door in m.doors:
			for c: Vector2i in door.cells:
				if c.y == front - 1 and c.x >= int(p.cell.x) and c.x < int(p.cell.x) + int(p.size.x):
					bare.append(Vector2(c.x, c.x + 1))
		out.append({"tag": MapWorld.house_tag(p), "x0": float(p.cell.x), "x1": float(p.cell.x + p.size.x), "front": float(front), "bare": bare})
	return out


## The listed eave that is `host`'s front one: facing out to +z, near its front edge, spanning its
## walls; the lowest such (a two-storey house's pent roof, under the upper roof). {} when none.
static func eave_of(host: Dictionary, eaves: Array[Dictionary]) -> Dictionary:
	var best := {}
	for e in eaves:
		var a: Vector3 = e.a
		var b: Vector3 = e.b
		if (e.out as Vector3).dot(Vector3(0, 0, 1)) < 0.9 or absf(a.z - float(host.front)) > 0.7:
			continue
		if minf(a.x, b.x) > float(host.x0) + 0.3 or maxf(a.x, b.x) < float(host.x1) - 0.3:
			continue
		if best.is_empty() or a.y < (best.a as Vector3).y - 0.01:
			best = e
	return best


func _ready() -> void:
	var px := float(HoshigakiRules.config().pixel_size)
	for s in _strings:
		var pivot := Node3D.new()
		pivot.position = s.spot.at
		add_child(pivot)
		var tex := PlaceholderArt.tex(HoshigakiRules.art_key(int(s.spot.fruit), 0, false))
		var sp := FarmWorld.make_sprite(tex)
		sp.pixel_size = px
		sp.offset = Vector2.ZERO
		pivot.add_child(sp)
		s.pivot = pivot
		s.sprite = sp
	refresh()


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the date, the weather and the wind: shows or takes in the strings, sets their picture by
## the days hung, swings them, and fades each with its house.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	visible = not _strings.is_empty() and HoshigakiRules.hangs_now(game, map)
	if not visible or not is_inside_tree():
		return
	var cfg := HoshigakiRules.config()
	var st := HoshigakiRules.stage(HoshigakiRules.days_now(game, cfg), cfg)
	var fw := get_parent() as FarmWorld
	var wind: float = fw.wind if fw != null else 0.0
	for s in _strings:
		var sp: Sprite3D = s.get("sprite")
		if sp == null:
			continue
		if st != _stage:
			sp.texture = PlaceholderArt.tex(HoshigakiRules.art_key(int(s.spot.fruit), st, false))
			sp.position = Vector3(0, -sp.texture.get_height() * sp.pixel_size / 2.0, 0)   # hangs from the pivot by its top
		(s.pivot as Node3D).rotation.z = HoshigakiRules.sway_angle(wind, _t, float(s.spot.phase), cfg)
		var fade := fw.occluders.fade_of_tag(str(s.tag)) if fw != null else 0.0
		if fade > 0.0:
			sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
			sp.transparent = true
		else:
			sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sp.modulate.a = 1.0 - fade
	_stage = st


## How many strings this layer hangs (for tests).
func string_count() -> int:
	return _strings.size()


## Every string's spot (for tests): {at, fruit, phase}.
func spot_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in _strings:
		out.append(s.spot)
	return out


## String `i`'s sprite and pivot (for tests): [Sprite3D, Node3D].
func string_nodes(i: int) -> Array:
	return [_strings[i].get("sprite"), _strings[i].get("pivot")]


## The picture stage showing now (for tests).
func shown_stage() -> int:
	return _stage
