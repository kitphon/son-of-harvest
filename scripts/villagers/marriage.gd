class_name Marriage
extends RefCounted
## Where courting ends (data/marriage.json): the farmer holds the proposal item (a keepsake,
## sold at the general store) overhead and talks to a villager who can marry. When the rules
## hold (the top heart band, their band 6 scene seen, the second room built, nobody else
## promised) the knot is taken, they are engaged and the proposal event plays; else the
## villager answers why not and the knot stays in hand. On the wedding day (a few days on,
## never a festival) the flag DUE is set each morning until the wedding event has played in
## the village (a trigger row in triggers_town.json); the event sets the spouse flags. The
## state is story flags only, so it is saved with them:
##   engaged = "<id>", engaged_<id> = true, wedding_day = day number   (between the two events)
##   wedding_due = true                                                  (from that morning)
##   spouse = "<id>", married_<id> = true                                (after the wedding;
##       wedding_day stays, for the village record's line: Ending.spouse_line)
## Married, the spouse helps each morning (help: a few dry plots watered on fair days, the
## coop's feed box topped up from the farmer's stock; Game.end_day, told on stepping out).
## The spouse's day plan (a married_<id> rule in their villager file) has them live at the
## farmhouse, and their talk file has married lines. Format: README.md, Villagers → Marriage.

const PATH := "res://data/marriage.json"
const ENGAGED := "engaged"
const DAY := "wedding_day"
const DUE := "wedding_due"
const SPOUSE := "spouse"
## Why a proposal is turned down, in the order they are asked (the dialogue line is <id>_<why>).
const REASONS: Array[String] = ["married", "taken", "waiting", "band", "room"]

static var _data: Variant = null


static func data() -> Dictionary:
	if _data == null:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		if not d is Dictionary:
			push_error("Marriage: can't read " + PATH)
			d = {}
		_data = d
	return _data


## The proposal item (a keepsake id, keep:<id>).
static func item() -> String:
	return str(data().get("item", ""))


static func candidates() -> Array:
	return data().get("candidates", [])


static func is_candidate(id: String) -> bool:
	return id in candidates()


## The dialogue file of the answers and the scenes' lines.
static func dialogue() -> String:
	return str(data().get("dialogue", "marriage"))


## The event of `kind` ("propose" or "wedding") for villager `id`.
static func event(kind: String, id: String) -> String:
	return str(data().get("events", {}).get(kind, "%s_%%s" % kind)) % id


## A text from the data's messages ("" when missing).
static func text(key: String) -> String:
	return str(data().get("messages", {}).get(key, ""))


static func spouse(flags: Dictionary) -> String:
	return str(flags.get(SPOUSE, "")) if flags.get(SPOUSE, "") is String else ""


static func engaged(flags: Dictionary) -> String:
	return str(flags.get(ENGAGED, "")) if flags.get(ENGAGED, "") is String else ""


## What villager `id` says to the proposal item: "" = yes; "not_candidate" for someone who
## can't marry; else one of REASONS. `band` is their heart band, `seen` the events seen,
## `built` the house extensions done.
static func answer(id: String, band: int, flags: Dictionary, seen: Dictionary, built: Array) -> String:
	if not is_candidate(id):
		return "not_candidate"
	if spouse(flags) == id:
		return "married"
	if spouse(flags) != "" or (engaged(flags) != "" and engaged(flags) != id):
		return "taken"
	if engaged(flags) == id:
		return "waiting"
	var after := str(data().get("after", "heart_%s_6"))
	if band < int(data().get("band", 6)) or (after != "" and not seen.has(after % id)):
		return "band"
	var room := str(data().get("built", ""))
	if room != "" and not room in built:
		return "room"
	return ""


## The day number of the wedding for a proposal on day `today`: `wedding_after_days` on,
## moved past festival days (`is_festival(day number) -> bool`).
static func wedding_day(today: int, is_festival: Callable) -> int:
	var n := today + maxi(1, int(data().get("wedding_after_days", 3)))
	for _i in 30:
		if not is_festival.call(n):
			break
		n += 1
	return n


