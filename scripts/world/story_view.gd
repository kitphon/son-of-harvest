class_name StoryView
extends Node2D
## The story props of a map (KINDS: the door bell, the store's sign, Tome's jar, Kota's carp
## streamer, the ribbon board, the builder's lumber by the farmhouse while a house extension is
## under way, a keepsake given to a villager who loves it, in their home, the mine's rope lift winch at the cave mouth once a landing
## is reached, the jizo's new red bibs, the three thumbprints on Ichiro's kiln and the name on Mio's boat) in the flat
## view, drawn from the same PlaceholderArt "story:" keys as in 3D (StoryProps): centred in
## their cells, standing on the bottom edge. MapView leaves them out of its boxes. The old
## kiln's wear (story:kiln_worn) is drawn over its box, on its own cells.

const T := 16
const KINDS: Array[String] = ["door_bell", "store_sign", "ume_jar", "carp_streamer", "ribbon_board", "lumber", "keepsake", "rope_lift", "jizo_bibs", "kiln_mark", "kiln_site", "kiln_new", "boat_name"]

var map: MapData


## The art key for a story prop: story:<kind>, the sign by its style (story:sign_old / new).
static func art_key(p: Dictionary) -> String:
	if str(p.kind) == "store_sign":
		return "story:sign_" + str(p.get("style", "old"))
	if str(p.kind) == "boat_name":   # Mio's boat's name by her answer (mio_boat father / new)
		return "story:boat_" + str(p.get("style", "new"))
	if str(p.kind) == "ribbon_board":   # one rosette per ribbon won (Keepsakes.RECORD)
		return "story:ribbon_board:" + Keepsakes.board_places(MapManager.flags)
	if str(p.kind) == "keepsake":   # the keepsake's own icon (`item`, keep:<id>)
		return PlaceholderArt.item_key(str(p.get("item", "")))
	return "story:" + str(p.kind)


func _init(m: MapData) -> void:
	map = m


func _ready() -> void:
	add_to_group(FlatLight.GROUP)   # the props' pictures take the world's light (redrawn when it changes)


func _draw() -> void:
	for p in map.props:
		if p.kind == "kiln":   # the old kiln's wear, over its box (MapView draws the box)
			draw_texture(PlaceholderArt.tex("story:kiln_worn"), Vector2(p.cell * T))
			continue
		if not p.kind in KINDS:
			continue
		var tex := PlaceholderArt.tex(art_key(p))
		var r := Rect2(Vector2(p.cell * T), Vector2(p.size * T))
		if p.kind == "keepsake" and not p.get("hang", false):   # on its little stand
			draw_rect(Rect2(r.position.x + 3, r.end.y - 5, T - 6, 4), Color("6a4a2a"))
			r.end.y -= 4
		elif p.kind == "keepsake":   # hung from the lintel: its top near the cell's top
			r.end.y = r.position.y + tex.get_height() + 2
		elif p.kind == "boat_name":   # on the boat's side, low in its cell (MapView draws the boat)
			r.end.y -= 3
		elif p.kind == "jizo_bibs":   # on the jizo's chest, the middle of its cell
			r.end.y -= 4
		elif p.kind == "kiln_mark":   # over the kiln's mouth, in the front cells' upper half
			r.end.y -= T / 2 + 1
			r.position.x += 12   # right of Ichiro's print, which kiln_new draws
		elif p.kind == "kiln_site" or p.kind == "kiln_new":   # the whole 2 x 2 picture on the old kiln's footing
			r.end.y -= 1
		draw_texture(tex, Vector2(roundf(r.get_center().x - tex.get_width() / 2.0), r.end.y - tex.get_height() - 1),
			FlatLight.at(Vector2(r.get_center().x, r.end.y - 1), tex.get_height(), FlatLight.field_px()))
