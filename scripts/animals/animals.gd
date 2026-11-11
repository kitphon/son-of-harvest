class_name Animals
extends RefCounted
## The farm's animals, their homes (the chicken coop and the barn) and the farm dog. Pure
## rules, no drawing: Game owns one (Game.animals), calls hour_passed / day_end from the clock
## and saves it; the coop / barn maps and the farm view only read it and redraw on `changed`.
## Every number is in data/animals.json. DESIGN "สัตว์": happiness, feeding, grazing outside,
## produce grades by happiness, brushing, sickness and medicine; our numbers. Nothing dies of
## neglect (DESIGN's advice: risks must be recoverable); only old age ends a life, gently and
## seen ahead (see Aging below).
##
## An animal is {kind, name, happy, age, sick, sick_days, petted, out_hours, brushed,
## prod_days, carrying, carry_days}. Adults (age >= the kind's adult_days) lay (hens) or give a product every few
## fed, healthy nights (cows: milk, sheep: wool; prod_days counts towards it). Each home has a
## feed box with portions put in from its stock (chicken feed / hay fodder) and a door to go
## out by; each animal eats one portion at night unless it grazed outside long enough. Eggs
## lie in the coop's nests until taken.
##
## Breeding (data/animals.json "breeding" and each kind's "breed"): the musubi cord tied on a
## happy, well, grown cow's or ewe's stall (breed) makes her carry for the kind's nights. She
## gives no milk or wool meanwhile; on the due night the calf or lamb is born in the barn if
## there is a free place, else she waits, night by night, until there is one.
##
## Aging (data/animals.json "aging" and each kind's bought_days / old_days / pass_days): `age`
## is the nights lived. From old_days the animal is old: "Kome (old)", and on a fed night its
## egg / milk / wool is skipped now and then (skip_chance). From pass_days[0] on it may pass
## away in its sleep, a chance each night that reaches 1 at pass_days[1]; the morning news says
## so and its place is free. A carrying mother waits until her young is born.
##
## The dog is {name, affection, petted, lifted, held, cell, facing}: always on the farm,
## stepped by dog_walk (the views call it), petted and picked up once a day each.

signal changed

const PATH := "res://data/animals.json"
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

static var _data := {}

var rules: Dictionary
var list: Array[Dictionary] = []
var state := {}               # home id -> {out, stock, box}: the door open, feed in stock, in the box
var eggs: Array[String] = []  # egg items lying in the nests, oldest first
var incubator := {}           # {} or {item, days}: an egg warming towards a chick
var named := 0                # how many names were given (the next one is names[named])
var dog := {}                 # the farm dog (see above)
var _dog_time := 0.0

## The coop's door, stock and box under their first names (the chickens came first).
var outside: bool:            # the hens are out on the farm (the hatch is open)
	get:
		return _st("coop").out
	set(v):
		_st("coop").out = v
var feed_stock: int:          # portions in the chicken feed sack
	get:
		return _st("coop").stock
	set(v):
		_st("coop").stock = v
var feed_box: int:            # portions in the coop's feed box
	get:
		return _st("coop").box
	set(v):
		_st("coop").box = v


## data/animals.json, read once.
static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = d if d is Dictionary else {}
	return _data


func _init(r := data()) -> void:
	rules = r
	for home in rules.get("homes", {}):
		_st(home)
	dog = new_dog()


func _st(home: String) -> Dictionary:
	if not state.has(home):
		state[home] = {"out": false, "stock": 0, "box": 0}
	return state[home]


## A new game: the starting animals, full feed stocks and the dog at home.
func start() -> void:
	list.clear()
	eggs.clear()
	incubator = {}
	named = 0
	state = {}
	for home in rules.get("homes", {}):
		_st(home).stock = int(home_rule(home).get("feed_start", 0))
	dog = new_dog()
	for kind in rules.get("start", []):
		add(kind)


func kind_rule(kind: String) -> Dictionary:
	return rules.get("kinds", {}).get(kind, {})


func home_rule(home: String) -> Dictionary:
	return rules.get("homes", {}).get(home, {})


func home_of(a: Dictionary) -> String:
	return String(kind_rule(a.kind).get("home", ""))


