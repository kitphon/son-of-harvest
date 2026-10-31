class_name Shop
extends RefCounted
## One shop from data/shops.json and its rules, without any drawing (ShopMenu / ShopScreen
## show it, Game applies the results, headless tests check it): opening hours and days off,
## the stock per season with prices, buying into and selling from an Inventory, and tool
## upgrades that take a tool away for some days. Every action gets the inventory and the
## money it may change and returns {ok, money, note}; nothing here touches Game.

const DATA := "res://data/shops.json"
const DAY_NAMES := {"mon": "Mon", "tue": "Tue", "wed": "Wed", "thu": "Thu", "fri": "Fri", "sat": "Sat", "sun": "Sun"}

var id := ""
var name := ""
var map := ""                       # the inside (data/maps/<map>.json)
var open_hour := 0
var close_hour := 24
var days_off: Array[String] = []
var keeper := ""                    # the villager at the counter; "" = the counter works alone
var stock_by_season: Dictionary = {}   # season or "any" -> [{item, price?}]
var buys: Dictionary = {}           # kind (crop, food) -> percent of the item's value
var upgrade_tools: Array[String] = []
var upgrade_levels: Dictionary = {}    # "2".."5" -> {price, days, items?}
var crops: Dictionary = {}
var foods: Dictionary = {}

static var _data := {}


## data/shops.json, read once.
static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_data = d if d is Dictionary else {}
	return _data


static func ids(d := data()) -> Array[String]:
	var out: Array[String] = []
	out.assign(d.get("shops", {}).keys())
	return out


## The shop `shop_id` from `d`, or null when there is none. `crop_data` / `food_data` give
## the items' own prices and names (crops.json, foods.json "foods").
static func make(shop_id: String, crop_data: Dictionary, food_data: Dictionary, d := data()) -> Shop:
	var s = d.get("shops", {}).get(shop_id)
	if not s is Dictionary:
		return null
	var shop := Shop.new()
	shop.id = shop_id
	shop.name = str(s.get("name", shop_id))
	shop.map = str(s.get("map", ""))
	var hours: Array = s.get("open", [0, 24])
	shop.open_hour = int(hours[0])
	shop.close_hour = int(hours[1])
	shop.days_off.assign(s.get("days_off", []))
	shop.keeper = str(s.get("keeper", ""))
	shop.stock_by_season = s.get("stock", {})
	shop.buys = s.get("buys", {})
	shop.upgrade_tools.assign(s.get("upgrades", {}).get("tools", []))
	shop.upgrade_levels = s.get("upgrades", {}).get("levels", {})
	shop.crops = crop_data
	shop.foods = food_data
	return shop


# --- hours ------------------------------------------------------------------

func is_open(hour: int, weekday: String) -> bool:
	return hour >= open_hour and hour < close_hour and not weekday in days_off


## "9:00-17:00" and "closed Sun" (or "open every day").
func hours_text() -> String:
	return "%d:00-%d:00" % [open_hour, close_hour]


func days_off_text() -> String:
	if days_off.is_empty():
		return "open every day"
	var names: Array[String] = []
	for day in days_off:
		names.append(DAY_NAMES.get(day, day))
	return "closed " + ", ".join(names)


## What the door and the counter say while it is shut.
func closed_text(d := data()) -> String:
	return str(d.get("closed_message", "%s is closed. Open %s, %s.")) % [name, hours_text(), days_off_text()]


# --- items and prices --------------------------------------------------------

## A name for an item the shop deals in (seed bags, food, crops, tools).
func item_name(item: String) -> String:
	if item.begins_with("seeds:") and crops.has(item.trim_prefix("seeds:")):
		return "%s seeds" % crops[item.trim_prefix("seeds:")].name
	if item.begins_with("food:") and foods.has(item.trim_prefix("food:")):
		return str(foods[item.trim_prefix("food:")].name)
	if crops.has(item):
		return str(crops[item].name)
	if HudLayout.TOOL_NAMES.has(item):
		return HudLayout.TOOL_NAMES[item]
	return item.replace(":", " ").replace("_", " ").capitalize()


## The item's own price: a seed bag's seed_price, a food's price; 0 when it has none.
func base_price(item: String) -> int:
	if item.begins_with("seeds:"):
		return int(crops.get(item.trim_prefix("seeds:"), {}).get("seed_price", 0))
	if item.begins_with("food:"):
		return int(foods.get(item.trim_prefix("food:"), {}).get("price", 0))
	return 0


