class_name Talk
extends RefCounted
## Talking to villagers, without any drawing: who the farmer faces, which line a villager
## says, and which shop a keeper at their counter opens. Each villager's lines are an ordinary
## dialogue, data/dialogue/talk_<id>.json, with a `picks` list beside its lines: rows of
## {if: {conditions}, at: [line ids]}; the first row whose conditions all hold names the lines,
## one of them by the day, so a villager says the same thing all day and something else
## tomorrow. The last row has no `if`. Gift answers are the lines gift_<reaction> (love, like,
## neutral, dislike, hate) and gift_again (one gift a day). Format: README.md, Villagers.

const DIR := "res://data/dialogue/"
## Conditions a pick row may use besides the day-plan rule ones (Villagers.RULE_KEYS): the
## clock ["H:MM", "H:MM"], the heart band [lowest, highest] and whether they already talked today.
const PICK_KEYS: Array[String] = ["time", "band", "again"]
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
	return ""


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
	if c.has("again") and not c.again is bool:
		return "again is true or false"
	return ""


## The line villager `id` opens with in state `s`: Game.trigger_state plus band (their heart
## band), again (already talked today) and day_number. "" when they have no talk file.
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
