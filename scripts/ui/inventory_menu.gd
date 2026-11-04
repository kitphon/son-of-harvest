class_name InventoryMenu
extends RefCounted
## The rucksack / storage screen's cursor and the stack it carries, without any drawing
## (InventoryScreen draws it, headless tests check it). The slots are laid out in rows of
## COLS per place: the rucksack shows the tool slots, the rucksack's item slots and the hand;
## the storage screen puts the chest on top of those. choose() picks a stack up, puts it down,
## stacks it or swaps it; hold() takes the thing under the cursor in hand; eat() eats it;
## close() puts a carried stack back first. Each returns a note for the screen ("" when there is none).

const COLS := 8
const PLACES := {"rucksack": ["tools", "bag", "hand"], "storage": ["chest", "tools", "bag", "hand"]}
const TITLES := {"rucksack": "Rucksack", "storage": "Storage chest"}
const LABELS := {"tools": "Tools", "bag": "Rucksack", "hand": "Hand", "chest": "Chest"}

var inv: Inventory
var mode := "rucksack"
var rows: Array = []        # [place, first slot, slots in the row]
var row := 0
var col := 0
var carry := {}             # the stack on the cursor, {} when none
var tool_slot := 0          # the tool slot in hand (Game.tool_index)
var last_ok := false        # did the last eat() go through
var _from := ["", -1]       # where the carried stack was picked up


func _init(inventory: Inventory, m := "rucksack", tool_in_hand := 0) -> void:
	inv = inventory
	mode = m if PLACES.has(m) else "rucksack"
	tool_slot = tool_in_hand
	for place in PLACES[mode]:
		var n := inv.size(place)
		for start in range(0, n, COLS):
			rows.append([place, start, mini(COLS, n - start)])
	# The cursor starts on the tool in hand (the rucksack) or the chest's first slot.
	if mode == "rucksack":
		col = clampi(tool_slot, 0, rows[0][2] - 1)


func heading() -> String:
	return TITLES[mode]


func place() -> String:
	return rows[row][0]


func index() -> int:
	return rows[row][1] + col


## The id under the cursor ("" for an empty slot).
func id_here() -> String:
	return inv.id_at(place(), index())


## Arrow keys: left / right along the row, up / down to the next row (wrapping round); the
## column is kept where the row is long enough.
func move(dx: int, dy: int) -> void:
	if dy != 0:
		row = posmod(row + dy, rows.size())
		col = mini(col, rows[row][2] - 1)
	if dx != 0:
		col = posmod(col + dx, rows[row][2])


## Puts the cursor on slot `i` of `p` (the mouse). False when that slot isn't shown.
func point(p: String, i: int) -> bool:
	for r in rows.size():
		if rows[r][0] == p and i >= rows[r][1] and i < rows[r][1] + rows[r][2]:
			row = r
			col = i - rows[r][1]
			return true
	return false


## Enter / click: with nothing carried, picks up the stack under the cursor; carrying one,
## puts it down there (stacking on the same id, swapping with another).
func choose() -> String:
	if carry.is_empty():
		carry = inv.lift(place(), index())
		if not carry.is_empty():
			_from = [place(), index()]
		return ""
	if not inv.accepts(place(), carry.id):
		return "Only tools go here." if place() == "tools" else "Tools go in the tool slots or the chest."
	carry = inv.drop(place(), index(), carry)
	if carry.is_empty():
		_from = ["", -1]
	return ""


## E / right click: the thing under the cursor goes in hand. A tool slot becomes the tool in
## hand; an item swaps into the hand slot; the hand's item goes back into the rucksack; a
## tool in the chest swaps with the tool in hand.
func hold() -> String:
	if not carry.is_empty():
		return "Put it down first."
	var id := id_here()
	match place():
		"tools":
			tool_slot = index()
			return ""
		"hand":
			if id == "":
				return ""
			var rest := inv.stow(inv.lift("hand", 0), "", -1, ["bag"])
			if not rest.is_empty():
				inv.drop("hand", 0, rest)
				return "No room in the rucksack."
			return ""
	if id == "":
		return ""
	if inv.is_tool(id):
		return "" if inv.move(place(), index(), "tools", tool_slot) else "No room for the tool."
	return "" if inv.move(place(), index(), "hand", 0) else "Can't hold that."


## F (eat): eats the item under the cursor through the game `g` (Game.eat_item), from the
## rucksack or the hand, not out of the chest. Returns the note; last_ok says if it was eaten.
func eat(g) -> String:
	last_ok = false
	var id := id_here()
	if not carry.is_empty():
		return "Put it down first."
	if id == "":
		return ""
	if not g.edible(id):
		return "You can't eat that."
	if not place() in Inventory.CARRIED:
		return "Take it out of the chest first."
	var r: Dictionary = g.eat_item(id, [place()])
	last_ok = r.ok
	return r.note


## Esc / I: a carried stack goes back where it came from (or anywhere it fits on this screen)
## and the screen may close. Returns "" when it can close, else why not.
func close() -> String:
	if carry.is_empty():
		return ""
	carry = inv.stow(carry, _from[0], _from[1], PLACES[mode])
	if not carry.is_empty():
		return "No room to put it down."
	_from = ["", -1]
	return ""
