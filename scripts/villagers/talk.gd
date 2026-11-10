class_name Talk
extends RefCounted
## Talking to villagers, without any drawing: who the farmer faces, which line a villager
## says, and which shop a keeper at their counter opens. Each villager's lines are an ordinary
## dialogue, data/dialogue/talk_<id>.json, with a `picks` list beside its lines: rows of
## {if: {conditions}, at: [line ids]}; the first row whose conditions all hold names the lines,
## one of them by the day, so a villager says the same thing all day and something else
## tomorrow. The last row has no `if`. Gift answers are the lines gift_<reaction> (love, like,
## neutral, dislike, hate) and gift_again (one gift a day); gift_birthday, if there, answers a
## gift that isn't disliked on their birthday. An optional `gift_items` table names lines of
## their own for keepsakes and dishes (gift_line). Format: README.md, Villagers.

const DIR := "res://data/dialogue/"
## Conditions a pick row may use besides the day-plan rule ones (Villagers.RULE_KEYS): the
## clock ["H:MM", "H:MM"], the heart band [lowest, highest], whether they already talked today,
## whether it is their birthday (birthday in the villager file) and the maps they may stand on
## (a list of map ids: lines for the river only there).
## `stage` (a list of Child stages) is for the little one's lines (talk_child.json); `scion` (a
## list of Scion stages: sapling, young, tree) is for the persimmon twig Kiku was given to plant.
const PICK_KEYS: Array[String] = ["time", "band", "again", "birthday", "map", "stage", "scion"]
const GIFT_LINES: Array[String] = ["gift_love", "gift_like", "gift_neutral", "gift_dislike", "gift_hate", "gift_again"]

static var _files := {}   # villager id -> the talk file's data


## The dialogue id of villager `id`'s lines.
static func dialogue_id(id: String) -> String:
	return "talk_" + id


static func data(id: String) -> Dictionary:
	if not _files.has(id):
		var path := DIR + dialogue_id(id) + ".json"
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		_files[id] = d if d is Dictionary else {}
	return _files[id]


## "" when `d` (a talk file) has usable picks and gift lines, else what is wrong. The lines
## themselves are checked by DialogueRunner.
static func check(d: Variant) -> String:
	if not d is Dictionary or not d.get("lines") is Array:
		return "not a dialogue"
	var ids := {}
	for l in d.lines:
		if l is Dictionary and l.get("id") is String:
			ids[l.id] = true
	for g in GIFT_LINES:
		if not ids.has(g):
			return "no line " + g
	var picks: Variant = d.get("picks")
	if not picks is Array or picks.is_empty():
		return "needs picks"
	for i in picks.size():
		var row: Variant = picks[i]
		if not row is Dictionary or not EventTriggers._names_ok(row.get("at"), ids.keys()):
			return "pick %d needs at: [line ids]" % i
		for k in row:
			if not k in ["if", "at", "_note"]:
				return "pick %d has an unknown key %s" % [i, k]
		if row.has("if") == (i == picks.size() - 1):
			return "only the last pick has no if" if row.has("if") else "pick %d needs if" % i
		var err := _check_if(row.get("if", {}))
		if err != "":
			return "pick %d: %s" % [i, err]
	var items: Variant = d.get("gift_items", {})
	if not items is Dictionary:
		return "gift_items is {item: line id}"
	for k in items:
		if not _gift_key_ok(str(k)):
			return "gift_items: %s is not a keepsake, a dish or dish: / keepsake:<reaction>" % k
		if not items[k] is String or not ids.has(items[k]):
			return "gift_items: %s needs a line id" % k
	return ""


## A gift_items key: a keepsake (keep:<id>), a dish (food:<recipe>), or "dish:<reaction>" /
## "keepsake:<reaction>" for any dish or keepsake met that way.
static func _gift_key_ok(k: String) -> bool:
	if k.begins_with("dish:") or k.begins_with("keepsake:"):
		return k.get_slice(":", 1) in Villagers.REACTIONS
	return not Keepsakes.keepsake(k).is_empty() or is_dish(k)


## Is `item` a cooked dish (food:<id> with a recipe in data/recipes.json)?
static func is_dish(item: String) -> bool:
	return item.begins_with("food:") and not Cooking.recipe(item.trim_prefix("food:")).is_empty()


