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

const PATH := "res://data/child.json"
const NEWS := "child_news"
const BORN := "child_born"
const NAME := "child_name"
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
	var seen := {}
	for who in d.get("names", {}):
		if not Marriage.is_candidate(who):
			return "names for %s, who cannot marry" % who
		for n in names(who):
			if seen.has(n):
				return "name %s is offered twice" % n
			seen[n] = true
	return ""
