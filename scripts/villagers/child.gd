class_name Child
extends RefCounted
## The farmer's child (data/child.json; docs/DESIGN.md, ความรักและแต่งงาน -> ลูก). Pure rules,
## no drawing and no scenes. One child per marriage. The state is story flags and one line in
## the affection table, so the save is the marriage's own:
##   child_news = day number   (the news was told)
##   child_born = day number   (the birth)
##   child_name = "<name>"     (picked from the spouse's three)
##   Affection id "child"      (starts at heart band 3, never below it)
## Day numbers are Game.day_number(). Older saves have none of these: no child.
## The two scenes (data/events/child_news_<spouse>.json, child_birth_<spouse>.json) play on
## the first morning they are due, when the farmer wakes in the farmhouse (triggers_house.json):
## day_start sets the flag NEWS_DUE or BIRTH_DUE each morning while it holds, and the scene's
## `child` step (event_step) tells the news or gives the birth, with the name picked in its
## dialogue (data/dialogue/child.json: the choice sets child_name).

const PATH := "res://data/child.json"
const NEWS := "child_news"
const BORN := "child_born"
const NAME := "child_name"
## Set each morning the news (or the birth) is due, for the trigger rows; gone once it played.
const NEWS_DUE := "child_news_due"
const BIRTH_DUE := "child_birth_due"
## The scenes, by the spouse's id.
const NEWS_EVENT := "child_news_%s"
const BIRTH_EVENT := "child_birth_%s"
const DIALOGUE := "child"
## The stage's id while a child is born ("baby", "crawler", ...), kept in step with the day by
## sync_stage (each morning, the birth, a loaded save) so map props can be gated by it: the
## cradle in the second room shows while it is "baby" (data/maps/house.json).
const STAGE := "child_stage"
## The map prop kind of the baby's cradle (drawn by CradleView / CradleLayer, not MapView's boxes).
const CRADLE := "cradle"
## The child's id in the affection table.
const ID := "child"

static var _data: Variant = null


static func data() -> Dictionary:
	if _data == null:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		if not d is Dictionary:
			push_error("Child: can't read " + PATH)
			d = {}
		_data = d
	return _data


## The flag `key` as a whole day number, or -1 when it is not set (or not a number).
static func _day(flags: Dictionary, key: String) -> int:
	var v: Variant = flags.get(key, -1)
	return int(v) if (v is int or v is float) and v == floorf(v) and v >= 0 else -1


static func news_day(flags: Dictionary) -> int:
	return _day(flags, NEWS)


static func born_day(flags: Dictionary) -> int:
	return _day(flags, BORN)


static func has_news(flags: Dictionary) -> bool:
	return news_day(flags) >= 0


static func is_born(flags: Dictionary) -> bool:
	return born_day(flags) >= 0


## The child's name ("" until it is picked).
static func child_name(flags: Dictionary) -> String:
	return str(flags.get(NAME, "")) if flags.get(NAME, "") is String else ""


## Is the news due this morning (day number `today`)? Married (the spouse flags and the day of
## the wedding), news_after_days past the wedding, the spouse's heart band `band` at least
## news_band, `festival` false (today is not a festival day), no news told yet. Until it
## holds, the news waits.
static func news_due(flags: Dictionary, today: int, band: int, festival: bool) -> bool:
	var id := Marriage.spouse(flags)
	if id == "" or not EventRunner.is_set(flags, "married_" + id) or has_news(flags):
		return false
	var wedding := _day(flags, Marriage.DAY)
	if wedding < 0 or today < wedding + int(data().get("news_after_days", 30)):
		return false
	return band >= int(data().get("news_band", 6)) and not festival


## Is the birth due this morning? The news told birth_after_days ago, not a festival day, not
## born yet.
static func birth_due(flags: Dictionary, today: int, festival: bool) -> bool:
	if not has_news(flags) or is_born(flags) or festival:
		return false
	return today >= news_day(flags) + int(data().get("birth_after_days", 30))


## The news is told on day `today`.
static func tell_news(flags: Dictionary, today: int) -> void:
	flags[NEWS] = today


## The birth on day `today`, named `name`.
static func give_birth(flags: Dictionary, today: int, name: String) -> void:
	flags[BORN] = today
	flags[NAME] = name


