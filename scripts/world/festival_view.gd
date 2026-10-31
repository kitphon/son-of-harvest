class_name FestivalView
extends Node2D
## Today's festival decorations on one map in the flat view (data/festivals.json → props) as
## flat boxes like MapView's props, shown only during the festival's hours. Made fresh with
## the map's view.

const T := 16
const COLORS := {
	"sakura": Color("f4b8c8"), "picnic_mat": Color("3a6ab0"), "red_mat": Color("b02a24"),
	"stall": Color("8a6a48"), "lantern_line": Color("d8402c"), "drum_stage": Color("5a3a24"),
	"moon_table": Color("f8f4ea"), "pampas": Color("e4dcc4"), "paper_lantern": Color("f0e6c8"),
	"kadomatsu": Color("5a9a48"), "bonfire": Color("ffb040"),
}

var map_id := ""
var festival := ""


func _init(map: String) -> void:
	map_id = map


func _ready() -> void:
	festival = Game.festival_today()
	if Festivals.get_festival(festival).get("map", "") != map_id:
		festival = ""
	Game.minute_passed.connect(refresh)
	refresh()


func refresh() -> void:
	visible = festival != "" and Festivals.on_now(festival, map_id, Game.hour * 60 + Game.minute)


func shown() -> bool:
	return visible and festival != "" and not Festivals.get_festival(festival).get("props", []).is_empty()


func _draw() -> void:
	if festival == "":
		return
	for p in Festivals.get_festival(festival).get("props", []):
		var size: Array = p.get("size", [1, 1])
		var r := Rect2(Vector2(p.cell[0], p.cell[1]) * T, Vector2(size[0], size[1]) * T)
		var c: Color = COLORS.get(p.kind, Color.MAGENTA)
		if p.has("cloth"):
			c = Color(str(p.cloth))
		if p.kind == "lantern_line":   # a lantern every cell along the string
			for i in int(size[0]):
				draw_circle(r.position + Vector2(i * T + T / 2.0, T / 2.0), 4.0, c if i % 2 == 0 else COLORS.paper_lantern)
		else:
			draw_rect(r.grow(-2), c)
