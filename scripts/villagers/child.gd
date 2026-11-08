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


# --- the crawler and the toddler about the house (step 4) ----------------------------

## The stages the little one is a figure of its own, out of the cradle (Villagers shows them
## like a villager, under the id ID).
const FIGURE_STAGES: Array[String] = ["crawler", "toddler", "child"]


## Is the little one about as a figure now (the stage flag is crawler, toddler or child)?
static func about(flags: Dictionary) -> bool:
	return is_born(flags) and str(flags.get(STAGE, "")) in FIGURE_STAGES


## The day plans of `stage` (data/child.json days): {speed, rules, default, plans}; a stage
## with none of its own uses the toddler's.
static func days_of(stage: String) -> Dictionary:
	var d: Dictionary = data().get("days", {})
	var own: Variant = d.get(stage)
	return own if own is Dictionary and own.has("plans") else d.get("toddler", {})


## The plan's name for a day in state `s` (Game.trigger_state): the first rule that holds.
static func plan_name(s: Dictionary) -> String:
	var d := days_of(str(s.flags.get(STAGE, "")))
	return Villagers.pick_plan({"id": ID, "rules": d.get("rules", []), "default": d.get("default", "")}, s)


## Today's DayPlan for the little one in state `s` (null while not about).
static func plan(s: Dictionary) -> DayPlan:
	if not about(s.flags):
		return null
	var d := days_of(str(s.flags.get(STAGE, "")))
	var r := DayPlan.build(d.get("plans", {}).get(plan_name(s), []), float(d.get("speed", 1.0)))
	return r[1]


## Where the little one is, from where its own plan puts it (`w`, as DayPlan.where gives) and
## where the spouse is (`spouse`, as Villagers.where gives): while both are on the home map, at
## the spouse's side (days.by_spouse), turned to them (walking along with them while they
## walk). `stage` picks the offset (a stage without one uses the toddler's).
static func by_spouse(w: Dictionary, spouse: Dictionary, stage: String) -> Dictionary:
	var d: Dictionary = data().get("days", {})
	var offs: Dictionary = d.get("by_spouse", {})
	var off: Variant = offs.get(stage, offs.get("toddler"))
	if not off is Array or w.get("map", "") != str(d.get("home", "house")) or spouse.get("map", "") != w.map:
		return w
	var out := w.duplicate()
	var v := Vector2(float(off[0]), float(off[1]))
	out.pos = spouse.pos + v
	out.moving = spouse.get("moving", false)
	out.walked = spouse.get("walked", 0.0)
	out.facing = spouse.facing if out.moving else DayPlan.facing_of(-v)
	return out


## The child stage's time out with spouse `spouse_id` on a day with plan `plan_name`
## (days.child.with): [from, until) in minutes of the game day (DayPlan.minute_of), or [] when
## that plan has none (wet days: in the house).
static func with_window(stage: String, plan_name: String, spouse_id: String) -> Array:
	var w: Variant = days_of(stage).get("with")
	if not w is Dictionary or stage != "child":
		return []
	var span: Variant = w.get("plans", {}).get(plan_name)
	if not span is Array or span.size() != 2:
		return []
	var from := str(w.get("join_at", {}).get(spouse_id, span[0])) if plan_name == "out" else str(span[0])
	return [DayPlan.minute_of(from), DayPlan.minute_of(str(span[1]))]


## Where the child stands off spouse `spouse_id` on map `map_id` while out with them
## (with.sides.<spouse>.<map>, else with.side).
static func side_of(spouse_id: String, map_id: String) -> Vector2:
	var w: Dictionary = days_of("child").get("with", {})
	var off: Variant = w.get("sides", {}).get(spouse_id, {}).get(map_id, w.get("side", [-1, 0]))
	return Vector2(float(off[0]), float(off[1])) if off is Array and off.size() == 2 else Vector2(-1, 0)


## The side to stand on off someone standing at `pos` on map `map_id`: `first` when that cell is
## free floor (in the map, not solid, not a door or a counter), else the first free of
## with.tries; `first` again when none is.
static func free_side(map_id: String, pos: Vector2, first: Vector2) -> Vector2:
	var m := MapManager.data(map_id)
	if m == null:
		return first
	var tries: Array = [[first.x, first.y]]
	tries.append_array(days_of("child").get("with", {}).get("tries", []))
	for off in tries:
		var v := Vector2(float(off[0]), float(off[1]))
		var c := Vector2i((pos + v).floor())
		if m.in_bounds(c) and not m.is_solid(c) and m.door_at(c).is_empty() and m.prop_at(c).get("kind", "") != "counter":
			return v
	return first