## A new morning (day number `today`, the spouse's heart band `band`, `festival` true on a
## festival day): sets NEWS_DUE or BIRTH_DUE while that scene is due, else clears it. Returns
## "news", "birth" or "".
static func day_start(flags: Dictionary, today: int, band: int, festival: bool) -> String:
	sync_stage(flags, today)
	flags.erase(NEWS_DUE)
	flags.erase(BIRTH_DUE)
	if news_due(flags, today, band, festival):
		flags[NEWS_DUE] = true
		return "news"
	if birth_due(flags, today, festival):
		flags[BIRTH_DUE] = true
		return "birth"
	return ""


## A scene's `child` step on day `today`: "news" tells the news; "birth" gives the birth with
## the name the dialogue's choice set (child_name; the spouse's first name if none was).
static func event_step(flags: Dictionary, step: String, today: int) -> void:
	if step == "news" and not has_news(flags):
		tell_news(flags, today)
		flags.erase(NEWS_DUE)
	elif step == "birth" and has_news(flags) and not is_born(flags):
		var n := child_name(flags)
		if n == "" or not n in names(Marriage.spouse(flags)):
			var list := names(Marriage.spouse(flags))
			n = str(list[0]) if not list.is_empty() else n
		give_birth(flags, today, n)
		flags.erase(BIRTH_DUE)
		sync_stage(flags, today)


## The three names the spouse `id` offers (empty for someone who cannot marry).
static func names(id: String) -> Array:
	var n: Variant = data().get("names", {}).get(id, [])
	return n if n is Array else []


## Days since the birth on day `today` (-1 when there is no child yet).
static func age(flags: Dictionary, today: int) -> int:
	return today - born_day(flags) if is_born(flags) else -1


## The stage id of a child `days` old: baby, crawler, toddler, child ("" for days < 0).
static func stage_at(days: int) -> String:
	if days < 0:
		return ""
	var out := ""
	for s in data().get("stages", []):
		if days >= int(s.get("from", 0)):
			out = str(s.get("id", ""))
	return out


## The child's stage on day `today` ("" when none is born).
static func stage(flags: Dictionary, today: int) -> String:
	return stage_at(age(flags, today))


## Sets STAGE to the stage on day `today` (erased while no child is born).
static func sync_stage(flags: Dictionary, today: int) -> void:
	var s := stage(flags, today)
	if s == "":
		flags.erase(STAGE)
	else:
		flags[STAGE] = s


## Is the child a baby on day `today` (the cradle in the second room)?
static func is_baby(flags: Dictionary, today: int) -> bool:
	return stage(flags, today) == "baby"


## The cradle's row for `minute_of_day` (data/child.json cradle.times): {from, look, line}.
## Before the first row's time the last row still holds (it runs past midnight). Minutes past
## 24:00 (Game.day_minutes after midnight) count from midnight again.
static func cradle_time(minute_of_day: int) -> Dictionary:
	minute_of_day = posmod(minute_of_day, 24 * 60)
	var rows: Array = data().get("cradle", {}).get("times", [])
	if rows.is_empty():
		return {"look": "asleep", "line": "%s"}
	var out: Dictionary = rows.back()
	for r in rows:
		if _minutes(str(r.get("from", "00:00"))) <= minute_of_day:
			out = r
	return out


## What the farmer reads looking into the cradle at `minute_of_day`, the name put in (English;
## the message is translated as a pattern).
static func cradle_line(flags: Dictionary, minute_of_day: int) -> String:
	return str(cradle_time(minute_of_day).get("line", "%s")) % child_name(flags)


## The baby's picture in the cradle at `minute_of_day`: asleep, awake or cry.
static func cradle_look(minute_of_day: int) -> String:
	return str(cradle_time(minute_of_day).get("look", "asleep"))


static func _minutes(s: String) -> int:
	var parts := s.split(":")
	return int(parts[0]) * 60 + (int(parts[1]) if parts.size() > 1 else 0)


## The PlaceholderArt key of the cradle with the baby in it (`look` asleep / awake / cry), or
## empty ("empty", while the farmer holds the baby), in the child's colours `colours`
## (Child.look): child:cradle:<look>:<skin>:<hair>:<top>.
static func cradle_key(state: String, colours: Dictionary) -> String:
	return "child:cradle:%s:%s" % [state, _colour_part(colours)]


## The baby held up in the farmer's arms (the hold pose): child:held:<look>:<skin>:<hair>:<top>.
static func held_key(state: String, colours: Dictionary) -> String:
	return "child:held:%s:%s" % ["asleep" if state == "asleep" else "awake", _colour_part(colours)]


