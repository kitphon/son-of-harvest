class_name EventPlayer
extends Node
## Plays event scripts in a view: checks the map's trigger table on its causes, runs the
## EventRunner, copies the scripted farmer onto the Player and draws the fade. While an event
## plays Game.event_running holds the clock (Game.paused) and keys go nowhere but to the text
## box. Add it after the Player, so its physics step comes after the Player's.
## `-- --event=<id>` plays one at the start; under `-- --demo` the triggers are off, so
## screenshots of the field stay free of events.

const GROUP := "event_player"   # FarmActions finds the view's player here for examine

var player: Player
var map_id := "farm"
var table: EventTriggers
var runner: EventRunner
var _fade: ColorRect
var _cell := Vector2i(-1, -1)
var _auto := true


func _init(farmer: Player) -> void:
	player = farmer


func _ready() -> void:
	add_to_group(GROUP)
	var layer := CanvasLayer.new()
	layer.layer = 9   # over the HUD, under the text box
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0, 0, 0, 0)
	layer.add_child(_fade)
	add_child(layer)
	Game.event_requested.connect(play)
	Game.day_started.connect(func(): check.call_deferred("day_start"))
	Game.minute_passed.connect(func(): check("minute"))
	Game.map_entered.connect(enter_map)   # after each map change's fade (and the view's start)
	var args := OS.get_cmdline_user_args()
	_auto = not "--demo" in args
	map_id = Game.maps.id
	table = EventTriggers.open(map_id)
	for arg in args:
		if arg.begins_with("--event="):   # e.g. `-- --demo --event=first_morning`
			play.call_deferred(arg.trim_prefix("--event="))
		elif arg.begins_with("--contest="):   # `-- --demo --festival=<id> --contest=<item>`: hand it in, see the results
			Game.enter_contest.call_deferred()


## The farmer arrived on map `id` (Game.map_entered): its trigger table, then the "enter" check.
func enter_map(id: String) -> void:
	map_id = id
	table = EventTriggers.open(id)
	if table.error != "":
		push_error("Triggers %s: %s" % [id, table.error])
	_cell = Player.cell_of(player.position)
	check.call_deferred("enter")


## Asks the trigger table about `cause` and plays what the first matching row names.
func check(cause: String) -> void:
	if not _auto or runner != null or Game.paused() or not Game.clock_running:
		return
	var s := Game.trigger_state(Player.cell_of(player.position))
	# A festival on this map plays its event once a year: on walking in during its hours, or
	# when the hours start with the farmer already there (data/festivals.json).
	var fest := Festivals.due_event(map_id, s) if cause in ["enter", "minute"] else ""
	if fest != "":
		Game.events_seen[Festivals.seen_key(s.festival, s.year)] = true
		play(fest)
		return
	var id := table.pick(cause, s)
	if id != "":
		play(id)


## The farmer pressed interact facing cell `spot`: plays the map's first matching "examine"
## row and says whether one played (FarmActions then skips its own interact). Examining is
## the player's own doing, so it works under `-- --demo` too.
func examine(spot: Vector2i) -> bool:
	if runner != null or Game.paused():
		return false
	var s := Game.trigger_state(Player.cell_of(player.position))
	s.spot = spot
	var id := table.pick("examine", s)
	if id != "":
		play(id)
	return runner != null


## The farmer talks to villager `who`: plays the map's first matching "talk" row for them
## and says whether one played (then the villager's own lines wait for another time).
func talked_to(who: String) -> bool:
	if not _auto or runner != null or Game.paused():
		return false
	var s := Game.trigger_state(Player.cell_of(player.position))
	s.who = who
	var id := table.pick("talk", s)
	if id != "":
		play(id)
	return runner != null


func play(id: String) -> void:
	if runner != null:
		return
	var r := EventRunner.open(id, Game)
	if r.error != "":
		push_error("Event %s: %s" % [id, r.error])
		Game.message.emit("Can't read event %s" % id)
		return
	runner = r
	runner.walk_speed = Player.WALK_SPEED
	runner.run_speed = Player.RUN_SPEED
	runner.sound.connect(Sfx.play)
	runner.start(player.position, player.facing)
	Game.events_seen[id] = true
	Game.event_running = true
	player.cancel_charge()
	_physics_process(0.0)   # instant first steps (a fade from black) show on the first frame


func is_playing() -> bool:
	return runner != null


func _physics_process(delta: float) -> void:
	if runner == null:
		var cell := Player.cell_of(player.position)
		if cell != _cell:
			_cell = cell
			check("step")
		return
	runner.update(delta)
	player.position = runner.pos
	player.facing = runner.facing
	player.moving = runner.walking
	player.running = runner.running
	player.queue_redraw()
	_fade.color.a = runner.fade
	var cast := {}
	for id in runner.actors:
		cast[id] = runner.actors[id].merged({"map": map_id})
	Villagers.actors = cast
	if runner.done():
		runner = null
		Villagers.actors = {}
		Game.event_running = false
		_cell = Player.cell_of(player.position)
		Game.changed.emit()


# Keys go to the text box during an event's dialogue, and nowhere between its steps.
func _input(event: InputEvent) -> void:
	if runner != null and not Game.dialogue_open and (event is InputEventKey or event is InputEventJoypadButton):
		get_viewport().set_input_as_handled()