## The line villager `id` answers gift `item` with when it meets reaction `r` (one of
## Villagers.REACTIONS): their own line for that item (gift_items), else their line for any
## dish / keepsake with that reaction ("dish:<r>", "keepsake:<r>"), else gift_<r>.
static func gift_line(id: String, item: String, r: String) -> String:
	var items: Dictionary = data(id).get("gift_items", {})
	if items.has(item):
		return items[item]
	var kind := "dish" if is_dish(item) else ("keepsake" if not Keepsakes.keepsake(item).is_empty() else "")
	if kind != "" and items.has(kind + ":" + r):
		return items[kind + ":" + r]
	return "gift_" + r


static func _check_if(c: Variant) -> String:
	if not c is Dictionary:
		return "if is {conditions}"
	var rule := {}
	for k in c:
		if not k in PICK_KEYS:
			rule[k] = c[k]
	var err := Villagers.check_conditions(rule)
	if err != "":
		return err
	if c.has("time"):
		var t: Variant = c.time
		if not t is Array or t.size() != 2 or EventTriggers.clock(t[0]) < 0 or EventTriggers.clock(t[1]) <= EventTriggers.clock(t[0]):
			return "time needs [\"H:MM\", \"H:MM\"], the first earlier"
	if c.has("band"):
		var b: Variant = c.band
		if not b is Array or b.size() != 2 or not EventRunner._whole(b[0], 0, 6) or not EventRunner._whole(b[1], 0, 6) or b[0] > b[1]:
			return "band needs [lowest, highest] in 0 .. 6"
	if c.has("map") and not EventTriggers._names_ok(c.map, MapManager.ids()):
		return "map needs a list of map ids (data/maps)"
	if c.has("stage") and not EventTriggers._names_ok(c.stage, Array(Child.stage_ids())):
		return "stage needs a list of the child's stages"
	if c.has("scion") and not EventTriggers._names_ok(c.scion, Scion.stage_ids()):
		return "scion needs a list of the twig's stages (data/scion.json)"
	for k in ["again", "birthday"]:
		if c.has(k) and not c[k] is bool:
			return "%s is true or false" % k
	return ""


## Does villager `id`'s talk file have line `at`? (gift_birthday is optional.)
static func has_line(id: String, at: String) -> bool:
	return data(id).get("lines", []).any(func(l): return l is Dictionary and l.get("id") == at)


## The line villager `id` opens with in state `s`: Game.trigger_state plus band (their heart
## band), again (already talked today), day_number and map (the map they stand on). "" when they have no talk file.
static func pick(id: String, s: Dictionary) -> String:
	for row in data(id).get("picks", []):
		if holds(row.get("if", {}), s):
			var at: Array = row.at
			return at[int(s.get("day_number", 0)) % at.size()]
	return ""


static func holds(c: Dictionary, s: Dictionary) -> bool:
	if not Villagers.conditions_hold(c, s):
		return false
	if c.has("time") and not (s.time >= EventTriggers.clock(c.time[0]) and s.time < EventTriggers.clock(c.time[1])):
		return false
	if c.has("band") and not (s.band >= int(c.band[0]) and s.band <= int(c.band[1])):
		return false
	if c.has("birthday") and c.birthday != s.get("birthday", false):
		return false
	if c.has("map") and not s.get("map", "") in c.map:
		return false
	if c.has("stage") and not s.get("stage", "") in c.stage:
		return false
	if c.has("scion") and not s.get("scion", "") in c.scion:
		return false
	return not c.has("again") or c.again == s.again


## The villager the farmer on `origin` faces (`facing`) on map `m` at minute `t`: the one
## standing on the cell in front, or across a counter there. {} when nobody.
static func facing_villager(m: MapData, origin: Vector2i, facing: Vector2i, t: float, s: Dictionary) -> Dictionary:
	var cells: Array[Vector2i] = [origin + facing]
	if m != null and m.prop_at(origin + facing).get("kind", "") == "counter":
		cells.append(origin + facing * 2)
	for c in cells:
		for w in Villagers.on_map(m.id if m != null else "", t, s):
			if Vector2i(w.pos.floor()) == c:
				return w
	return {}


## The shop villager `id` keeps when standing on `cell` of map `map_id`: a shop in
## data/shops.json with them as keeper, on its map, at its `keeper` spawn. "" otherwise.
static func keeper_shop(id: String, map_id: String, cell: Vector2i) -> String:
	for sid in Shop.ids():
		var s: Dictionary = Shop.data().shops[sid]
		if str(s.get("keeper", "")) != id or str(s.get("map", "")) != map_id or not MapManager.has(map_id):
			continue
		var spot: Variant = MapManager.data(map_id).spawns.get("keeper")
		if spot != null and spot[0] == cell:
			return sid
	return ""
