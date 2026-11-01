class_name MochiScreen
extends CanvasLayer
## The mochi pounding (a festival's `game`, kind mochi) over the village in both views: a wood
## box with the game's name, the round and the score, and a paper stage below with the mortar
## in the middle, the farmer swinging the mallet on the left and the partner turning the dough
## on the right. A ring closes on the dough for every strike: E (or Enter / Space) as it
## meets the mark. Opens on Game.game_requested, runs a MochiPound, shows the score for a
## moment and hands it to Game.finish_game, whose result event follows. The clock holds while
## it is open. `-- --demo --festival=years_turn --contest=mochi` opens it at the start;
## `--contest=mochi:auto` swings by itself (for screenshots).

const W := 280               # the paper's width
const STAGE := Vector2(240, 118)
const TOP := 17              # the heading strip on the wood
const LINE := 11
const SCALE := 2.0           # the sprites on the stage
const MORTAR := Vector2(88, 62)      # the usu's top left on the stage
const DOUGH := Vector2(120, 72)      # where the mallet lands and the ring closes
const FARMER := Vector2(36, 60)
const PARTNER := Vector2(156, 60)
const HANDS := Vector2(66, 88)       # the farmer's grip on the handle
const UP := -0.45            # the mallet's angle raised (radians from upright), and on the dough
const DOWN := 1.35
const RING := 14.0           # the mark's radius; the ring starts RING_FAR out a second ahead
const RING_FAR := 46.0
const SHOW_RESULT := 2.0     # seconds the final score stays up
const AUTO := [0.0, 0.03, 0.1, 0.0, 0.05, 0.13]   # --contest=mochi:auto: how late each swing is

var game: MochiPound
var festival := ""
var partner := ""
var _open := false
var _ended := 0.0            # seconds since the last beat was judged (0 while playing)
var _counts: Array[float] = []   # the count-in clicks still to play
var _round := -1
var _auto := false
var _auto_i := 0
var _dim: Control
var _wood: NinePatchRect
var _paper: NinePatchRect
var _stage: Stage
var _name: Label
var _info: Label
var _call: Label             # Great! / Good / Miss, or the round's call
var _hint: Label


## The paper stage: drawn fresh every frame from the screen's game.
class Stage:
	extends Control
	var screen: MochiScreen

	func _draw() -> void:
		screen.draw_stage(self)


func _ready() -> void:
	layer = 10   # over the HUD
	_dim = Control.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_click)
	add_child(_dim)
	_wood = _box(_dim, "wood")
	_name = _label(_wood, Vector2i(9, 5), PlaceholderArt.UI_PAPER)
	_info = _label(_wood, Vector2i(0, 5), PlaceholderArt.UI_PAPER)
	_paper = _box(_wood, "paper")
	_paper.position = Vector2(4, TOP)
	_paper.size = Vector2(W, STAGE.y + LINE + 10)
	_stage = Stage.new()
	_stage.screen = self
	_stage.position = Vector2((W - STAGE.x) / 2, 3)
	_stage.size = STAGE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_paper.add_child(_stage)
	_call = _label(_paper, Vector2i(0, 6), PlaceholderArt.UI_SEAL)
	_hint = _label(_paper, Vector2i(8, int(STAGE.y) + 5), Hud.INK_SOFT)
	_wood.size = Vector2(W + 8, TOP + _paper.size.y + 4)
	var screen := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	_wood.position = Vector2(floorf((screen.x - _wood.size.x) / 2), 28)
	_dim.visible = false
	Game.game_requested.connect(open)
	_auto = Array(OS.get_cmdline_user_args()).any(func(a): return a.begins_with("--contest=") and a.ends_with(":auto"))


func _exit_tree() -> void:
	if _open:
		_open = false
		Game.game_partner = ""
		Game.unpause()


func is_open() -> bool:
	return _open


## Starts festival `fid`'s game with `who` turning the dough.
func open(fid: String, who: String) -> void:
	if _open:
		return
	festival = fid
	partner = who
	var g := Festivals.game(fid)
	game = MochiPound.new(g)
	_open = true
	_ended = 0.0
	_round = -1
	_auto_i = 0
	var first: float = float(g.rounds[0].beat)
	_counts = []
	for k in [3, 2, 1]:
		if game.beats[0] - k * first >= 0.0:
			_counts.append(game.beats[0] - k * first)
	_name.text = str(g.name)
	Game.pause()
	_dim.visible = true
	_refresh()


## The score goes to Game.finish_game (its result event plays next).
func close() -> void:
	if not _open:
		return
	_open = false
	_dim.visible = false
	Game.unpause()
	Game.finish_game(game.score)


## A swing of the mallet (E / Enter / Space, or a click).
func swing() -> void:
	if not _open:
		return
	if game.done():
		close()
		return
	match game.press():
		"great", "good":
			Sfx.play("mochi_pound")
		"miss":
			Sfx.play("mochi_miss")
	_refresh()


