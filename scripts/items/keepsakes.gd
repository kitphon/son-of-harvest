class_name Keepsakes
extends RefCounted
## Things to keep (data/keepsakes.json): keepsakes bought at a festival stall ("keep:<id>")
## and contest ribbons ("ribbon:<festival>:<place>"). They sit in the rucksack and are never
## eaten, shipped or sold (Game.sell_price and Shop.buy_back give them 0). Every ribbon won
## is also written into the story flag RECORD ("<festival>:<place>:<year>", comma between),
## which the farmhouse's ribbon board shows (a map prop gated by that flag; StoryView /
## StoryProps draw one ribbon per entry). Format: README.md, Festivals.

const PATH := "res://data/keepsakes.json"
const RECORD := "ribbons"   # the story flag that lists the ribbons won
const BOARD_MOST := 12      # ribbons drawn on the board (the record keeps them all)

static var _data: Variant = null


static func data() -> Dictionary:
	if _data == null:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		if not d is Dictionary:
			push_error("Keepsakes: can't read " + PATH)
			d = {}
		_data = d
	return _data


## Is `id` a keepsake or a ribbon?
static func is_keepsake(id: String) -> bool:
	return id.begins_with("keep:") or id.begins_with("ribbon:")


## A bought keepsake's data ({} for anything else).
static func keepsake(id: String) -> Dictionary:
	return data().get("keepsakes", {}).get(id.trim_prefix("keep:"), {}) if id.begins_with("keep:") else {}


## The ribbon places, 1st first: [{name, color}].
static func places() -> Array:
	return data().get("ribbons", {}).get("places", [])


## The ribbon item for `place` (1 = first) at festival `festival`, "" below the last place.
static func ribbon_id(festival: String, place: int) -> String:
	return "ribbon:%s:%d" % [festival, place] if place >= 1 and place <= places().size() else ""


## A ribbon's place (1 = first), 0 for anything that isn't one.
static func ribbon_place(id: String) -> int:
	return clampi(int(id.get_slice(":", 2)), 0, places().size()) if id.begins_with("ribbon:") else 0


## The name to show for a keepsake or ribbon ("" for anything else).
static func name_of(id: String) -> String:
	if id.begins_with("keep:"):
		return str(keepsake(id).get("name", ""))
	var place := ribbon_place(id)
	if place == 0 or Festivals.name_of(id.get_slice(":", 1)) == "":
		return ""
	return str(data().ribbons.get("name", "%s ribbon (%s)")) % [Festivals.name_of(id.get_slice(":", 1)), places()[place - 1].name]


## The colour of the ribbon for `place` (1 = first).
static func ribbon_color(place: int) -> Color:
	var p := places()
	return Color(str(p[clampi(place, 1, p.size()) - 1].get("color", "c8442c"))) if not p.is_empty() else Color("c8442c")


# --- the record (story flag RECORD) ----------------------------------------------

## The ribbons won, oldest first, from the record flag's value: [{festival, place, year}].
static func record(flags: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in str(flags.get(RECORD, "")).split(",", false):
		var parts := e.split(":")
		if parts.size() == 3:
			out.append({"festival": parts[0], "place": int(parts[1]), "year": int(parts[2])})
	return out


## Adds a ribbon won at `festival` in `year` for `place` to the record in `flags`.
static func note(flags: Dictionary, festival: String, place: int, year: int) -> void:
	var have := str(flags.get(RECORD, ""))
	flags[RECORD] = ("%s," % have if have != "" else "") + "%s:%d:%d" % [festival, place, year]


## The board's look: the places of the last BOARD_MOST ribbons won, e.g. "112".
static func board_places(flags: Dictionary) -> String:
	var r := record(flags)
	var out := ""
	for e in r.slice(maxi(r.size() - BOARD_MOST, 0)):
		out += str(clampi(int(e.place), 1, maxi(places().size(), 1)))
	return out


## What examining the board says.
static func board_text(flags: Dictionary) -> String:
	var r := record(flags)
	if r.is_empty():
		return "An empty board for contest ribbons."
	var firsts := r.filter(func(e): return int(e.place) == 1).size()
	return "Contest ribbons: %d on the board, %d of them for first place." % [r.size(), firsts] if r.size() > 1 \
		else "Your first contest ribbon: %s, year %d." % [name_of(ribbon_id(r[0].festival, r[0].place)), r[0].year]
