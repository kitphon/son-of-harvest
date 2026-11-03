class_name Goals
extends RefCounted
## Tome's first-week list (data/goals.json): small goals with a reward each, so a new farm has
## something to reach on day 1-3 and through the first week. What is counted comes from Game
## (Game.goal_stats: some from its own state, the rest from `counts` here); this class only
## keeps which goals are done, decides which are newly done, and builds the texts. Saved with
## the run (Game.goals). Pure logic, tested headless (tests/test_goals.gd).

const PATH := "res://data/goals.json"

static var _data: Variant = null

var done: Array[String] = []   # goal ids done (and paid), in the order they were done
var counts: Dictionary = {}    # stat -> number, for what Game can't count from its own state (forage, earned)
var waiting: Array[String] = []   # done goals whose villager line is still to be shown (not saved)


static func data() -> Dictionary:
	if _data == null:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		if not d is Dictionary:
			push_error("Goals: can't read " + PATH)
			d = {}
		_data = d
	return _data


## Every goal, in the order the HUD shows them.
static func all() -> Array:
	return data().get("goals", [])


static func goal(id: String) -> Dictionary:
	for g in all():
		if g.get("id", "") == id:
			return g
	return {}


static func message(key: String) -> String:
	return String(data().get("messages", {}).get(key, ""))


## Adds `n` to the counted stat `stat` (a wild thing picked, money paid by the cart).
func add(stat: String, n := 1) -> void:
	if n > 0:
		counts[stat] = int(counts.get(stat, 0)) + n


func is_done(id: String) -> bool:
	return id in done


## The first goal not done yet ({} once the list is done).
func current() -> Dictionary:
	for g in all():
		if not is_done(g.id):
			return g
	return {}


## How far goal `g` is with the numbers `stats` (Game.goal_stats), at most its count.
static func progress(g: Dictionary, stats: Dictionary) -> int:
	return clampi(int(stats.get(g.get("stat", ""), 0)), 0, int(g.get("count", 1)))


## The ids of goals not done yet whose stat has reached their count, in list order. Does not
## mark them: Game does that when it pays the reward.
func reached(stats: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for g in all():
		if not is_done(g.id) and progress(g, stats) >= int(g.get("count", 1)):
			out.append(String(g.id))
	return out


## The HUD line for goal `g`: "Plant 9 plots 4/9".
static func hud_text(g: Dictionary, stats: Dictionary) -> String:
	if g.is_empty():
		return ""
	return message("hud") % [String(g.text), progress(g, stats), int(g.get("count", 1))]


## The message line when goal `g` is done: "Goal done: Plant 9 plots! +150 G", with what the
## reward gave (`given`: Game._give_goal_reward's list of short texts).
static func done_text(g: Dictionary, given: Array) -> String:
	var parts := [message("done") % String(g.get("text", ""))]
	parts.append_array(given)
	return " ".join(parts)


func to_dict() -> Dictionary:
	return {"done": done.duplicate(), "counts": counts.duplicate()}


## [error, Goals] from saved data ("" = usable). Unknown goal ids are dropped, so taking a goal
## out of the list doesn't break older saves.
static func parse(v: Variant) -> Array:
	var g := Goals.new()
	if not v is Dictionary or not v.get("done", []) is Array or not v.get("counts", {}) is Dictionary:
		return ["Saved goals are broken", null]
	for id in v.get("done", []):
		if not id is String:
			return ["Saved goals are broken", null]
		if not goal(id).is_empty() and not id in g.done:
			g.done.append(id)
	var c: Dictionary = v.get("counts", {})
	for k in c:
		var n = SaveGame.whole(c[k], 0, 1 << 50)
		if not k is String or n == null:
			return ["Saved goals are broken", null]
		g.counts[k] = n
	return ["", g]


## A run saved before the list existed: every goal counts as done (that farm is past its
## first week, or near enough), so loading it doesn't pour out the whole list at once.
static func all_done() -> Goals:
	var g := Goals.new()
	for x in all():
		g.done.append(String(x.id))
	return g