## Where the little one is at minute `t` of a day with plan `plan_name`: inside the time out
## with the spouse (with_window) and the spouse somewhere (`spouse`, as Villagers.where gives;
## not away), at their side wherever they are: on the home map by_spouse's offset, elsewhere
## side_of (or free_side's while they stand), turned to them, walking along while they walk. Otherwise by_spouse (at the spouse's
## side when both are at home, else the little one's own plan, `w`).
static func place(w: Dictionary, spouse: Dictionary, stage: String, t: float, spouse_id: String, plan_name: String) -> Dictionary:
	var win := with_window(stage, plan_name, spouse_id)
	var out_now: bool = not win.is_empty() and t >= float(win[0]) and t < float(win[1]) \
		and spouse.has("pos") and str(spouse.get("map", DayPlan.AWAY)) != DayPlan.AWAY
	if not out_now:
		return by_spouse(w, spouse, stage)
	var home := str(data().get("days", {}).get("home", "house"))
	if spouse.map == home:
		var at_home := w.duplicate()
		at_home.map = home
		if not at_home.has("pos"):
			at_home.pos = spouse.pos
		return by_spouse(at_home, spouse, stage)
	var out := w.duplicate()
	var v := side_of(spouse_id, str(spouse.map))
	if not spouse.get("moving", false):   # standing: on free floor beside them (not a wall, a door or a counter)
		v = free_side(str(spouse.map), spouse.pos, v)
	out.map = spouse.map
	out.pos = spouse.pos + v
	out.moving = spouse.get("moving", false)
	out.walked = spouse.get("walked", 0.0)
	out.facing = spouse.facing if out.moving else DayPlan.facing_of(-v)
	out.with_spouse = true
	return out


## The little one's colours (look) for the farmer's flags: the spouse's hair and the skin
## between, from the farmer's look now (FarmerLooks.current_look).
static func colours(flags: Dictionary) -> Dictionary:
	var spouse := Marriage.spouse(flags)
	return look(Villagers.look(spouse) if spouse != "" else {}, str(FarmerLooks.current_look().get("skin", "f2c79b")))


## The FigureArt body (crawler, toddler, child) and the cells per walk frame for `stage`.
static func figure(stage: String) -> Dictionary:
	var f: Variant = data().get("figures", {}).get(stage)
	return f if f is Dictionary else {"build": "toddler", "stride": 0.3}


## The hair style the little one wears at `stage` for the spouse's `style`: the stage's own
## figures.<stage>.styles first, then figures.styles.
static func small_style(style: String, stage := "") -> String:
	var own: Variant = figure(stage).get("styles", {}) if stage != "" else {}
	if own is Dictionary and own.has(style):
		return str(own[style])
	return str(data().get("figures", {}).get("styles", {}).get(style, style))


## The sprite key of the little one as Villagers.on_map gives them (with `stage` and `look`):
## child:figure:<build>:<style>:<skin>:<hair>:<top>:<front|back>:<idle|walk>:<frame>, the walk
## frame by the ground covered (figures.stride).
static func figure_key(w: Dictionary) -> String:
	var f := figure(str(w.get("stage", "toddler")))
	var c: Dictionary = w.get("look", {})
	var walking: bool = w.get("moving", false)
	var frame := int(float(w.get("walked", 0.0)) / maxf(float(f.get("stride", 0.3)), 0.05)) % 4 if walking else 0
	return "child:figure:%s:%s:%s:%s:%s:%d" % [str(f.get("build", "toddler")), small_style(str(c.get("hair_style", "short")), str(w.get("stage", "toddler"))),
		_colour_part(c), "back" if FarmerAnim.is_back(w.get("facing", Vector2i.DOWN)) else "front", "walk" if walking else "idle", frame]


## Does the little one take gifts at `stage`? From gifts_from on (the crawler only babbles).
static func takes_gifts(stage: String) -> bool:
	var ids := stage_ids()
	return stage in ids and ids.find(stage) >= ids.find(str(data().get("gifts_from", "toddler")))


## Dialogue `d` (the little one's talk file) with the name put into every line's `%s`, for
## Game.dialogue_made: the lines are translated as patterns, the name with them.
static func named_dialogue(d: Dictionary, name: String) -> Dictionary:
	var out := d.duplicate(true)
	for l in out.get("lines", []):
		if l is Dictionary and l.get("text") is String and "%s" in l.text:
			l.text = l.text.replace("%s", name)
	return out


# --- the child's morning help (step 5) -------------------------------------------------

## Set for the day the child pulled weeds this morning (the child's talk line).
const HELP_WEEDS := "help_weeds"


