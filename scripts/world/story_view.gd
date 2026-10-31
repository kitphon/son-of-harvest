class_name StoryView
extends Node2D
## The story props of a map (KINDS: the door bell, the store's sign, Tome's jar, Kota's carp
## streamer, the ribbon board, the builder's lumber by the farmhouse while a house extension is
## under way) in the flat
## view, drawn from the same PlaceholderArt "story:" keys as in 3D (StoryProps): centred in
## their cells, standing on the bottom edge. MapView leaves them out of its boxes.

const T := 16
const KINDS: Array[String] = ["door_bell", "store_sign", "ume_jar", "carp_streamer", "ribbon_board", "lumber"]

var map: MapData


## The art key for a story prop: story:<kind>, the sign by its style (story:sign_old / new).
static func art_key(p: Dictionary) -> String:
	if str(p.kind) == "store_sign":
		return "story:sign_" + str(p.get("style", "old"))
	if str(p.kind) == "ribbon_board":   # one rosette per ribbon won (Keepsakes.RECORD)
		return "story:ribbon_board:" + Keepsakes.board_places(MapManager.flags)
	return "story:" + str(p.kind)


func _init(m: MapData) -> void:
	map = m


func _draw() -> void:
	for p in map.props:
		if not p.kind in KINDS:
			continue
		var tex := PlaceholderArt.tex(art_key(p))
		var r := Rect2(Vector2(p.cell * T), Vector2(p.size * T))
		draw_texture(tex, Vector2(roundf(r.get_center().x - tex.get_width() / 2.0), r.end.y - tex.get_height() - 1))
