class_name Animals
extends RefCounted
## The farm's animals and their homes (only the chicken coop so far). Pure rules, no drawing:
## Game owns one (Game.animals), calls hour_passed / day_end from the clock and saves it;
## the coop map and the farm view only read it and redraw on `changed`.
## Every number is in data/animals.json. DESIGN "สัตว์": happiness, feeding, grazing outside,
## produce grades by happiness, sickness and medicine; our numbers, and no deaths (DESIGN's
## advice: risks must be recoverable).
##
## An animal is {kind, name, happy, age, sick, sick_days, petted, out_hours}. Adults (age >=
## the kind's adult_days) lay. The feed box holds portions put in from the sack; each animal
## eats one at night unless it grazed outside long enough. Eggs lie in the nests until taken.

signal changed

const PATH := "res://data/animals.json"

static var _data := {}

var rules: Dictionary
var list: Array[Dictionary] = []
var outside := false          # the hens are out on the farm (the hatch is open)
var feed_stock := 0           # portions in the feed sack
var feed_box := 0             # portions in the feed box
var eggs: Array[String] = []  # egg items lying in the nests, oldest first
var incubator := {}           # {} or {item, days}: an egg warming towards a chick
var named := 0                # how many names were given (the next one is names[named])


## data/animals.json, read once.
static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = d if d is Dictionary else {}
	return _data


func _init(r := data()) -> void:
	rules = r


## A new game: the starting animals and a full feed sack.
func start() -> void:
	list.clear()
	eggs.clear()
	incubator = {}
	outside = false
	feed_box = 0
	named = 0
	feed_stock = int(home_rule("coop").get("feed_start", 0))
	for kind in rules.get("start", []):
		add(kind)


func kind_rule(kind: String) -> Dictionary:
	return rules.get("kinds", {}).get(kind, {})


func home_rule(home: String) -> Dictionary:
	return rules.get("homes", {}).get(home, {})


func _h(key: String) -> int:
	return int(rules.get("happiness", {}).get(key, 0))


func happy_max() -> int:
	return maxi(_h("max"), 1)


func is_adult(a: Dictionary) -> bool:
	return int(a.age) >= int(kind_rule(a.kind).get("adult_days", 0))


## A name for showing: a chick is "Mochi (chick)".
func label(a: Dictionary) -> String:
	return a.name if is_adult(a) else "%s (%s)" % [a.name, String(kind_rule(a.kind).get("chick_name", "young")).to_lower()]


## Places left in a home: its capacity less the animals there and an egg in the incubator.
func room(home := "coop") -> int:
	var used := 1 if incubator.size() > 0 and home == "coop" else 0
	for a in list:
		if kind_rule(a.kind).get("home", "") == home:
			used += 1
	return int(home_rule(home).get("capacity", 0)) - used


## The shop's hook (and the starting flock): one more animal of `kind`, grown up unless
## `young`. False when the kind is unknown or its home is full.
func add(kind: String, young := false) -> bool:
	var k := kind_rule(kind)
	if k.is_empty() or room(k.get("home", "")) <= 0:
		return false
	var names: Array = rules.get("names", [])
	var name: String = names[named % names.size()] if names.size() > 0 else kind.capitalize()
	named += 1
	list.append({"kind": kind, "name": name, "happy": int(k.get("happy_start", 0)),
		"age": 0 if young else int(k.get("adult_days", 0)), "sick": false, "sick_days": 0,
		"petted": false, "out_hours": 0})
	changed.emit()
	return true


## More portions in the feed sack (a shop sells them later).
func add_feed(n: int) -> void:
	feed_stock += maxi(n, 0)
	changed.emit()


# --- the day ----------------------------------------------------------------

func good_weather(weather: String) -> bool:
	return weather in rules.get("good_weather", ["sunny"])


## "" when the hens may go out now, else why not ("weather", "time", "none").
func why_not_out(weather: String, hour: int) -> String:
	var hours: Array = rules.get("out_hours", [6, 17])
	if list.is_empty():
		return "none"
	if not good_weather(weather):
		return "weather"
	if hour < int(hours[0]) or hour > int(hours[1]):
		return "time"
	return ""


