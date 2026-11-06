class_name FestivalProps
extends FarmWorld
## Today's festival decorations on one map in 3D (data/festivals.json → props): cherry trees
## and picnic mats, lantern strings and stalls, the moon offering, New Year bamboo, a mochi mortar, the fishing race's flag and a
## bonfire, the contest's judges' table. Built with the map's world when a festival falls on today and is held here, shown
## only during its hours. Lights (lanterns, the fire) are listed in `glows` for FestivalGlow,
## which draws their glow over the night tint. Lit meshes (FestivalMeshes).

const GROUP := "festival_props"
const LANTERN_RED := Color("d8402c")
const LANTERN_PAPER := Color("f0e6c8")
const FLAME := Color("ffb040")

var map_id := ""
var festival := ""
var glows: Array[Dictionary] = []   # {pos: Vector3, color: Color, size: cells across, pool: "round" / "line" / "stall"}
var wares := 0                      # item pictures on the selling stalls' counters


func _init(map: String) -> void:
	map_id = map


func _ready() -> void:
	add_to_group(GROUP)
	festival = Game.festival_today()
	if Festivals.get_festival(festival).get("map", "") == map_id:
		for p in Festivals.get_festival(festival).get("props", []):
			_make(p)
	else:
		festival = ""
	Game.minute_passed.connect(refresh)
	refresh()


## Shown only while the festival is on (its hours, on this map).
func refresh() -> void:
	visible = festival != "" and Festivals.on_now(festival, map_id, Game.hour * 60 + Game.minute)


## Are decorations standing now (for tests and FestivalGlow)?
func shown() -> bool:
	return visible and get_child_count() > 0


func _make(p: Dictionary) -> void:
	var size: Array = p.get("size", [1, 1])
	var r := Rect2(Vector2(p.cell[0], p.cell[1]), Vector2(size[0], size[1]))
	var mid := Vector3(r.get_center().x, 0, r.get_center().y)
	var cloth := Color(str(p.get("cloth", "c8442c")))
	match str(p.kind):
		"sakura": _sakura(mid)
		"picnic_mat": FestivalMeshes.mat(self, mid, r, Color("3a6ab0"))
		"red_mat": FestivalMeshes.mat(self, mid, r, Color("b02a24"))
		"stall":
			FestivalMeshes.stall(self, mid, r, cloth)
			_glow(mid + Vector3((r.size.x - 0.2) / 2, 1.2, 0.36), LANTERN_RED.lerp(Color("ffd890"), 0.5), 1.4, "stall", mid, r.size.x - 0.2)
			_wares(mid, r, Festivals.stall_of_prop(festival, p))
		"judge_table": FestivalMeshes.judge_table(self, mid, r)
		"lantern_line":
			FestivalMeshes.lantern_line(self, r)
			for i in int(r.size.x):
				var paper := LANTERN_RED if i % 2 == 0 else LANTERN_PAPER
				_glow(Vector3(r.position.x + i + 0.5, 1.62, r.get_center().y), paper.lerp(Color("ffd890"), 0.5), 1.4, "line")
		"drum_stage":
			FestivalMeshes.drum_stage(self, mid)
			_glow(mid + Vector3(0, 1.3, 0), Color("ffd890"), 2.2)
		"moon_table": FestivalMeshes.moon_table(self, mid)
		"pampas": FestivalMeshes.pampas(self, mid)
		"paper_lantern":
			FestivalMeshes.paper_lantern(self, mid)
			_glow(mid + Vector3(0, 1.25, 0), Color("ffe0a0"), 1.8)
		"kadomatsu": FestivalMeshes.kadomatsu(self, mid)
		"bonfire":
			FestivalMeshes.bonfire(self, mid)
			_glow(mid + Vector3(0, 0.4, 0), FLAME, 3.0)
		"mochi_usu": FestivalMeshes.mochi_usu(self, mid)
		"race_flag": FestivalMeshes.race_flag(self, mid)
		_:
			push_warning("FestivalProps: no look for prop '%s'" % p.kind)
			_box(Vector3(r.size.x, 0.5, r.size.y) * 0.9, mid + Vector3(0, 0.25, 0), flat_material(Color.MAGENTA))


## A light at `pos` (FestivalGlow's glow, NightLamps' lamp) and the pool it casts on the ground
## (NightLights.festival_pools): "round" under it, "line" a string lantern's fainter one, "stall"
## in front of the counter of a stall `wide` cells across standing at `mid`.
func _glow(pos: Vector3, color: Color, size: float, pool := "round", mid := Vector3.ZERO, wide := 0.0) -> void:
	glows.append({"pos": pos, "color": color, "size": size, "pool": pool, "mid": mid, "wide": wide})


## A cherry tree in bloom (Trees.broadleaf in spring): a crown of pink lumps, petals on the
## ground.
func _sakura(mid: Vector3) -> void:
	var parts := FarmProps.Parts.new()
	Trees.broadleaf(parts, mid, "sakura", "spring", int(mid.x * 7 + mid.z * 13))
	parts.commit(self)


## A selling stall's stock set out along its counter, one item picture each (the same icons
## as in the rucksack).
func _wares(mid: Vector3, r: Rect2, stall: Dictionary) -> void:
	var stock: Array = stall.get("stock", [])
	var w := r.size.x - 0.5
	for i in stock.size():
		var s := make_sprite(PlaceholderArt.tex(PlaceholderArt.item_key(str(stock[i].item))))
		s.pixel_size = 0.028
		s.position = mid + Vector3(-w / 2 + w * (i + 0.5) / stock.size(), 0.75, 0.05)
		add_child(s)
		wares += 1


## The lights a festival's decorations give on a map (as in `glows`), without keeping the
## meshes: the flat view's FestivalView reads them for FestivalGlow.
static func glows_of(fest: String, map: String) -> Array[Dictionary]:
	var fp := FestivalProps.new(map)
	fp.festival = fest
	for p in Festivals.get_festival(fest).get("props", []):
		fp._make(p)
	var out := fp.glows
	fp.free()
	return out