## Indices in `list` of the animals living in `home`, in the order they came.
func in_home(home: String) -> Array[int]:
	var out: Array[int] = []
	for i in list.size():
		if home_of(list[i]) == home:
			out.append(i)
	return out


## The home whose map is `map_id` ("" when none).
func home_on_map(map_id: String) -> String:
	for home in rules.get("homes", {}):
		if String(home_rule(home).get("map", home)) == map_id:
			return home
	return ""


func is_out(home: String) -> bool:
	return _st(home).out


func _h(key: String) -> int:
	return int(rules.get("happiness", {}).get(key, 0))


func happy_max() -> int:
	return maxi(_h("max"), 1)


func is_adult(a: Dictionary) -> bool:
	return int(a.age) >= int(kind_rule(a.kind).get("adult_days", 0))


## A name for showing: a chick is "Mochi (chick)", a calf "Momo (calf)", a cow carrying
## "Hana (in calf)", an old hen "Kome (old)".
func label(a: Dictionary) -> String:
	if a.get("carrying", false):
		return "%s (%s)" % [a.name, String(breed_rule(a.kind).get("carrying_name", "+"))]
	if is_old(a):
		return "%s (old)" % a.name
	return a.name if is_adult(a) else "%s (%s)" % [a.name, String(kind_rule(a.kind).get("young_name", "young")).to_lower()]


## The sprite kind for an animal: the young one's, a shorn sheep's, or the kind itself; a
## carrying cow or ewe adds data/animals.json breeding.sprite_suffix ("cow_carrying").
func look(a: Dictionary) -> String:
	var k := kind_rule(a.kind)
	if not is_adult(a):
		return String(k.get("young_sprite", a.kind))
	var sprite := String(a.kind)
	if k.has("shorn_sprite") and not _grown(a):
		sprite = String(k.shorn_sprite)
	if a.get("carrying", false):   # a carrying cow or ewe: her rounder picture until the birth
		sprite += String(breeding().get("sprite_suffix", ""))
	if is_old(a):   # a greying face from old_days on (data/animals.json aging.sprite_suffix)
		sprite += String(aging().get("sprite_suffix", ""))
	return sprite


## Where animal `i` stands in its home (the home's spots, in the order they came), or (-1, -1).
func spot(i: int) -> Vector2i:
	if i < 0 or i >= list.size():
		return Vector2i(-1, -1)
	var home := home_of(list[i])
	var spots: Array = home_rule(home).get("spots", [])
	var n := in_home(home).find(i)
	if n < 0 or n >= spots.size():
		return Vector2i(-1, -1)
	return Vector2i(int(spots[n][0]), int(spots[n][1]))


## The animal standing on `c` inside `home` (none while they are out), else -1.
func animal_at(home: String, c: Vector2i) -> int:
	if is_out(home):
		return -1
	for i in in_home(home):
		if spot(i) == c:
			return i
	return -1


## Places left in a home: its capacity less the animals there and an egg in the incubator.
func room(home := "coop") -> int:
	var used := 1 if incubator.size() > 0 and home == "coop" else 0
	return int(home_rule(home).get("capacity", 0)) - used - in_home(home).size()


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
		"age": 0 if young else bought_age(kind), "sick": false, "sick_days": 0,
		"petted": false, "out_hours": 0, "brushed": false, "prod_days": 0,
		"carrying": false, "carry_days": 0})
	changed.emit()
	return true


## More portions in a home's feed stock (a shop sells them): chicken feed for the coop.
func add_feed(n: int, home := "coop") -> void:
	_st(home).stock = int(_st(home).stock) + maxi(n, 0)
	changed.emit()


## The shop's fodder hook: hay bundles for the barn.
func add_fodder(n: int) -> void:
	add_feed(n, "barn")


## Portions left in a home's feed stock (the coop's sack, the barn's loft).
func stock_of(home := "coop") -> int:
	return int(_st(home).stock)


# --- the day ----------------------------------------------------------------

func good_weather(weather: String) -> bool:
	return weather in rules.get("good_weather", ["sunny"])


## "" when the animals of `home` may go out now, else why not ("weather", "time", "none").
func why_not_out(weather: String, hour: int, home := "coop") -> String:
	var hours: Array = rules.get("out_hours", [6, 17])
	if in_home(home).is_empty():
		return "none"
	if not good_weather(weather):
		return "weather"
	if hour < int(hours[0]) or hour > int(hours[1]):
		return "time"
	return ""