## The hatch: opens (the hens go out) when why_not_out is "", or closes. Returns the reason
## it stayed shut ("" when it opened or closed).
func toggle_out(weather: String, hour: int) -> String:
	if outside:
		outside = false
		changed.emit()
		return ""
	var why := why_not_out(weather, hour)
	if why == "":
		outside = true
		changed.emit()
	return why


## Animals that are out on the farm now.
func out_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if outside:
		out.assign(list)
	return out


## An hour went by on the clock. Outside, good weather counts towards grazing; bad weather
## hurts every hour they are left out in it.
func hour_passed(weather: String) -> void:
	if not outside:
		return
	for a in list:
		if good_weather(weather):
			a.out_hours = int(a.out_hours) + 1
		else:
			a.happy = clampi(int(a.happy) + _h("bad_weather_hour"), 0, happy_max())
	changed.emit()


## Tops the feed box up from the sack: one portion per animal that hasn't one there yet.
## Returns how many portions went in (0: full already, or the sack is empty).
func fill_feed_box() -> int:
	var n := mini(maxi(list.size() - feed_box, 0), feed_stock)
	feed_stock -= n
	feed_box += n
	if n > 0:
		changed.emit()
	return n


## Strokes animal `i` (once a day counts). False when already petted today.
func pet(i: int) -> bool:
	if i < 0 or i >= list.size() or list[i].petted:
		return false
	list[i].petted = true
	changed.emit()
	return true


## Medicine cures a sick animal at once. False when it isn't sick.
func cure(i: int) -> bool:
	if i < 0 or i >= list.size() or not list[i].sick:
		return false
	list[i].sick = false
	list[i].sick_days = 0
	changed.emit()
	return true


## Takes the oldest egg from the nests ("" when there is none).
func take_egg() -> String:
	if eggs.is_empty():
		return ""
	var e: String = eggs.pop_front()
	changed.emit()
	return e


func is_egg(id: String) -> bool:
	for g in rules.get("products", {}).get("egg", {}).get("grades", []):
		if g.item == id:
			return true
	return false


## An egg into the incubator: it hatches into a chick after hatch_days nights. Needs an
## empty incubator and a free place in the coop.
func incubate(id: String) -> bool:
	if not is_egg(id) or incubator.size() > 0 or room("coop") <= 0:
		return false
	incubator = {"item": id, "days": 0}
	changed.emit()
	return true


## The product item for a happiness: the first grade whose `below` is over it.
func grade_for(product: String, happy: int) -> String:
	var grades: Array = rules.get("products", {}).get(product, {}).get("grades", [])
	for g in grades:
		if happy < int(g.below):
			return g.item
	return grades.back().item if grades.size() > 0 else ""


## The night: every animal eats (grazed outside or from the box), happiness moves, adults
## that ate and aren't sick lay, sickness comes or passes, everyone ages a day, the
## incubator warms. Returns news to tell the player ("Mochi is sick", "A chick hatched").
func day_end(weather: String, rng: RandomNumberGenerator) -> Array[String]:
	var news: Array[String] = []
	var sick_rule: Dictionary = rules.get("sickness", {})
	var grazing := maxi(_h("grazing_hours"), 1)
	var nests := int(home_rule("coop").get("capacity", 0))
	for a in list:
		var grazed := int(a.out_hours) >= grazing   # out_hours only grow outside in good weather
		var ate := grazed
		if not ate and feed_box > 0:
			feed_box -= 1
			ate = true
		var d := _h("fed") if ate else _h("unfed")
		if grazed:
			d += _h("sun")
		if a.petted:
			d += _h("petted")
		if outside:
			d += _h("left_out_night")
		if a.sick:
			d += _h("sick_day")
		a.happy = clampi(int(a.happy) + d, 0, happy_max())
		var lays := String(kind_rule(a.kind).get("lays", ""))
		if lays != "" and is_adult(a) and ate and not a.sick and eggs.size() < nests:
			eggs.append(grade_for(lays, a.happy))
		if a.sick:
			a.sick_days = int(a.sick_days) + 1
			if a.sick_days >= int(sick_rule.get("recover_days", 5)):
				a.sick = false
				a.sick_days = 0
				news.append("%s is well again" % a.name)
		else:
			var chance := 0.0
			if int(a.happy) <= int(sick_rule.get("below", 0)):
				chance += float(sick_rule.get("chance", 0.0))
			if not ate:
				chance += float(sick_rule.get("unfed_chance", 0.0))
			if chance > 0.0 and rng.randf() < chance:
				a.sick = true
				a.sick_days = 0
				news.append("%s looks sick" % a.name)
		var was_adult := is_adult(a)
		a.age = int(a.age) + 1
		if not was_adult and is_adult(a):
			news.append("%s has grown up" % a.name)
		a.petted = false
		a.out_hours = 0
	if outside:
		news.append("The hens were out all night")
	outside = false
	if incubator.size() > 0:
		incubator.days = int(incubator.days) + 1
		if incubator.days >= int(rules.get("incubator", {}).get("hatch_days", 3)):
			incubator = {}
			if add("chicken", true):
				news.append("A chick hatched: %s" % list.back().name)
	changed.emit()
	return news


