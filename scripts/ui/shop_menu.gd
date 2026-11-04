class_name ShopMenu
extends RefCounted
## The shop screen's tabs, list and cursor, without any drawing (ShopScreen draws it,
## headless tests check it). The tabs come from what the shop does: "buy" (its stock this
## season, the next bigger rucksack and the kitchen tools not owned first), "tools" (upgrades), "sell" (carried things it
## buys) and "build" (house extensions). Up / down pick a row, left / right how many,
## choose() makes the deal through the game `g` (Game's shop_buy, shop_sell, shop_upgrade,
## shop_collect, shop_build) and returns its note.

const TAB_NAMES := {"buy": "Buy", "sell": "Sell", "tools": "Tools", "build": "Build"}
const MOST := 99            # most of one thing in one deal

var g                       # the Game (the autoload, or a test's)
var shop: Shop
var tabs: Array[String] = []
var tab := 0
var cursor := 0
var count := 1
var last_ok := false        # did the last choose() go through


func _init(game, shop_id: String) -> void:
	g = game
	shop = game.shop(shop_id)
	if not shop.stock_by_season.is_empty():
		tabs.append("buy")
	if shop.upgrades():
		tabs.append("tools")
	if not shop.buys.is_empty():
		tabs.append("sell")
	if not shop.builds.is_empty():
		tabs.append("build")


func tab_id() -> String:
	return tabs[tab] if tab < tabs.size() else ""


## The open tab's rows. buy: {item, price, to} (the rucksack row also level and slots);
## sell: {item, price, have}; tools: {item (the tool), level, state, price?, days?, items?,
## lack?, ready?} with state offer / short (materials missing from the rucksack, lack = how
## many more) / top (no next level) / missing (not in the tool slots) / away (at the forge) /
## ready (to collect) / busy (another tool is being worked on); build: Shop.build_offer.
func rows() -> Array[Dictionary]:
	match tab_id():
		"buy":
			var out: Array[Dictionary] = []
			var bag := shop.rucksack_offer(g.inventory.size("bag"))
			if not bag.is_empty():
				out.append(bag)
			out.append_array(shop.kitchen_offers(g.kitchen_tools, g.house_built))
			out.append_array(shop.stock(g.season_name()))
			return out
		"build":
			var out: Array[Dictionary] = []
			for id in shop.builds:
				out.append(shop.build_offer(id, g.house_built, g.house_job))
			return out
		"sell":
			return shop.sellable(g.inventory)
		"tools":
			var out: Array[Dictionary] = []
			var job: Dictionary = g.shop_jobs.get(shop.id, {})
			for tool in shop.upgrade_tools:
				var row := {"item": tool, "level": g.tool_level(tool)}
				if job.get("tool", "") == tool:
					row.state = "ready" if Shop.job_ready(job, g.day_number()) else "away"
					row.level = int(job.level)
					row.ready = int(job.ready)
				else:
					var offer := shop.upgrade_offer(tool, g.tool_level(tool))
					if offer.is_empty():
						row.state = "top"
					else:
						row.merge(offer, true)
						row.level = g.tool_level(tool)
						row.state = "busy" if not job.is_empty() else ("offer" if g.inventory.count(tool, ["tools"]) > 0 else "missing")
						row.lack = Shop.short_of(g.inventory, offer.items)
						if row.state == "offer" and not row.lack.is_empty():
							row.state = "short"   # the ores (or other materials) aren't in the rucksack
				out.append(row)
			return out
	return []


func current() -> Dictionary:
	var r := rows()
	return r[cursor] if cursor < r.size() else {}


## How many the cursor's row can go up to: what the money and the room (rucksack, coop)
## allow when buying, what is carried when selling; 1 for the rucksack, kitchen tools, tools
## and builds.
func most() -> int:
	var row := current()
	match tab_id():
		"buy":
			if row.get("item", "") == "rucksack" or row.get("to", "") == "kitchen":
				return 1
			var by_money: int = g.money / maxi(int(row.get("price", 1)), 1)
			return clampi(mini(by_money, g.shop_room(shop.id, str(row.get("item", "")))), 1, MOST)
		"sell":
			return clampi(int(row.get("have", 1)), 1, MOST)
	return 1


## The deal's price for the cursor's row and count (0 when there is none).
func total() -> int:
	return int(current().get("price", 0)) * (count if tab_id() in ["buy", "sell"] else 1)


func move(dy: int) -> void:
	var n := rows().size()
	if n > 0:
		cursor = posmod(cursor + dy, n)
	count = 1


## Left / right: one fewer / more, wrapping from 1 to the most and back.
func change_count(dx: int) -> void:
	var top := most()
	count = posmod(count - 1 + dx, top) + 1


func next_tab(step := 1) -> void:
	if tabs.size() > 0:
		tab = posmod(tab + step, tabs.size())
	cursor = 0
	count = 1


## Puts the cursor on row `i` of the open tab (the mouse). False when there is no such row.
func point(i: int) -> bool:
	if i < 0 or i >= rows().size():
		return false
	if i != cursor:
		cursor = i
		count = 1
	return true


## Enter: buys / sells `count` of the row, or hands the tool in / takes it back.
func choose() -> String:
	var row := current()
	last_ok = false
	if row.is_empty():
		return "Nothing to sell here." if tab_id() == "sell" else ""
	var r: Dictionary
	match tab_id():
		"buy":
			r = g.shop_buy(shop.id, row.item, count)
		"build":
			r = g.shop_build(shop.id, row.item)
		"sell":
			r = g.shop_sell(shop.id, row.item, count)
		"tools":
			match str(row.state):
				"ready", "away":
					r = g.shop_collect(shop.id)
				"top":
					return "The %s is as good as it gets." % shop.item_name(row.item).to_lower()
				_:
					r = g.shop_upgrade(shop.id, row.item)
	last_ok = bool(r.ok)
	# Rows can go (sold out of the rucksack); keep the cursor on the list.
	cursor = clampi(cursor, 0, maxi(rows().size() - 1, 0))
	count = mini(count, most())
	return str(r.note)