func _process(delta: float) -> void:
	if not _open:
		return
	if game.done():
		_ended += delta
		if _ended >= SHOW_RESULT:
			close()
		else:
			_stage.queue_redraw()
		return
	if _auto and game.to_next() <= -AUTO[_auto_i % AUTO.size()]:
		_auto_i += 1
		swing()
	for e in game.advance(delta):
		if e == "turn":
			Sfx.play("mochi_turn")
	while not _counts.is_empty() and game.time >= _counts[0]:
		_counts.pop_front()
		Sfx.play("mochi_count")
	if game.round_now() != _round and game.to_next() < 1.2:
		_round = game.round_now()
		if _round > 0:
			Sfx.play("mochi_count")
	_refresh()


# --- drawing ------------------------------------------------------------------

func _refresh() -> void:
	if game == null:
		return
	_info.text = "Round %d of %d   %d pts" % [game.round_now() + 1, game.rounds, game.score]
	_info.position.x = _wood.size.x - 9 - PixelFont.width(_info.text)
	var call := ""
	var color := PlaceholderArt.UI_SEAL
	if game.done():
		call = "%d points!" % game.score
	elif game.time - game.last_at < 0.45:
		call = {"great": "Great!", "good": "Good", "miss": "Miss"}.get(game.last, "")
		color = PlaceholderArt.UI_SEAL if game.last == "great" else Hud.INK if game.last == "good" else Hud.INK_SOFT
	elif game.to_next() > 1.0 and game.round_now() > 0:
		call = "Faster now!"
	elif game.time < game.beats[0] - 0.6:
		call = "Ready..."
	_call.text = call
	_call.add_theme_color_override("font_color", color)
	_call.position.x = (W - PixelFont.width(call)) / 2
	var name := str(Villagers.all().get(partner, {}).get("name", partner))
	_hint.text = "%s turns the dough. E: swing as the ring closes" % name if not game.done() \
		else "Great %d   Good %d   Miss %d" % [game.counts.great, game.counts.good, game.counts.miss]
	_stage.queue_redraw()


## The stage: the ring, the partner, the mortar with its dough, the farmer and the mallet.
func draw_stage(c: Control) -> void:
	if game == null:
		return
	c.draw_rect(Rect2(0, 100, STAGE.x, STAGE.y - 100), Color("d8c8a0"))   # the trodden ground
	var turning := game.turning()
	_sprite(c, "villager:%s:front:%s:%d" % [partner, "work" if turning else "idle", 1 if turning else 0], PARTNER)
	_sprite(c, "mochi:usu:%d" % game.dough(4), MORTAR)
	var t := game.time - game.swung_at
	var swung := t < 0.28
	_sprite(c, "player:front:%s:0" % ("idle" if swung and t < 0.14 else "hold_idle"), FARMER)
	# The mallet: down onto the dough fast, a moment there, back up slower.
	var a := UP
	if swung:
		a = lerpf(UP, DOWN, clampf(t / 0.06, 0.0, 1.0)) if t < 0.12 else lerpf(DOWN, UP, clampf((t - 0.12) / 0.16, 0.0, 1.0))
	c.draw_set_transform(HANDS, a, Vector2(SCALE, SCALE))
	c.draw_texture(PlaceholderArt.tex("mochi:kine"), -PlaceholderArt.KINE_GRIP)
	c.draw_set_transform(Vector2.ZERO)
	if turning:   # the partner's wet hands in the bowl
		c.draw_circle(DOUGH + Vector2(12, -4), 3.0, Color("e8b890"))
	# The mark on the dough and the ring closing on it.
	if not game.done():
		var to := game.to_next()
		c.draw_arc(DOUGH, RING, 0, TAU, 24, Color(1, 1, 1, 0.8), 1.0)
		if to < 1.0:
			var near := absf(to) < 0.07
			c.draw_arc(DOUGH, RING + maxf(to, 0.0) * (RING_FAR - RING), 0, TAU, 32,
				PlaceholderArt.UI_SEAL if near else Hud.INK, 2.0)
	# The strikes so far, a dot each along the bottom: red great, ink good, hollow miss.
	var n := game.beats.size()
	for i in n:
		var p := Vector2(STAGE.x / 2 - n * 3.5 + i * 7 + 3.5, 109)
		match game.marks[i]:
			"great": c.draw_circle(p, 2.5, PlaceholderArt.UI_SEAL)
			"good": c.draw_circle(p, 2.5, Hud.INK)
			"miss": c.draw_arc(p, 2.5, 0, TAU, 10, Hud.INK_SOFT, 1.0)
			_: c.draw_circle(p, 1.0, Hud.RULE)


func _sprite(c: Control, key: String, at: Vector2) -> void:
	var tex := PlaceholderArt.tex(key)
	c.draw_texture_rect(tex, Rect2(at, tex.get_size() * SCALE), false)


func _label(parent: Control, pos: Vector2i, color := Hud.INK) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", PixelFont.font())
	l.add_theme_font_size_override("font_size", PixelFont.size())
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _box(parent: Control, kind: String) -> NinePatchRect:
	var b := NinePatchRect.new()
	b.texture = PlaceholderArt.tex("ui:frame:" + kind)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		b.set_patch_margin(side, Hud.NINE_MARGIN)
	b.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b


# --- input --------------------------------------------------------------------

# While open, every key and pad button is taken here, so nothing reaches the village.
func _input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		swing()


func _on_click(event: InputEvent) -> void:
	if _open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		swing()
