class_name StoryView
extends Node2D
## The story props of a map (KINDS: the door bell, the store's sign, Tome's jar, Kota's carp
## streamer, the ribbon board, the builder's lumber by the farmhouse while a house extension is
## under way, a keepsake given to a villager who loves it, in their home, the mine's rope lift winch at the cave mouth once a landing
## is reached, the jizo's new red bibs, the three thumbprints on Ichiro's kiln, the name on Mio's boat, the noren Shino dyed,
## Captain's jar by Shige's door, Captain the frog in the ditch and Nana's sky map on the hen barn) in the flat
## view, drawn from the same PlaceholderArt "story:" keys as in 3D (StoryProps): centred in
## their cells, standing on the bottom edge. MapView leaves them out of its boxes. The old
## kiln's wear (story:kiln_worn) is drawn over its box, on its own cells.

const T := 16
const KINDS: Array[String] = ["door_bell", "store_sign", "ume_jar", "carp_streamer", "ribbon_board", "lumber", "keepsake", "rope_lift", "jizo_bibs", "kiln_mark", "kiln_site", "kiln_new", "boat_name", "noren", "scion", "captain_jar", "frog", "sky_map"]

var map: MapData


## The art key for a story prop: story:<kind>, the sign by its style (story:sign_old / new).
static func art_key(p: Dictionary) -> String:
	if str(p.kind) == "store_sign":
		return "story:sign_" + str(p.get("style", "old"))
	if str(p.kind) == "noren":   # a door curtain Shino dyed (shino_noren rows / flowers, or her own)
		return "story:noren_" + str(p.get("style", "shino"))
	if str(p.kind) == "scion":   # Kiku's persimmon, by its age and the season (Scion)
		return scion_key()
	if str(p.kind) == "boat_name":   # Mio's boat's name by her answer (mio_boat father / new)
		return "story:boat_" + str(p.get("style", "new"))
	if str(p.kind) == "ribbon_board":   # one rosette per ribbon won (Keepsakes.RECORD)
		return "story:ribbon_board:" + Keepsakes.board_places(MapManager.flags)
	if str(p.kind) == "sky_map":   # Nana's stars by her answers (nana_beside, nana_star)
		return sky_map_key(MapManager.flags)
	if str(p.kind) == "keepsake":   # the keepsake's own icon (`item`, keep:<id>)
		return PlaceholderArt.item_key(str(p.get("item", "")))
	return "story:" + str(p.kind)


## The season's name (spring if the game is not up, as in a bare tool run).
static func _season() -> String:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	return game.season_name() if game != null else "spring"

## Kiku's persimmon today: its stage by the days since it was planted (Game.flags), the
## season's look, snow on the winter branches with snow lying (a sapling in spring when the
## game is not up).
static func scion_key() -> String:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if game == null:
		return Scion.art_key("sapling", "spring", false)
	var season: String = game.season_name()
	return Scion.art_key(Scion.stage(game.flags, game.day_number()), season, Scion.snowy(season, game.snow_cover))


## Nana's sky map with these story flags: her father's star the big steady one, or beside her
## mother's (nana_beside, her band 5 answer); the farmer's near his or out over the field
## (nana_star, band 6).
static func sky_map_key(f: Dictionary) -> String:
	var star := str(f.get("nana_star", "near"))
	return "story:sky_map:%s:%s" % ["beside" if EventRunner.is_set(f, "nana_beside") else "steady", "field" if star == "field" else "near"]


func _init(m: MapData) -> void:
	map = m


func _ready() -> void:
	add_to_group(FlatLight.GROUP)   # the props' pictures take the world's light (redrawn when it changes)
	var game := get_node_or_null("/root/Game")
	if game != null:
		game.day_started.connect(queue_redraw)   # the persimmon twig changes with the season


func _draw() -> void:
	for p in map.props:
		if p.kind == "kiln":   # the old kiln's wear, over its box (MapView draws the box)
			draw_texture(PlaceholderArt.tex("story:kiln_worn"), Vector2(p.cell * T))
			continue
		if not p.kind in KINDS or p.kind == "boat_name":   # the boat's name goes with the boat (FerryView)
			continue
		var tex := PlaceholderArt.tex(art_key(p))
		var r := Rect2(Vector2(p.cell * T), Vector2(p.size * T))
		if p.kind == "keepsake" and not p.get("hang", false):   # on its little stand
			draw_rect(Rect2(r.position.x + 3, r.end.y - 5, T - 6, 4), Color("6a4a2a"))
			r.end.y -= 4
		elif p.kind == "keepsake":   # hung from the lintel: its top near the cell's top
			r.end.y = r.position.y + tex.get_height() + 2
		elif p.kind == "noren":   # over the door, the top of its cell
			r.end.y = r.position.y + tex.get_height() + 2
		elif p.kind == "frog":   # on the ditch's back bank
			r.end.y -= 5
		elif p.kind == "sky_map":   # pinned to the hen barn's front, over its lower half
			r.end.y -= 2
		elif p.kind == "jizo_bibs":   # on the jizo's chest, the middle of its cell
			r.end.y -= 4
		elif p.kind == "kiln_mark":   # over the kiln's mouth, in the front cells' upper half
			r.end.y -= T / 2 + 1
			r.position.x += 12   # right of Ichiro's print, which kiln_new draws
		elif p.kind == "kiln_site" or p.kind == "kiln_new":   # the whole 2 x 2 picture on the old kiln's footing
			r.end.y -= 1
		draw_texture(tex, Vector2(roundf(r.get_center().x - tex.get_width() / 2.0), r.end.y - tex.get_height() - 1),
			FlatLight.at(Vector2(r.get_center().x, r.end.y - 1), tex.get_height(), FlatLight.field_px()))