## The child's morning help (data/child.json help), after the night and the spouse's help:
## at help.stage, the child's heart band `band` at least help.band, today's `weather` in
## help.weather, up to help.weeds weeds in the field pulled (FarmGrid.pull_weeds). Returns how
## many (0: no child of that age, too few hearts, a wet day or no weeds).
static func help(flags: Dictionary, farm: FarmGrid, band: int, weather: String) -> int:
	flags.erase(HELP_WEEDS)
	var h: Dictionary = data().get("help", {})
	if farm == null or not is_born(flags) or str(flags.get(STAGE, "")) != str(h.get("stage", "child")):
		return 0
	if band < int(h.get("band", 5)) or not weather in h.get("weather", ["sunny"]):
		return 0
	var n := farm.pull_weeds(int(h.get("weeds", 0)))
	if n > 0:
		flags[HELP_WEEDS] = true
	return n


## What the farmer is told on stepping out ("" when nothing was pulled): help.messages one or
## more, with the child's name (and how many).
static func help_text(pulled: int, name: String) -> String:
	if pulled <= 0:
		return ""
	var m: Dictionary = data().get("help", {}).get("messages", {})
	return str(m.get("one", "%s")) % name if pulled == 1 else str(m.get("more", "%s %d")) % [name, pulled]


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
	for st in FIGURE_STAGES:
		if not str(figure(st).get("build", "")) in FigureArt.LITTLE_BUILDS or float(figure(st).get("stride", 0)) <= 0.0:
			return "figures.%s needs a build (%s) and a stride above 0" % [st, FigureArt.LITTLE_BUILDS]
	var days: Dictionary = d.get("days", {})
	if not MapManager.has(str(days.get("home", ""))):
		return "days.home is not a map"
	for st in ["crawler", "toddler", "child"]:
		var p: Variant = days.get(st)
		if not p is Dictionary or not p.get("plans") is Dictionary or not p.plans.has(p.get("default")):
			return "days.%s needs plans and a default plan" % st
		for name in p.plans:
			var r := DayPlan.build(p.plans[name], float(p.get("speed", 0)))
			if r[0] != "":
				return "days.%s plan %s: %s" % [st, name, r[0]]
		for rule in p.get("rules", []):
			if not rule is Dictionary or not rule.get("if") is Dictionary or not p.plans.has(rule.get("plan")):
				return "days.%s: a rule needs if {...} and a plan" % st
			var err := Villagers.check_conditions(rule.if)
			if err != "":
				return "days.%s: %s" % [st, err]
		var off: Variant = days.get("by_spouse", {}).get(st)
		if not off is Array or off.size() != 2:
			return "days.by_spouse.%s needs [x, y]" % st
	var with: Variant = days.get("child", {}).get("with")
	if not with is Dictionary or not with.get("plans") is Dictionary or not with.get("sides", {}) is Dictionary:
		return "days.child.with needs plans and sides"
	for name in with.plans:
		var span: Variant = with.plans[name]
		if not days.child.plans.has(name) or not span is Array or span.size() != 2 \
				or DayPlan.minute_of(span[0]) < 0 or DayPlan.minute_of(span[1]) <= DayPlan.minute_of(span[0]):
			return "days.child.with.plans.%s needs a plan of the child and [from, until] rising" % name
	for who in with.get("join_at", {}):
		if not Marriage.is_candidate(who) or DayPlan.minute_of(with.join_at[who]) < 0:
			return "days.child.with.join_at.%s needs a spouse and a time" % who
	for who in with.sides:
		if not Marriage.is_candidate(who) or not with.sides[who] is Dictionary:
			return "days.child.with.sides.%s needs a spouse and {map: [x, y]}" % who
		for m in with.sides[who]:
			var off: Variant = with.sides[who][m]
			if not MapManager.has(m) or not off is Array or off.size() != 2:
				return "days.child.with.sides.%s.%s needs a map and [x, y]" % [who, m]
	var hp: Variant = d.get("help")
	if not hp is Dictionary or not str(hp.get("stage", "")) in stage_ids() or not EventRunner._whole(hp.get("band", -1), 0, 6) \
			or not EventRunner._whole(hp.get("weeds", -1), 0, 99) or not hp.get("weather") is Array:
		return "help needs a stage, band 0 .. 6, weeds 0 .. 99 and a weather list"
	if not "%s" in str(hp.get("messages", {}).get("one", "")) or not "%d" in str(hp.get("messages", {}).get("more", "")):
		return "help.messages need one (%s) and more (%s, %d)"
	if not str(d.get("gifts_from", "")) in stage_ids():
		return "gifts_from is a stage"
	var gifts: Variant = d.get("gifts")
	if not gifts is Dictionary:
		return "gifts is {reaction: [items]}"
	for r in gifts:
		if r != "_about" and (not r in Villagers.REACTIONS or r == "neutral" or not EventTriggers._names_ok(gifts[r], [])):
			return "gifts %s needs a list of items" % r
	var seen := {}
	for who in d.get("names", {}):
		if not Marriage.is_candidate(who):
			return "names for %s, who cannot marry" % who
		for n in names(who):
			if seen.has(n):
				return "name %s is offered twice" % n
			seen[n] = true
	return ""