## The hatch / the barn gate: opens (the animals go out) when why_not_out is "", or closes.
## Returns the reason it stayed shut ("" when it opened or closed).
func toggle_out(weather: String, hour: int, home := "coop") -> String:
	if is_out(home):
		_st(home).out = false
		changed.emit()
		return ""
	var why := why_not_out(weather, hour, home)
	if why == "":
		_st(home).out = true
		changed.emit()
	return why


## Animals of `home` that are out on the farm now.
func out_list(home := "coop") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if is_out(home):
		for i in in_home(home):
			out.append(list[i])
	return out


## An hour went by on the clock. Outside, good weather counts towards grazing; bad weather
## hurts every hour they are left out in it.
func hour_passed(weather: String) -> void:
	var any := false
	for a in list:
		if not is_out(home_of(a)):
			continue
		any = true
		if good_weather(weather):
			a.out_hours = int(a.out_hours) + 1
		else:
			a.happy = clampi(int(a.happy) + _h("bad_weather_hour"), 0, happy_max())
	if any:
		changed.emit()


## Tops a home's feed box up from its stock: one portion per animal there that hasn't one in
## the box yet, at most `most`. Returns how many portions went in (0: full already, or the
## stock is empty).
func fill_feed_box(home := "coop", most := 1 << 30) -> int:
	var st := _st(home)
	var n := mini(mini(maxi(in_home(home).size() - int(st.box), 0), int(st.stock)), maxi(most, 0))
	st.stock = int(st.stock) - n
	st.box = int(st.box) + n
	if n > 0:
		changed.emit()
	return n


## Strokes / talks to animal `i` (once a day counts). False when already petted today.
func pet(i: int) -> bool:
	if i < 0 or i >= list.size() or list[i].petted:
		return false
	list[i].petted = true
	changed.emit()
	return true


func can_brush(a: Dictionary) -> bool:
	return bool(kind_rule(a.kind).get("brush", false))


## Brushes animal `i` (cows and sheep; once a day counts). False when it can't be brushed or
## was brushed today.
func brush(i: int) -> bool:
	if i < 0 or i >= list.size() or not can_brush(list[i]) or list[i].brushed:
		return false
	list[i].brushed = true
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


## {product, every, tool} of an animal that gives something (cows, sheep), else {}.
func gives(a: Dictionary) -> Dictionary:
	return kind_rule(a.kind).get("gives", {})


## Milk to take / wool to shear: grown, well, not carrying, and enough fed nights since the
## last time.
func product_ready(a: Dictionary) -> bool:
	return _grown(a) and not a.sick and not a.get("carrying", false)


## The product has grown back (enough fed nights): the sheep looks woolly again.
func _grown(a: Dictionary) -> bool:
	var g := gives(a)
	return not g.is_empty() and is_adult(a) and int(a.prod_days) >= maxi(int(g.get("every", 1)), 1)


## Milks / shears animal `i`: the product graded by its happiness now ("" when not ready).
func take_product(i: int) -> String:
	if i < 0 or i >= list.size() or not product_ready(list[i]):
		return ""
	var a: Dictionary = list[i]
	a.prod_days = 0
	changed.emit()
	return grade_for(String(gives(a).product), int(a.happy))


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