## Villager `id` said yes on day `today`: the engaged flags.
static func engage(flags: Dictionary, id: String, today: int, is_festival: Callable) -> void:
	flags[ENGAGED] = id
	flags[ENGAGED + "_" + id] = true
	flags[DAY] = wedding_day(today, is_festival)


## A new morning (day number `today`): is the wedding due? Sets DUE and says so.
static func day_start(flags: Dictionary, today: int) -> bool:
	if engaged(flags) == "" or spouse(flags) != "" or not flags.get(DAY) is int:
		return false
	if today < int(flags[DAY]):
		return false
	flags[DUE] = true
	return true


## The spouse's morning help (data/marriage.json help), after the night (`farm` and `animals`
## have had their day_end; `weather` is today's): on a day whose weather is in help.weather,
## up to help.water dry plots with an unripe crop are watered (FarmGrid.water_dry_crops), and
## when a home in help.feed_homes is short in its feed box, up to help.feed portions go in
## from the farmer's own feed stock (Animals.fill_feed_box). Nothing when single.
## Returns {watered, fed}: the counts.
static func help(flags: Dictionary, farm: FarmGrid, animals: Animals, weather: String) -> Dictionary:
	var out := {"watered": 0, "fed": 0}
	var id := spouse(flags)
	if id == "" or not EventRunner.is_set(flags, "married_" + id):
		return out
	var h: Dictionary = data().get("help", {})
	if farm != null and weather in h.get("weather", ["sunny"]):
		out.watered = farm.water_dry_crops(int(h.get("water", 0)))
	if animals != null:
		for home in h.get("feed_homes", ["coop"]):
			out.fed += animals.fill_feed_box(String(home), int(h.get("feed", 0)))
	return out


## What the farmer is told on stepping out that morning ("" when the spouse did nothing):
## help.messages watered / fed / both, with the spouse's name.
static func help_text(done: Dictionary, name: String) -> String:
	var kind := ""
	if int(done.get("watered", 0)) > 0:
		kind = "both" if int(done.get("fed", 0)) > 0 else "watered"
	elif int(done.get("fed", 0)) > 0:
		kind = "fed"
	if kind == "":
		return ""
	var t := str(data().get("help", {}).get("messages", {}).get(kind, ""))
	return t % name if "%s" in t else t


## The HUD tag under the clock on the wedding day ("" else).
static func day_tag(flags: Dictionary) -> String:
	return text("tag") if EventRunner.is_set(flags, DUE) and spouse(flags) == "" else ""


## "" when the data can be used, else what is wrong with it.
static func check() -> String:
	var d := data()
	if not Keepsakes.is_keepsake(item()) or Keepsakes.keepsake(item()).is_empty():
		return "item %s is not a keepsake in data/keepsakes.json" % item()
	if candidates().is_empty():
		return "no candidates"
	for id in candidates():
		if not Villagers.friends().has(id):
			return "%s is not a villager with hearts" % id
		for kind in ["propose", "wedding"]:
			if not FileAccess.file_exists(EventRunner.DIR + event(kind, id) + ".json"):
				return "no event %s" % event(kind, id)
		for why in REASONS:
			if DialogueRunner.open(dialogue(), {}, "%s_%s" % [id, why]).error != "":
				return "no line %s_%s in %s" % [id, why, dialogue()]
	if not EventRunner._whole(d.get("band", 6), 0, 6):
		return "band is 0 .. 6"
	for k in ["not_candidate", "due", "tag"]:
		if text(k) == "":
			return "messages need %s" % k
	var h: Variant = d.get("help", {})
	if not h is Dictionary or not h.get("weather", []) is Array or not h.get("feed_homes", []) is Array:
		return "help needs weather and feed_homes lists"
	for k in ["water", "feed"]:
		if not EventRunner._whole(h.get(k, 0), 0, 99):
			return "help.%s is 0 .. 99" % k
	for k in ["watered", "fed", "both"]:
		if not str(h.get("messages", {}).get(k, "")).contains("%s"):
			return "help.messages.%s needs the spouse's name" % k
	return ""
