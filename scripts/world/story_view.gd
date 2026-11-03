class_name StoryView
extends Node2D
## The story props of a map (KINDS: the door bell, the store's sign, Tome's jar, Kota's carp
## streamer, the ribbon board, the builder's lumber by the farmhouse while a house extension is
## under way, a keepsake given to a villager who loves it, in their home, the mine's rope lift winch at the cave mouth once a landing
## is reached) in the flat
## view, drawn from the same PlaceholderArt "story:" keys as in 3D (StoryProps): centred in
## their cells, standing on the bottom edge. MapView leaves them out of its boxes.

const T := 16
const KINDS: Array[String] = ["door_bell", "store_sign", "ume_jar", "carp_streamer", "ribbon_board", "lumber", "keepsake", "rope_lift"]

var map: MapData


## The art key for a story prop: story:<kind>, the sign by its style (story:sign_old / new).
static func art_key(p: Dictionary) -> String:
	if str(p.kind) == "store_sign":
		return "story:sign_" + str(p.get("style", "old"))
	if str(p.kind) == "ribbon_board":   # one rosette per ribbon won (Keepsakes.RECORD)
		return "story:ribbon_board:" + Keepsakes.board_places(MapManager.flags)
	if str(p.kind) == "keepsake":   # the keepsake's own icon (`item`, keep:<id>)
		return PlaceholderArt.item_key(str(p.get("item", "")))
	return "story:" + str(p.kind)


func _init(m: MapData) -> void:
	map = m


func _draw() -> void:
	for p in map.props:
		if not p.kind in KINDS:
			continue
		var tex := PlaceholderArt.tex(art_key(p))
		var r := Rect2(Vector2(p.cell * T), Vector2(p.size * T))
		if p.kind == "keepsake" and not p.get("hang", false):   # on its little stand
			draw_rect(Rect2(r.position.x + 3, r.end.y - 5, T - 6, 4), Color("6a4a2a"))
			r.end.y -= 4
		elif p.kind == "keepsake":   # hung from the lintel: its top near the cell's top
			r.end.y = r.position.y + tex.get_height() + 2
		draw_texture(tex, Vector2(roundf(r.get_center().x - tex.get_width() / 2.0), r.end.y - tex.get_height() - 1))