## What is for sale in `season`: [{item, price}], that season's goods first, then "any".
func stock(season: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key in [season, "any"]:
		for e in stock_by_season.get(key, []):
			var p := int(e.get("price", base_price(e.item)))
			if p > 0:
				out.append({"item": str(e.item), "price": p})
	return out


## The price of `item` here in `season`, -1 when it isn't sold then.
func price(item: String, season: String) -> int:
	for e in stock(season):
		if e.item == item:
			return e.price
	return -1


## What the shop pays for one `item` (0 = it doesn't buy it): a percent of a crop's sell
## price or a food's price, rounded down.
func buy_back(item: String) -> int:
	if crops.has(item) and buys.has("crop"):
		return int(crops[item].get("sell", 0)) * int(buys.crop) / 100
	if item.begins_with("food:") and buys.has("food"):
		return base_price(item) * int(buys.food) / 100
	return 0


## Buys `n` of `item` into the rucksack: it must be in stock this season, paid in full and
## fit in the bag (all or nothing).
func buy(inv: Inventory, money: int, item: String, n: int, season: String) -> Dictionary:
	var p := price(item, season)
	if p < 0 or n < 1:
		return _no(money, "That isn't sold in %s" % season)
	if money < p * n:
		return _no(money, "Not enough money (%d G)" % (p * n))
	if inv.room_for(item) < n:
		return _no(money, "Your rucksack is full")
	inv.add(item, n)
	var what := item_name(item) if n == 1 else "%d %s" % [n, item_name(item)]
	return {"ok": true, "money": money - p * n, "note": "Bought %s for %d G" % [what, p * n]}


## Sells `n` of `item` from what the farmer carries (rucksack and hand).
func sell(inv: Inventory, money: int, item: String, n: int) -> Dictionary:
	var p := buy_back(item)
	if p <= 0:
		return _no(money, "%s doesn't buy that" % name)
	if n < 1 or not inv.take(item, n):
		return _no(money, "You don't have that many")
	var what := item_name(item) if n == 1 else "%d %s" % [n, item_name(item)]
	return {"ok": true, "money": money + p * n, "note": "Sold %s for %d G" % [what, p * n]}


## Carried items the shop buys: [{item, price, have}], in rucksack order.
func sellable(inv: Inventory) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var t := inv.totals()
	for item in t:
		if buy_back(item) > 0:
			out.append({"item": item, "price": buy_back(item), "have": int(t[item])})
	return out


# --- tool upgrades -----------------------------------------------------------

func upgrades() -> bool:
	return not upgrade_tools.is_empty()


## The deal to take `tool` from `level` to the next: {level, price, days, items}; {} when this
## shop doesn't work on the tool or the next level has no entry (top level).
func upgrade_offer(tool: String, level: int) -> Dictionary:
	var e = upgrade_levels.get(str(level + 1))
	if not tool in upgrade_tools or not e is Dictionary:
		return {}
	return {"level": level + 1, "price": int(e.get("price", 0)), "days": maxi(int(e.get("days", 1)), 0),
		"items": e.get("items", {})}


## Hands `tool` (at `level`, in a tool slot) in for an upgrade on day `today`. One job at a
## time; the price and any materials are paid now. The result also has the job:
## {tool, level (the new one), ready (day number), slot (where the tool was)}.
func start_upgrade(inv: Inventory, money: int, tool: String, level: int, today: int, busy := false) -> Dictionary:
	var offer := upgrade_offer(tool, level)
	if busy:
		return _no(money, "One tool at a time, please")
	if offer.is_empty():
		return _no(money, "The %s can't be improved any more" % item_name(tool).to_lower())
	if money < offer.price:
		return _no(money, "Not enough money (%d G)" % offer.price)
	for item in offer.items:
		if inv.count(item) < int(offer.items[item]):
			return _no(money, "Bring %d %s" % [int(offer.items[item]), item_name(item)])
	var slot := -1
	for i in inv.size("tools"):
		if inv.id_at("tools", i) == tool:
			slot = i
	if slot < 0:
		return _no(money, "Bring the %s in your rucksack" % item_name(tool).to_lower())
	for item in offer.items:
		inv.take(item, int(offer.items[item]))
	inv.lift("tools", slot)
	var r := {"ok": true, "money": money - offer.price,
		"job": {"tool": tool, "level": offer.level, "ready": today + offer.days, "slot": slot}}
	var days := "tomorrow" if offer.days == 1 else "in %d days" % offer.days
	r.note = "Left the %s for %d G. Ready %s." % [item_name(tool).to_lower(), offer.price, days]
	if offer.days == 0:
		r.note = "Left the %s for %d G. Ready now." % [item_name(tool).to_lower(), offer.price]
	return r


static func job_ready(job: Dictionary, today: int) -> bool:
	return not job.is_empty() and today >= int(job.ready)


## Gives a finished tool back: into its old tool slot when that is free, else any tool slot,
## else the chest. The caller raises its level (Game.raise_tool_level).
static func give_back(inv: Inventory, job: Dictionary) -> String:
	var rest := inv.stow({"id": job.tool, "n": 1}, "tools", int(job.slot), ["tools", "chest"])
	if not rest.is_empty():
		inv.grow("chest", inv.size("chest") + 1)
		inv.add(job.tool, 1, ["chest"])
		return "chest"
	for i in inv.size("tools"):
		if inv.id_at("tools", i) == job.tool:
			return "tools"
	return "chest"


func _no(money: int, note: String) -> Dictionary:
	return {"ok": false, "money": money, "note": note}