## The night: every animal eats (grazed outside or from its home's box), happiness moves,
## adults that ate and aren't sick lay or grow their product, sickness comes or passes,
## everyone ages a day, the very old may pass away in their sleep, the incubator warms, the
## dog goes home. Returns news to tell the player ("Mochi is sick", "A chick hatched").
func day_end(weather: String, rng: RandomNumberGenerator) -> Array[String]:
	var news: Array[String] = []
	var sick_rule: Dictionary = rules.get("sickness", {})
	var grazing := maxi(_h("grazing_hours"), 1)
	var nests := int(home_rule("coop").get("capacity", 0))
	for a in list:
		var st := _st(home_of(a))
		var grazed := int(a.out_hours) >= grazing   # out_hours only grow outside in good weather
		var ate := grazed
		if not ate and int(st.box) > 0:
			st.box = int(st.box) - 1
			ate = true
		var d := _h("fed") if ate else _h("unfed")
		if grazed:
			d += _h("sun")
		if a.petted:
			d += _h("petted")
		if a.brushed:
			d += _h("brushed")
		if st.out:
			d += _h("left_out_night")
		if a.sick:
			d += _h("sick_day")
		a.happy = clampi(int(a.happy) + d, 0, happy_max())
		var lays := String(kind_rule(a.kind).get("lays", ""))
		var thin := is_old(a) and rng.randf() < float(aging().get("skip_chance", 0.0))   # old: now and then nothing
		if lays != "" and is_adult(a) and ate and not a.sick and eggs.size() < nests and not thin:
			eggs.append(grade_for(lays, a.happy))
		var g := gives(a)
		if a.get("carrying", false):
			a.carry_days = mini(int(a.carry_days) + 1, carry_nights(a.kind))
		elif not g.is_empty() and is_adult(a) and ate and not a.sick and not thin:
			a.prod_days = mini(int(a.prod_days) + 1, maxi(int(g.get("every", 1)), 1))
		if a.sick:
			a.sick_days = int(a.sick_days) + 1
			if a.sick_days >= int(sick_rule.get("recover_days", 5)):
				a.sick = false
				a.sick_days = 0
				news.append("%s is well again." % a.name)
		else:
			var chance := 0.0
			if int(a.happy) <= int(sick_rule.get("below", 0)):
				chance += float(sick_rule.get("chance", 0.0))
			if not ate:
				chance += float(sick_rule.get("unfed_chance", 0.0))
			if chance > 0.0 and rng.randf() < chance:
				a.sick = true
				a.sick_days = 0
				news.append("%s looks sick." % a.name)
		var was_adult := is_adult(a)
		a.age = int(a.age) + 1
		if not was_adult and is_adult(a):
			news.append("%s has grown up." % a.name)
		a.petted = false
		a.brushed = false
		a.out_hours = 0
	for home in state:
		if state[home].out:
			news.append(String(home_rule(home).get("out_news", "The animals were out all night.")))
		state[home].out = false
	if incubator.size() > 0:
		incubator.days = int(incubator.days) + 1
		if incubator.days >= int(rules.get("incubator", {}).get("hatch_days", 3)):
			incubator = {}
			if add("chicken", true):
				news.append("A chick hatched: %s." % list.back().name)
	news.append_array(_passings(rng))   # before the births: a mother has her young first, and passes no sooner than the next night
	news.append_array(_births())
	_dog_night()
	changed.emit()
	return news


# --- breeding ---------------------------------------------------------------

## The breeding rules shared by every kind ({item, happy_min, born_happy}).
func breeding() -> Dictionary:
	return rules.get("breeding", {})


## The rucksack item that starts a pregnancy (the musubi cord).
func breed_item() -> String:
	return String(breeding().get("item", ""))


## A kind's own breeding rule ({carry_nights, carrying_name, born, waits}); {} for a kind that
## doesn't breed this way (the hens have the incubator).
func breed_rule(kind: String) -> Dictionary:
	return kind_rule(kind).get("breed", {})


func carry_nights(kind: String) -> int:
	return maxi(int(breed_rule(kind).get("carry_nights", 1)), 1)


## "" when animal `i` may carry now, else why not ("kind", "young", "sick", "carrying",
## "unhappy").
func why_not_breed(i: int) -> String:
	if i < 0 or i >= list.size() or breed_rule(list[i].kind).is_empty():
		return "kind"
	var a: Dictionary = list[i]
	if not is_adult(a):
		return "young"
	if a.sick:
		return "sick"
	if a.get("carrying", false):
		return "carrying"
	if int(a.happy) < int(breeding().get("happy_min", 0)):
		return "unhappy"
	return ""


## The cord tied on animal `i`'s stall: she carries from tonight. Returns why_not_breed.
func breed(i: int) -> String:
	var why := why_not_breed(i)
	if why == "":
		list[i].carrying = true
		list[i].carry_days = 0
		changed.emit()
	return why


