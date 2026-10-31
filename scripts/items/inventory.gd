class_name Inventory
extends RefCounted
## Where the farmer's things are, without any drawing (Game keeps one, InventoryMenu moves
## things around in it, headless tests check it). Places: "tools" (the rucksack's tool slots,
## the HUD tool bar), "bag" (the rucksack's item slots), "hand" (the item held in the other
## hand, one slot) and "chest" (the storage chest by the house). A slot is {} (empty) or
## {"id": String, "n": int}. Tools go in tool slots and the chest; every other id goes in the
## bag, the hand and the chest, whatever it is (crops, seeds, food, ...). Same ids stack up to
## stack_max, tools never stack. Slot counts and the starting things are in
## data/inventory.json; a bigger rucksack later is grow("bag", n).

const DATA := "res://data/inventory.json"
const PLACES: Array[String] = ["tools", "bag", "hand", "chest"]
const CARRIED: Array[String] = ["bag", "hand"]   # what the farmer has on them (counts, shipping)

var slots := {}                 # place -> Array of slots
var tool_ids: Array[String] = []
var stack_max := 99

static var _data := {}


## data/inventory.json, read once.
static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_data = d if d is Dictionary else {}
	return _data


## Empty slots in the sizes from `d`. `tools` are the ids that count as tools.
static func empty(tools: Array, d := data()) -> Inventory:
	var inv := Inventory.new()
	inv.tool_ids.assign(tools)
	inv.stack_max = maxi(int(d.get("stack_max", 99)), 1)
	for place in PLACES:
		var row := []
		row.resize(maxi(int(d.get("slots", {}).get(place, 1)), 1))
		for i in row.size():
			row[i] = {}
		inv.slots[place] = row
	return inv


## What a new game starts with: the start tools in the tool slots, the start items in the bag.
static func starting(tools: Array, d := data()) -> Inventory:
	var inv := empty(tools, d)
	var start: Dictionary = d.get("start", {})
	var i := 0
	for id in start.get("tools", []):
		if i < inv.size("tools") and inv.is_tool(id):
			inv.slots.tools[i] = {"id": id, "n": 1}
			i += 1
	for id in start.get("items", {}):
		inv.add(id, int(start.items[id]))
	return inv


func size(place: String) -> int:
	return slots.get(place, []).size()


func slot(place: String, i: int) -> Dictionary:
	var row: Array = slots.get(place, [])
	return row[i] if i >= 0 and i < row.size() else {}


func id_at(place: String, i: int) -> String:
	return String(slot(place, i).get("id", ""))


func is_tool(id: String) -> bool:
	return id in tool_ids


## Can `id` sit in a slot of `place`?
func accepts(place: String, id: String) -> bool:
	if id == "" or not slots.has(place):
		return false
	if is_tool(id):
		return place == "tools" or place == "chest"
	return place != "tools"


## Most of `id` one slot holds.
func limit(id: String) -> int:
	return 1 if is_tool(id) else stack_max


## How many of `id` are in `places`.
func count(id: String, places: Array = CARRIED) -> int:
	var n := 0
	for place in places:
		for s in slots.get(place, []):
			if s.get("id", "") == id:
				n += int(s.n)
	return n


## id -> count over `places`.
func totals(places: Array = CARRIED) -> Dictionary:
	var t := {}
	for place in places:
		for s in slots.get(place, []):
			if not s.is_empty():
				t[s.id] = int(t.get(s.id, 0)) + int(s.n)
	return t


## How many more of `id` fit in `places`.
func room_for(id: String, places: Array = ["bag"]) -> int:
	var n := 0
	for place in places:
		if not accepts(place, id):
			continue
		for s in slots[place]:
			if s.is_empty():
				n += limit(id)
			elif s.id == id:
				n += maxi(limit(id) - int(s.n), 0)
	return n


## Puts `n` of `id` into `places`: on stacks of the same id first, then into empty slots,
## in order. Returns how many did not fit.
func add(id: String, n := 1, places: Array = ["bag"]) -> int:
	var left := n
	for pass_empty in [false, true]:
		for place in places:
			if not accepts(place, id):
				continue
			var row: Array = slots[place]
			for i in row.size():
				if left <= 0:
					return 0
				var s: Dictionary = row[i]
				if s.is_empty() and pass_empty:
					var put := mini(left, limit(id))
					row[i] = {"id": id, "n": put}
					left -= put
				elif not s.is_empty() and s.id == id and not pass_empty:
					var put := mini(left, limit(id) - int(s.n))
					if put > 0:
						s.n = int(s.n) + put
						left -= put
	return maxi(left, 0)