static func _colour_part(c: Dictionary) -> String:
	return "%s:%s:%s" % [str(c.get("skin", "e0b088")), str(c.get("hair", "3a2a24")), str(c.get("top", "2e4a8c"))]


static func stage_ids() -> Array[String]:
	var out: Array[String] = []
	for s in data().get("stages", []):
		out.append(str(s.get("id", "")))
	return out


## The child's FigureArt colours from the parents: the spouse's hair style and colour (`spouse`
## is the villager's look), the skin the middle of the farmer's (`farmer_skin`, hex) and the
## spouse's, and the house's small indigo happi.
static func look(spouse: Dictionary, farmer_skin: String) -> Dictionary:
	var l: Dictionary = data().get("look", {})
	var out := {"hair_style": str(spouse.get("hair_style", "short")), "hair": str(spouse.get("hair", "3a2a24"))}
	out.skin = mix(farmer_skin, str(spouse.get("skin", farmer_skin)), float(l.get("skin_mix", 0.5)))
	var clothes: Dictionary = l.get("clothes", {})
	for k in clothes:
		out[k] = str(clothes[k])
	return out


## The colour `t` of the way from hex `a` to hex `b` (t = 0.5 is the middle), as lowercase hex.
static func mix(a: String, b: String, t: float) -> String:
	return Color.html(a).lerp(Color.html(b), t).to_html(false)


## The child's affection when first met (points at the start of start_band).
static func start_points() -> int:
	return _band_points(int(data().get("hearts", {}).get("start_band", 3)))


## The fewest affection points `id` can have: the child's floor, 0 for everyone else.
static func min_points(id: String) -> int:
	return _band_points(int(data().get("hearts", {}).get("min_band", 3))) if id == ID else 0


static func _band_points(band: int) -> int:
	var starts: Array = Affection.rules().get("bands", [0])
	return int(starts[clampi(band, 0, starts.size() - 1)])


## "" when the data can be used, else what is wrong with it.
static func check() -> String:
	var d := data()
	for k in ["news_after_days", "birth_after_days"]:
		if not EventRunner._whole(d.get(k, 0), 1, 999):
			return "%s is 1 .. 999" % k
	if not EventRunner._whole(d.get("news_band", -1), 0, 6):
		return "news_band is 0 .. 6"
	var ids := stage_ids()
	if ids != ["baby", "crawler", "toddler", "child"]:
		return "stages are baby, crawler, toddler, child (%s)" % [ids]
	var last := -1
	for s in d.get("stages", []):
		if not EventRunner._whole(s.get("from", -1), 0, 9999) or int(s.from) <= last:
			return "stage %s: from must rise" % s.get("id", "")
		last = int(s.from)
	if int(d.stages[0].from) != 0:
		return "the first stage starts at day 0"
	var h: Dictionary = d.get("hearts", {})
	if not EventRunner._whole(h.get("start_band", -1), 0, 6) or not EventRunner._whole(h.get("min_band", -1), 0, 6) or int(h.start_band) < int(h.min_band):
		return "hearts: start_band and min_band are 0 .. 6, start at least min"
	for who in Marriage.candidates():
		var list := names(who)
		if list.size() != 3:
			return "%s needs three names" % who
		for n in list:
			if not n is String or n.strip_edges() == "":
				return "%s has a name that is not a word" % who
		for ev in [NEWS_EVENT, BIRTH_EVENT]:
			if not FileAccess.file_exists(EventRunner.DIR + (ev % who) + ".json"):
				return "no event %s" % (ev % who)
	var rows: Array = d.get("cradle", {}).get("times", [])
	if rows.is_empty():
		return "cradle.times is empty"
	var at := -1
	for r in rows:
		if not r is Dictionary or not str(r.get("look", "")) in ["asleep", "awake", "cry"] or not "%s" in str(r.get("line", "")):
			return "a cradle row needs a look (asleep, awake, cry) and a line with %s"
		var m := _minutes(str(r.get("from", "")))
		if m <= at or m >= 24 * 60:
			return "cradle times must rise within the day"
		at = m
	var seen := {}
	for who in d.get("names", {}):
		if not Marriage.is_candidate(who):
			return "names for %s, who cannot marry" % who
		for n in names(who):
			if seen.has(n):
				return "name %s is offered twice" % n
			seen[n] = true
	return ""