## Nights until animal `a` is due (0: due, waiting for room), or -1 when not carrying.
func due_in(a: Dictionary) -> int:
	if not a.get("carrying", false):
		return -1
	return maxi(carry_nights(a.kind) - int(a.carry_days), 0)


## The night's births: every mother at her due night has her young in her home if it has a
## free place (named from the names list like any new animal), else she waits.
func _births() -> Array[String]:
	var news: Array[String] = []
	for i in list.size():   # the young are appended at the end, past the mothers looked at
		var a: Dictionary = list[i]
		if not a.get("carrying", false) or due_in(a) > 0:
			continue
		var b := breed_rule(a.kind)
		if not add(a.kind, true):
			news.append(String(b.get("waits", "%s")) % a.name)
			continue
		var young: Dictionary = list.back()
		young.happy = mini(int(young.happy) + int(breeding().get("born_happy", 0)), happy_max())
		a.carrying = false
		a.carry_days = 0
		news.append(String(b.get("born", "%s: %s")) % [a.name, young.name])
	return news


# --- aging ------------------------------------------------------------------

## The aging rules shared by every kind ({skip_chance, passed, age_lines, ...}).
func aging() -> Dictionary:
	return rules.get("aging", {})


## A bought (or starting) animal's age: its kind's bought_days, and grown up in any case.
func bought_age(kind: String) -> int:
	var k := kind_rule(kind)
	return maxi(int(k.get("bought_days", 0)), int(k.get("adult_days", 0)))


## From the kind's old_days on (never for a kind without one).
func is_old(a: Dictionary) -> bool:
	var k := kind_rule(a.kind)
	return k.has("old_days") and int(a.get("age", 0)) >= int(k.old_days)


## [first, last] night of a kind's lifespan, or [] for a kind that doesn't pass away.
func pass_days(kind: String) -> Array[int]:
	var p: Array = kind_rule(kind).get("pass_days", [])
	if p.size() != 2:
		return []
	return [int(p[0]), maxi(int(p[1]), int(p[0]))]


## Tonight's chance that animal `a` passes away: 0 before pass_days[0] (and while she carries),
## then 1 / (nights left to pass_days[1] + 1), so the night falls evenly over the range and is
## sure at the end of it.
func pass_chance(a: Dictionary) -> float:
	var p := pass_days(a.kind)
	if p.is_empty() or int(a.age) < p[0] or a.get("carrying", false):
		return 0.0
	return 1.0 / float(maxi(p[1] - int(a.age), 0) + 1)


## The night's peaceful passings (after the night's aging, before the births): each animal
## past its first night rolls pass_chance; those that go leave the list and free their place.
func _passings(rng: RandomNumberGenerator) -> Array[String]:
	var news: Array[String] = []
	var i := 0
	while i < list.size():
		var chance := pass_chance(list[i])
		if chance > 0.0 and rng.randf() < chance:
			news.append(String(aging().get("passed", "%s")) % list[i].name)
			list.remove_at(i)
		else:
			i += 1
	return news


## What E on an animal says about its age: "Kome is 2 years and a season old.", in days
## under a season ("Mochi is 5 days old."). One whole sentence per case (aging.age_lines).
func age_text(a: Dictionary) -> String:
	var r := aging()
	var lines: Dictionary = r.get("age_lines", {})
	var season := maxi(int(r.get("season_days", 30)), 1)
	var year := season * maxi(int(r.get("seasons", 4)), 1)
	var age := maxi(int(a.get("age", 0)), 0)
	var y := age / year
	var s := (age % year) / season
	var key := ""
	var nums := []
	if age == 0:
		key = "new"
	elif age < season:
		key = "day" if age == 1 else "days"
		nums = [] if age == 1 else [age]
	elif y == 0:
		key = "season" if s == 1 else "seasons"
		nums = [] if s == 1 else [s]
	else:
		key = "year" if y == 1 else "years"
		if y > 1:
			nums.append(y)
		if s > 0:
			key += "_season" if s == 1 else "_seasons"
			if s > 1:
				nums.append(s)
	if not lines.has(key):
		return ""
	return String(lines[key]) % ([a.name] + nums)


# --- the dog ----------------------------------------------------------------

func dog_rule() -> Dictionary:
	return rules.get("dog", {})


