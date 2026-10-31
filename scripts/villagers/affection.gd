class_name Affection
extends RefCounted
## How much each villager likes the farmer, and the day each last counted a talk and took a
## gift, so both count once a day. The numbers (what a talk or a gift is worth, the 7 heart
## bands) are in data/villagers/_common.json "affection"; a gift's reaction comes from the
## villager's own file (Villagers.reaction). Saved with the run (Game.affection). Pure logic.

var points := {}   # villager id -> 0 .. max
var talked := {}   # id -> day number (Game.day_number) of the last talk that counted
var gifted := {}   # id -> day number of the last gift


static func rules() -> Dictionary:
	return Villagers.common().get("affection", {})


static func max_points() -> int:
	return int(rules().get("max", 255))


func of(id: String) -> int:
	return int(points.get(id, rules().get("start", 0)))


## Changes villager `id`'s affection by `n` (kept in 0 .. max); returns the new value. The
## hook for events (EventRunner "affection") and anything else that pleases or hurts them.
func add(id: String, n: int) -> int:
	points[id] = clampi(of(id) + n, 0, max_points())
	return points[id]


## The heart band (0 .. 6) of villager `id`.
func band(id: String) -> int:
	return band_of(of(id))


static func band_of(p: int) -> int:
	var b := 0
	var starts: Array = rules().get("bands", [0])
	for i in starts.size():
		if p >= int(starts[i]):
			b = i
	return b


## Every villager's band so far, id -> band (event trigger rows check these).
func bands() -> Dictionary:
	var out := {}
	for id in Villagers.all():
		out[id] = band(id)
	return out


func talked_on(id: String, day: int) -> bool:
	return int(talked.get(id, -1)) == day


func gifted_on(id: String, day: int) -> bool:
	return int(gifted.get(id, -1)) == day


## A talk with villager `id` on day `day`: the first one that day is worth `talk`, later ones
## nothing. Returns the change.
func talk(id: String, day: int) -> int:
	if talked_on(id, day):
		return 0
	talked[id] = day
	var was := of(id)
	return add(id, int(rules().get("talk", 1))) - was


## Villager `id` is offered `item` on day `day`: {ok, reaction, change}. One gift a day; a
## second one is refused (reaction "again") and the farmer keeps the item. On their birthday
## the gift counts birthday_times over, good or bad.
func give(id: String, item: String, day: int, birthday := false) -> Dictionary:
	if gifted_on(id, day):
		return {"ok": false, "reaction": "again", "change": 0}
	gifted[id] = day
	var r := Villagers.reaction(id, item)
	var was := of(id)
	var times := int(rules().get("birthday_times", 1)) if birthday else 1
	return {"ok": true, "reaction": r, "change": add(id, int(rules().get("gift", {}).get(r, 0)) * times) - was}


## The night after day `day`: each villager the farmer has met (affection above 0) who got
## neither a talk nor a gift that day may lose a little (neglect: chance, loss). Returns the
## ids that lost some.
func day_end(day: int, rng: RandomNumberGenerator) -> Array[String]:
	var n: Dictionary = rules().get("neglect", {})
	var out: Array[String] = []
	for id in Villagers.all():
		if of(id) <= 0 or talked_on(id, day) or gifted_on(id, day):
			continue
		if rng.randf() < float(n.get("chance", 0.0)):
			add(id, -int(n.get("loss", 0)))
			out.append(id)
	return out


func to_dict() -> Dictionary:
	return {"points": points.duplicate(), "talked": talked.duplicate(), "gifted": gifted.duplicate()}


## [error, Affection] from saved data ("" = usable). Ids are kept even for a villager whose
## file is gone, so taking a villager out doesn't break older saves.
static func parse(v: Variant) -> Array:
	var a := Affection.new()
	if not v is Dictionary:
		return ["Saved affection is broken", null]
	for key in ["points", "talked", "gifted"]:
		var part: Variant = v.get(key, {})
		if not part is Dictionary:
			return ["Saved affection is broken", null]
		for id in part:
			var n: Variant = SaveGame.whole(part[id], 0 if key == "points" else -1, max_points() if key == "points" else 1 << 40)
			if not id is String or id == "" or n == null:
				return ["Saved affection is broken", null]
			a.get(key)[id] = n
	return ["", a]
