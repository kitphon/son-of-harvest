class_name FestivalView
extends Node2D
## Today's festival decorations on one map in the flat view (data/festivals.json → props),
## drawn from PlaceholderArt "festival:" keys: each picture is the 3D prop (FestivalProps) seen
## front-on, standing on the middle of its cells, nearer ones over farther ones. Shown only
## during the festival's hours; made fresh with the map's view. Its lights
## (FestivalProps.glows_of) are in `glows` for FestivalGlow, which draws them over the night
## tint: a light at (x, y up, z) shows at (x, z - y) cells, where the picture hangs its lamp.

const T := 16
const GROUP := "festival_view"

var map_id := ""
var festival := ""
var glows: Array[Dictionary] = []   # {pos: Vector2 px in this node, color: Color, size: px across}


func _init(map: String) -> void:
	map_id = map


func _ready() -> void:
	add_to_group(GROUP)
	festival = Game.festival_today()
	if Festivals.get_festival(festival).get("map", "") != map_id:
		festival = ""
	else:
		for g in FestivalProps.glows_of(festival, map_id):
			glows.append({"pos": glow_pos(g.pos), "color": g.color, "size": float(g.size) * T})
	Game.minute_passed.connect(refresh)
	refresh()


func refresh() -> void:
	visible = festival != "" and Festivals.on_now(festival, map_id, Game.hour * 60 + Game.minute)


func shown() -> bool:
	return visible and festival != "" and not Festivals.get_festival(festival).get("props", []).is_empty()


## Where a 3D light (FestivalProps.glows) shows in this view, in pixels.
static func glow_pos(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z - p.y) * T


## The art key for a decoration: festival:<kind>:<w>x<h>, a stall with its cloth colour.
static func art_key(p: Dictionary) -> String:
	var size: Array = p.get("size", [1, 1])
	var key := "festival:%s:%dx%d" % [p.kind, int(size[0]), int(size[1])]
	if p.kind == "stall":
		key += ":" + str(p.get("cloth", "c8442c"))
	return key


## The art key of the display on a stall prop's counter (data: "display"), "" for none.
static func display_key(p: Dictionary) -> String:
	return "festival:display_%s:1x1" % p.display if p.has("display") else ""


## The middle of a decoration's cells, in pixels: where its picture stands.
static func ground_mid(p: Dictionary) -> Vector2:
	var size: Array = p.get("size", [1, 1])
	return Rect2(Vector2(p.cell[0], p.cell[1]) * T, Vector2(size[0], size[1]) * T).get_center()


## The top left corner of a decoration's picture, in pixels.
static func art_origin(p: Dictionary) -> Vector2:
	var size: Array = p.get("size", [1, 1])
	return ground_mid(p) - Vector2(PlaceholderArt.festival_anchor(str(p.kind), int(size[0]), int(size[1])))


func _draw() -> void:
	if festival == "":
		return
	var props: Array = Festivals.get_festival(festival).get("props", []).duplicate()
	props.sort_custom(func(a, b): return ground_mid(a).y < ground_mid(b).y)
	for p in props:
		draw_texture(PlaceholderArt.tex(art_key(p)), art_origin(p))
		if p.kind == "stall":   # a selling stall's stock along its counter (FestivalProps._wares)
			var stock: Array = Festivals.stall_of_prop(festival, p).get("stock", [])
			var mid := ground_mid(p)
			var w: float = (float(p.get("size", [1, 1])[0]) - 0.75) * T   # clear of the corner lantern
			for i in stock.size():
				var tex := PlaceholderArt.tex(PlaceholderArt.item_key(str(stock[i].item)))
				var x := mid.x - w / 2 + w * (i + 0.5) / stock.size()
				draw_texture(tex, Vector2(x - tex.get_width() / 2.0, mid.y - 4 - tex.get_height()).round())
			if p.has("display"):   # a stall that sells nothing sets out a display (StallWares.DISPLAYS)
				var show := PlaceholderArt.tex(display_key(p))
				draw_texture(show, Vector2(mid.x - 4 - show.get_width() / 2.0, mid.y - 4 - show.get_height()).round())