func _dog_home() -> Vector2i:
	var h: Array = dog_rule().get("home", [1, 5])
	return Vector2i(int(h[0]), int(h[1]))


func new_dog() -> Dictionary:
	var r := dog_rule()
	return {"name": String(r.get("name", "Dog")), "affection": int(r.get("affection_start", 0)),
		"petted": false, "lifted": false, "held": false, "cell": _dog_home(), "facing": Vector2i.DOWN,
		"age": int(r.get("start_days", 0))}


## The dog is old from data/animals.json dog.old_days on (it never passes away).
func dog_old() -> bool:
	var r := dog_rule()
	return r.has("old_days") and int(dog.get("age", 0)) >= int(r.old_days)


## The dog's sprite kind: "dog", or with aging.sprite_suffix once old ("dog_old").
func dog_look() -> String:
	return "dog" + (String(aging().get("sprite_suffix", "")) if dog_old() else "")


func _dog_add(key: String) -> void:
	dog.affection = clampi(int(dog.affection) + int(dog_rule().get(key, 0)), 0, maxi(int(dog_rule().get("max", 100)), 1))


## Petting the dog (once a day counts). False when already petted today.
func dog_pet() -> bool:
	if dog.petted:
		return false
	dog.petted = true
	_dog_add("petted")
	changed.emit()
	return true


## Picks the dog up (held overhead); once a day it counts for affection. False when held.
func dog_lift() -> bool:
	if dog.held:
		return false
	dog.held = true
	if not dog.lifted:
		dog.lifted = true
		_dog_add("lifted")
	changed.emit()
	return true


## Sets the dog down on `c`.
func dog_put(c: Vector2i) -> void:
	dog.held = false
	dog.cell = c
	changed.emit()


func dog_follows() -> bool:
	return int(dog.affection) >= int(dog_rule().get("follow_affection", 0))


## One step for the dog: towards the farmer on `farmer` once fond enough and not too far
## (stopping a little way off), else now and then a step about its home. `free` says whether
## a farm cell can be walked on. Returns whether it moved.
func dog_step(farmer: Vector2i, free: Callable, rng: RandomNumberGenerator) -> bool:
	if dog.held:
		return false
	var r := dog_rule()
	var at: Vector2i = dog.cell
	var d := farmer - at
	var dist := absi(d.x) + absi(d.y)
	var tries: Array[Vector2i] = []
	if dog_follows() and dist > int(r.get("follow_from", 2)) and dist <= int(r.get("follow_range", 8)):
		tries = [Vector2i(signi(d.x), 0), Vector2i(0, signi(d.y))]
		if absi(d.y) > absi(d.x):
			tries.reverse()
	elif rng.randf() < float(r.get("wander_chance", 0.3)):
		var dir := DIRS[rng.randi() % DIRS.size()]
		var home := _dog_home()
		var off := at + dir - home
		if absi(off.x) + absi(off.y) <= int(r.get("wander_range", 4)) or absi(off.x) + absi(off.y) < absi(at.x - home.x) + absi(at.y - home.y):
			tries = [dir]
	for s in tries:
		if s != Vector2i.ZERO and at + s != farmer and free.call(at + s):
			dog.cell = at + s
			dog.facing = s
			return true
	return false


## The view's clock for the dog: steps every step_seconds while the farmer is on the farm.
func dog_walk(delta: float, farmer: Vector2i, free: Callable, rng: RandomNumberGenerator) -> void:
	_dog_time += delta
	var every := maxf(float(dog_rule().get("step_seconds", 0.3)), 0.05)
	if dog_old():
		every *= maxf(float(dog_rule().get("old_step", 1.0)), 1.0)
	while _dog_time >= every:
		_dog_time -= every
		dog_step(farmer, free, rng)


func _dog_night() -> void:
	if not dog.petted and not dog.lifted:
		_dog_add("ignored")
	dog.petted = false
	dog.lifted = false
	dog.held = false
	dog.age = int(dog.get("age", 0)) + 1
	dog.cell = _dog_home()
	dog.facing = Vector2i.DOWN


# --- items ------------------------------------------------------------------

## Products and animal goods (eggs, milk, wool, medicine): {name, sell}, {} for anything else.
func item_info(id: String) -> Dictionary:
	return rules.get("items", {}).get(id, {})


