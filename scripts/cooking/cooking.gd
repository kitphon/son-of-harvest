class_name Cooking
extends RefCounted
## Home cooking at the kitchen corner, without any drawing (CookingMenu lists it, Game.cook
## runs it, headless tests check it). Recipes are data/recipes.json: a recipe's id is the dish
## it makes (a food in data/foods.json, so "food:<id>" goes into the rucksack), its needs are
## items or groups of items. Ingredients come out of the rucksack, the hand and then the
## storage chest (PLACES); the kitchen's pantry (rice, miso, soy) is never counted. A recipe is
## known from the start or once its flag recipe_<id> is set (Game.flags, saved).

const DATA := "res://data/recipes.json"
const PLACES: Array[String] = ["bag", "hand", "chest"]
const FLAG_PREFIX := "recipe_"

static var _data := {}


## data/recipes.json, read once.
static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_data = d if d is Dictionary else {}
	return _data


## Recipe ids in data order.
static func ids(d := data()) -> Array[String]:
	var out: Array[String] = []
	out.assign(d.get("recipes", {}).keys())
	return out


static func recipe(id: String, d := data()) -> Dictionary:
	return d.get("recipes", {}).get(id, {})


## The flag that teaches recipe `id`.
static func flag(id: String) -> String:
	return FLAG_PREFIX + id


static func known(id: String, flags: Dictionary, d := data()) -> bool:
	var r := recipe(id, d)
	return not r.is_empty() and (bool(r.get("start", false)) or EventRunner.is_set(flags, flag(id)))


static func known_ids(flags: Dictionary, d := data()) -> Array[String]:
	return ids(d).filter(func(id: String) -> bool: return known(id, flags, d))


## The recipes whose card (recipes.json card) comes with the first `item` shipped.
static func cards(item: String, d := data()) -> Array[String]:
	return ids(d).filter(func(id: String) -> bool: return String(recipe(id, d).get("card", "")) == item)


## The rucksack item a cooking of `id` gives, and how many.
static func dish(id: String) -> String:
	return "food:" + id


static func makes(id: String, d := data()) -> int:
	return maxi(int(recipe(id, d).get("makes", 1)), 1)


## Does `item` fill the need `need` ({item, n} or {group, n})?
static func fits(need: Dictionary, item: String, d := data()) -> bool:
	if need.has("item"):
		return item == need.item
	var g: Dictionary = d.get("groups", {}).get(need.get("group", ""), {})
	if g.has("prefix"):
		return item.begins_with(String(g.prefix))
	return item in g.get("items", [])


## The ids in `places` of `inv` that fill `need`, in the order they are used up: a group's
## own order (plain eggs before golden ones), prefix groups in slot order.
static func candidates(need: Dictionary, inv: Inventory, places: Array = PLACES, d := data()) -> Array[String]:
	var found: Array[String] = []
	for place in places:
		for s in inv.slots.get(place, []):
			var id := String(s.get("id", ""))
			if id != "" and not id in found and fits(need, id, d):
				found.append(id)
	var g: Dictionary = d.get("groups", {}).get(need.get("group", ""), {})
	if g.has("items"):
		var order: Array = g.items
		found.sort_custom(func(a: String, b: String) -> bool: return order.find(a) < order.find(b))
	return found


## How many of `need` the farmer has to cook with.
static func have(need: Dictionary, inv: Inventory, places: Array = PLACES, d := data()) -> int:
	var n := 0
	for id in candidates(need, inv, places, d):
		n += inv.count(id, places)
	return n


## The needs of `id` not met now ([] = it can be cooked, ingredients-wise).
static func missing(id: String, inv: Inventory, places: Array = PLACES, d := data()) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for need in recipe(id, d).get("needs", []):
		if have(need, inv, places, d) < int(need.n):
			out.append(need)
	return out


## Cooks `id` once in `inv`: takes the needs (one need's items before the next, so a turnip
## taken for one need is gone for the next), then puts the dishes in the rucksack. Tried on a
## copy first, so on "missing" or "full" nothing changes. Returns {result: "cooked" /
## "unknown" / "missing" / "full", used: {item id: n}}.
static func cook(id: String, inv: Inventory, places: Array = PLACES, d := data()) -> Dictionary:
	var r := recipe(id, d)
	if r.is_empty():
		return {"result": "unknown", "used": {}}
	var trial := Inventory.new()
	trial.tool_ids = inv.tool_ids
	trial.stack_max = inv.stack_max
	trial.slots = inv.slots.duplicate(true)
	var used := {}
	for need in r.get("needs", []):
		var left := int(need.n)
		for item in candidates(need, trial, places, d):
			var take := mini(left, trial.count(item, places))
			if take > 0:
				trial.take(item, take, places)
				used[item] = int(used.get(item, 0)) + take
				left -= take
		if left > 0:
			return {"result": "missing", "used": {}}
	if trial.add(dish(id), makes(id, d)) > 0:
		return {"result": "full", "used": {}}
	inv.slots = trial.slots
	return {"result": "cooked", "used": used}


## "" when `d` is usable with these foods (foods.json "foods"), else what is wrong.
static func check(d: Dictionary, foods: Dictionary) -> String:
	var groups: Dictionary = d.get("groups", {})
	for g in groups:
		var gd = groups[g]
		if not gd is Dictionary or not (gd.get("items") is Array or gd.get("prefix") is String):
			return "group %s needs items or a prefix" % g
	var rs = d.get("recipes")
	if not rs is Dictionary or rs.is_empty():
		return "no recipes"
	for id in rs:
		var r = rs[id]
		if not foods.has(id):
			return "%s: no food %s in foods.json" % [id, id]
		if not r is Dictionary or not r.get("needs") is Array or r.needs.is_empty():
			return "%s needs needs" % id
		for need in r.needs:
			if not need is Dictionary or int(need.get("n", 0)) < 1 or need.has("item") == need.has("group"):
				return "%s: a need is {item, n} or {group, n}" % id
			if need.has("group") and not groups.has(need.group):
				return "%s: no group %s" % [id, need.group]
	return ""