# --- items ------------------------------------------------------------------

## Products and animal goods (eggs, medicine): {name, sell}, {} for anything else.
func item_info(id: String) -> Dictionary:
	return rules.get("items", {}).get(id, {})


func sell_price(id: String) -> int:
	return int(item_info(id).get("sell", 0))


# --- save -------------------------------------------------------------------

func to_dict() -> Dictionary:
	var animals := []
	for a in list:
		animals.append(a.duplicate())
	return {"animals": animals, "outside": outside, "feed_stock": feed_stock, "feed_box": feed_box,
		"eggs": eggs.duplicate(), "incubator": incubator.duplicate(), "named": named}


## [error, Animals] checked from saved data; nothing else changes.
static func parse(v: Variant, r := data()) -> Array:
	var out := Animals.new(r)
	if not v is Dictionary or not v.get("animals") is Array or not v.get("eggs") is Array \
			or not v.get("outside") is bool or not v.get("incubator") is Dictionary:
		return ["Saved animals are broken", null]
	var stock = SaveGame.whole(v.get("feed_stock"), 0, 1 << 30)
	var box = SaveGame.whole(v.get("feed_box"), 0, 1 << 30)
	var named_n = SaveGame.whole(v.get("named"), 0, 1 << 30)
	if stock == null or box == null or named_n == null:
		return ["Saved animal feed is broken", null]
	out.outside = v.outside
	out.feed_stock = stock
	out.feed_box = box
	out.named = named_n
	for s in v.animals:
		if not s is Dictionary or not s.get("kind") is String or out.kind_rule(s.kind).is_empty() \
				or not s.get("name") is String or not s.get("sick") is bool or not s.get("petted") is bool:
			return ["A saved animal is broken", null]
		var a := {"kind": s.kind, "name": s.name, "sick": s.sick, "petted": s.petted,
			"happy": SaveGame.whole(s.get("happy"), 0, out.happy_max()),
			"age": SaveGame.whole(s.get("age"), 0, 1 << 30),
			"sick_days": SaveGame.whole(s.get("sick_days"), 0, 1 << 30),
			"out_hours": SaveGame.whole(s.get("out_hours"), 0, 24)}
		if null in a.values():
			return ["A saved animal is broken", null]
		out.list.append(a)
	for e in v.eggs:
		if not e is String or not out.is_egg(e):
			return ["A saved egg is broken", null]
		out.eggs.append(e)
	if v.incubator.size() > 0:
		var days = SaveGame.whole(v.incubator.get("days"), 0, 1 << 30)
		if not out.is_egg(str(v.incubator.get("item", ""))) or days == null:
			return ["The saved incubator is broken", null]
		out.incubator = {"item": v.incubator.item, "days": days}
	if out.room("coop") < 0:
		return ["Too many saved animals for the coop", null]
	return ["", out]