func sell_price(id: String) -> int:
	return int(item_info(id).get("sell", 0))


# --- save -------------------------------------------------------------------

func to_dict() -> Dictionary:
	var animals := []
	for a in list:
		animals.append(a.duplicate())
	var barn := _st("barn")
	return {"animals": animals, "outside": outside, "feed_stock": feed_stock, "feed_box": feed_box,
		"eggs": eggs.duplicate(), "incubator": incubator.duplicate(), "named": named,
		"barn": {"out": barn.out, "stock": barn.stock, "box": barn.box},
		"dog": {"name": dog.name, "affection": dog.affection, "petted": dog.petted, "lifted": dog.lifted,
			"cell": [dog.cell.x, dog.cell.y], "age": int(dog.get("age", 0))}}


## [error, Animals] checked from saved data; nothing else changes. Saves from before version 4
## (the barn and the dog) get the new-game fodder and dog.
static func parse(v: Variant, r := data(), version := SaveGame.VERSION) -> Array:
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
	var new_barn := {"out": false, "stock": int(out.home_rule("barn").get("feed_start", 0)), "box": 0}
	var barn = v.get("barn", new_barn if version < 4 else null)
	if not barn is Dictionary or not barn.get("out") is bool:
		return ["The saved barn is broken", null]
	var barn_stock = SaveGame.whole(barn.get("stock"), 0, 1 << 30)
	var barn_box = SaveGame.whole(barn.get("box"), 0, 1 << 30)
	if barn_stock == null or barn_box == null:
		return ["Saved barn fodder is broken", null]
	out.state["barn"] = {"out": barn.out, "stock": barn_stock, "box": barn_box}
	for s in v.animals:
		if not s is Dictionary or not s.get("kind") is String or out.kind_rule(s.kind).is_empty() \
				or not s.get("name") is String or not s.get("sick") is bool or not s.get("petted") is bool \
				or not s.get("brushed", false) is bool or not s.get("carrying", false) is bool:
			return ["A saved animal is broken", null]
		var a := {"kind": s.kind, "name": s.name, "sick": s.sick, "petted": s.petted,
			"brushed": s.get("brushed", false),
			"happy": SaveGame.whole(s.get("happy"), 0, out.happy_max()),
			"age": SaveGame.whole(s.get("age", out.bought_age(s.kind)), 0, 1 << 30),   # none saved: as if just bought
			"sick_days": SaveGame.whole(s.get("sick_days"), 0, 1 << 30),
			"out_hours": SaveGame.whole(s.get("out_hours"), 0, 24),
			"prod_days": SaveGame.whole(s.get("prod_days", 0), 0, 1 << 30),
			"carrying": s.get("carrying", false),
			"carry_days": SaveGame.whole(s.get("carry_days", 0), 0, 1 << 30)}
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
	for home in out.rules.get("homes", {}):
		if out.room(home) < 0:
			return ["Too many saved animals for the %s" % home, null]
	var sd = v.get("dog", out.dog.duplicate() if version < 4 else null)
	if version < 4 and not v.has("dog"):
		sd.cell = [out.dog.cell.x, out.dog.cell.y]
	if not sd is Dictionary or not sd.get("name") is String or not sd.get("petted") is bool \
			or not sd.get("lifted") is bool or not sd.get("cell") is Array or sd.cell.size() != 2:
		return ["The saved dog is broken", null]
	var aff = SaveGame.whole(sd.get("affection"), 0, maxi(int(out.dog_rule().get("max", 100)), 1))
	var cx = SaveGame.whole(sd.cell[0], 1, FarmGrid.W - 2)
	var cy = SaveGame.whole(sd.cell[1], 1, FarmGrid.H - 2)
	var dage = SaveGame.whole(sd.get("age", int(out.dog_rule().get("start_days", 0))), 0, 1 << 30)   # a save from before: a year old
	if aff == null or cx == null or cy == null or dage == null:
		return ["The saved dog is broken", null]
	out.dog = {"name": sd.name, "affection": aff, "petted": sd.petted, "lifted": sd.lifted,
		"held": false, "cell": Vector2i(cx, cy), "facing": Vector2i.DOWN, "age": dage}
	return ["", out]