## Takes `n` of `id` out of `places` (in order), all or nothing.
func take(id: String, n := 1, places: Array = CARRIED) -> bool:
	if n <= 0 or count(id, places) < n:
		return false
	var left := n
	for place in places:
		var row: Array = slots.get(place, [])
		for i in row.size():
			var s: Dictionary = row[i]
			if left == 0 or s.is_empty() or s.id != id:
				continue
			var got := mini(left, int(s.n))
			left -= got
			if got == int(s.n):
				row[i] = {}
			else:
				s.n = int(s.n) - got
	return true


## Every slot of the carried places emptied, then `counts` (id -> n) put in the bag; what
## doesn't fit goes to the chest, which grows when it must (old saves, nothing is lost).
func set_carried(counts: Dictionary) -> void:
	for place in CARRIED:
		for i in size(place):
			slots[place][i] = {}
	for id in counts:
		var left := add(id, int(counts[id]), ["bag", "chest"])
		while left > 0:
			grow("chest", size("chest") + 8)
			left = add(id, left, ["chest"])


## Lifts the whole stack out of a slot (the menu's cursor carries it). Returns it, or {}.
func lift(place: String, i: int) -> Dictionary:
	var s := slot(place, i)
	if not s.is_empty():
		slots[place][i] = {}
	return s


## Puts a carried `stack` down on a slot and returns what is carried after: {} when it all
## went in, the rest when the stack there filled up, the slot's old stack when the two
## swapped. A place that doesn't take the id gives the stack back untouched.
func drop(place: String, i: int, stack: Dictionary) -> Dictionary:
	if stack.is_empty() or i < 0 or i >= size(place) or not accepts(place, stack.id):
		return stack
	var here: Dictionary = slots[place][i]
	if here.is_empty():
		slots[place][i] = stack
		return {}
	if here.id == stack.id:
		var put := mini(int(stack.n), limit(stack.id) - int(here.n))
		here.n = int(here.n) + put
		if put == int(stack.n):
			return {}
		return {"id": stack.id, "n": int(stack.n) - put}
	slots[place][i] = stack
	return here


## Moves a whole slot onto another: into an empty one, onto the same id (what doesn't fit
## stays behind), or a swap when each place takes the other's id. Returns false when nothing
## could move (the slots stay as they were).
func move(from: String, fi: int, to: String, ti: int) -> bool:
	var s := slot(from, fi)
	if s.is_empty() or (from == to and fi == ti) or ti < 0 or ti >= size(to) or not accepts(to, s.id):
		return false
	var other := slot(to, ti)
	if not other.is_empty() and other.id != s.id and not accepts(from, other.id):
		return false
	if not other.is_empty() and other.id == s.id and int(other.n) >= limit(s.id):
		return false
	var rest := drop(to, ti, lift(from, fi))
	if not rest.is_empty():
		slots[from][fi] = rest
	return true


## Finds a home for a carried stack: `first` (where it came from) when that slot is empty,
## else stacks of the same id and empty slots in `places`. Returns what is still carried
## ({} when all of it went somewhere).
func stow(stack: Dictionary, first_place := "", first_i := -1, places: Array = ["tools", "bag", "hand", "chest"]) -> Dictionary:
	if stack.is_empty():
		return {}
	if first_place != "" and slot(first_place, first_i).is_empty() and accepts(first_place, stack.id):
		slots[first_place][first_i] = stack
		return {}
	var left := add(stack.id, int(stack.n), places)
	return {} if left == 0 else {"id": stack.id, "n": left}


## A place gets `n` slots (never fewer than it has, so nothing falls out).
func grow(place: String, n: int) -> void:
	var row: Array = slots.get(place, [])
	while row.size() < n:
		row.append({})
	slots[place] = row


# --- save / load ------------------------------------------------------------

## {place: [slot or null, ...]}, empty slots as null.
func to_dict() -> Dictionary:
	var d := {}
	for place in PLACES:
		var row := []
		for s in slots[place]:
			row.append(null if s.is_empty() else {"id": s.id, "n": int(s.n)})
		d[place] = row
	return d


## A saved inventory, checked slot by slot against these slot counts and tool ids. Returns
## [error, Inventory]; error is "" when it is usable. A place saved with fewer slots than the
## data has now is filled up to the data's count (the data grew), never cut.
static func parse(saved: Variant, tools: Array, d := data()) -> Array:
	if not saved is Dictionary:
		return ["Saved inventory is broken", null]
	var inv := empty(tools, d)
	for place in PLACES:
		var row = saved.get(place)
		if not row is Array or row.size() > 999:
			return ["Saved %s slots are broken" % place, null]
		inv.grow(place, row.size())
		for i in row.size():
			var s = row[i]
			if s == null:
				continue
			if not s is Dictionary or not s.get("id") is String or not inv.accepts(place, s.id):
				return ["Saved %s slot %d is broken" % [place, i + 1], null]
			var n = SaveGame.whole(s.get("n"), 1, inv.limit(s.id))
			if n == null:
				return ["Saved %s slot %d is broken" % [place, i + 1], null]
			inv.slots[place][i] = {"id": s.id, "n": n}
	return ["", inv]
