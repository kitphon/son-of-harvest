class_name ScoopScreen
extends CanvasLayer
## The goldfish scoop (a festival's `game`, kind scoop) over the village in both views: a wood
## box with the game's name, the time left and the fish scooped, and a paper stage below with the
## stall's tub seen from above, goldfish swimming slow loops in it, the farmer's paper scoop held
## over the water and the bowl of fish scooped beside it. E (or Enter / Space, a click) dips the
## scoop: a fish right under the paper comes up clean, one at the rim with a struggle (more wear),
## an empty dip only splashes; the bar under the tub shows the paper left. Opens on
## Game.game_requested, runs a GoldfishScoop, shows the count for a moment and hands it to
## Game.finish_game, whose result event follows. The clock holds while it is open.
## `-- --demo --festival=lantern_night --contest=scoop` opens it at the start;
## `--contest=scoop:auto` dips by itself (for screenshots).

const W := 280               # the paper's width
const STAGE := Vector2(240, 118)
const TOP := 17              # the heading strip on the wood
const LINE := 11
const TUB := Vector2(104, 54)       # the tub's middle on the stage
const TUB_R := 50.0                 # its water's radius (x); y is squashed by SQUASH
const SQUASH := 0.82                # the tub seen from above at a slant
const BOWL := Vector2(204, 76)      # the bowl of fish scooped
const SHOW_RESULT := 2.0     # seconds the final count stays up
const AUTO_WAIT := 0.06      # --contest=scoop:auto: seconds a fish is under the paper before the dip
const WATER := Color("5a9ab8")
const WATER_DEEP := Color("467c9c")
const TUB_WOOD := Color("8a6a44")
const POI_RING := Color("e8607a")    # the scoop's frame, a pink plastic ring
const POI_PAPER := Color(0.97, 0.95, 0.9, 0.55)

var game: GoldfishScoop
var festival := ""
var _open := false
var _ended := 0.0            # seconds since the go ended (0 while playing)
var _ticks := 0              # count-in clicks played
var _auto := false
var _auto_seen := -1.0
var _dim: Control
var _wood: NinePatchRect
var _paper: NinePatchRect
var _stage: Stage
var _name: Label
var _info: Label
var _call: Label
var _hint: Label


## The paper stage: drawn fresh every frame from the screen's game.
class Stage:
	extends Control
	var screen: ScoopScreen

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
	_auto = Array(OS.get_cmdline_user_args()).any(func(a): return a == "--contest=scoop:auto")


func _exit_tree() -> void:
	if _open:
		_open = false
		Game.scooping = false
		Game.scoop_lifted = false
		Game.unpause()


func is_open() -> bool:
	return _open


## Starts festival `fid`'s goldfish scoop (other game kinds have their own screens).
func open(fid: String, _who: String) -> void:
	if _open or Festivals.game(fid).get("kind") != "scoop":
		return
	festival = fid
	var g := Festivals.game(fid)
	game = GoldfishScoop.new(g, hash("%s:scoop:%d" % [fid, Game.year]))
	_open = true
	_ended = 0.0
	_ticks = 0
	_auto_seen = -1.0
	_name.text = str(g.name)
	Game.pause()
	_dim.visible = true
	_refresh()


## The count goes to Game.finish_game (its result event plays next).
func close() -> void:
	if not _open:
		return
	_open = false
	_dim.visible = false
	Game.scoop_lifted = false
	Game.unpause()
	Game.finish_game(game.score)


## A dip of the scoop (E / Enter / Space, or a click); once the go is over, it closes.
func dip() -> void:
	if not _open:
		return
	if game.done():
		if _ended > 0.5:
			close()
		return
	match game.press():
		"clean", "edge":
			Sfx.play("fish_catch")
		"splash":
			Sfx.play("hold_splash")
		"tear":
			Sfx.play("fish_escape")
	_refresh()


func _process(delta: float) -> void:
	if not _open:
		return
	Game.scoop_lifted = game.running() and game.lifted()   # the farmer's pose lifts the scoop with it
	if game.done():
		_ended += delta
		if _ended >= SHOW_RESULT:
			close()
		else:
			_refresh()
		return
	var tick := int(game.lead) - ceili(game.to_go())   # one click as each second of the count-in starts
	while game.to_go() > 0.0 and _ticks <= tick:
		_ticks += 1
		Sfx.play("mochi_count")
	for e in game.advance(delta):
		match e:
			"go": Sfx.play("chime_morning")
			"time": Sfx.play("mochi_count")
	if _auto and game.running():
		_auto_dip()
	_refresh()


## `--contest=scoop:auto`: dips a moment after a fish swims right under the paper.
func _auto_dip() -> void:
	if game.under() != "clean" or game.lifted():
		_auto_seen = -1.0
	elif _auto_seen < 0.0:
		_auto_seen = game.time
	elif game.time - _auto_seen >= AUTO_WAIT:
		_auto_seen = -1.0
		dip()


# --- drawing ------------------------------------------------------------------

func _refresh() -> void:
	if game == null:
		return
	var left := ceili(game.left())
	_info.text = "%d:%02d   %d fish" % [left / 60, left % 60, game.score]
	_info.position.x = _wood.size.x - 9 - PixelFont.shown_width(_info.text)
	var call := ""
	var color := PlaceholderArt.UI_SEAL
	if game.torn:
		call = "The paper tore!" if _ended < 0.9 else "%d fish!" % game.score
	elif game.done():
		call = "Time!" if _ended < 0.9 else "%d fish!" % game.score
	elif game.to_go() > 0.0:
		call = "Ready... %d" % ceili(game.to_go()) if game.to_go() > 0.5 else "Ready..."
	elif game.time - game.lead < 0.7:
		call = "Go!"
	elif game.time - game.last_at < 0.5:
		call = {"clean": "Scooped!", "edge": "Got it!", "splash": "Splash"}.get(game.last, "")
		color = PlaceholderArt.UI_SEAL if game.last == "clean" else Hud.INK if game.last == "edge" else Hud.INK_SOFT
	_call.text = call
	_call.add_theme_color_override("font_color", color)
	_call.position.x = (W - PixelFont.shown_width(call)) / 2
	_hint.text = "E: dip the scoop as a fish swims under the paper" if not game.done() \
		else "Clean %d   Close %d   Splash %d" % [game.counts.clean, game.counts.edge, game.counts.splash]
	_stage.queue_redraw()


## A point of the tub (unit circle, GoldfishScoop) on the stage.
func at(p: Vector2) -> Vector2:
	return TUB + Vector2(p.x, p.y * SQUASH) * TUB_R


## The stage: the stall's counter cloth, the tub with its fish, the scoop, the paper bar, the bowl.
func draw_stage(c: Control) -> void:
	if game == null:
		return
	c.draw_rect(Rect2(0, 0, STAGE.x, STAGE.y - 8), Color("2c4a8a"))          # the stall's indigo cloth
	c.draw_rect(Rect2(0, STAGE.y - 8, STAGE.x, 8), Color("d8c8a0"))          # the trodden ground
	for x in range(6, int(STAGE.x), 22):   # the cloth's white wave marks
		c.draw_arc(Vector2(x, 12), 5.0, PI, TAU, 8, Color(1, 1, 1, 0.25), 1.0)
	_ellipse(c, TUB, TUB_R + 7, Color("5a4026"))       # the tub's rim, its shadow side
	_ellipse(c, TUB - Vector2(0, 1), TUB_R + 6, TUB_WOOD)
	for k in 12:   # the staves
		var a := TAU * k / 12.0
		c.draw_line(at(Vector2(cos(a), sin(a)) * (TUB_R + 1) / TUB_R), at(Vector2(cos(a), sin(a)) * (TUB_R + 6) / TUB_R), Color("6a4a30"), 1.0)
	_ellipse(c, TUB, TUB_R, WATER_DEEP)
	_ellipse(c, TUB - Vector2(0, 2), TUB_R - 3, WATER)
	_ellipse(c, TUB + Vector2(-14, -12), 12.0, Color(1, 1, 1, 0.12))   # a lantern's glint
	for i in game.fish.size():
		if game.swimming(i):
			_fish(c, at(game.pos(i)), game.heading(i), int(game.fish[i].look), 1.5)
	_poi(c)
	# The paper left: a bar under the tub, red when nearly gone.
	var bar := Rect2(TUB.x - 40, STAGE.y - 6, 80, 3)
	c.draw_rect(bar, Hud.RULE)
	c.draw_rect(Rect2(bar.position, Vector2(roundf(bar.size.x * game.strength()), bar.size.y)),
		PlaceholderArt.UI_SEAL if game.strength() < 0.3 else Color("f4ece0"))
	# The bowl of fish scooped, the last few swimming in it.
	_ellipse(c, BOWL, 22.0, Color("c8d8e0"))
	_ellipse(c, BOWL - Vector2(0, 1), 19.0, Color("8cc0d8"))
	var shown := game.bowl.slice(maxi(game.bowl.size() - 8, 0))
	for k in shown.size():
		var a := TAU * k / 8.0 + game.time * 0.4
		var p := BOWL + Vector2(cos(a) * 11.0, sin(a) * 11.0 * SQUASH)
		_fish(c, p, Vector2(-sin(a), cos(a)), shown[k], 1.0)


## The paper scoop over the water: held low when ready, lifted (and dripping) after a dip,
## a ragged hole once torn.
func _poi(c: Control) -> void:
	var lift := 6.0 if game.lifted() else 0.0
	var mid := at(GoldfishScoop.SPOT) - Vector2(0, lift)
	var r: float = TUB_R * float(Festivals.game(festival).reach.edge)
	if lift > 0.0:   # the ripples where it came out
		_ring(c, at(GoldfishScoop.SPOT), r + (game.time - game.dipped_at) * 30.0, Color(1, 1, 1, 0.4))
	c.draw_line(mid + Vector2(r * 0.7, r * 0.7 * SQUASH), mid + Vector2(r + 22, r + 16), POI_RING.darkened(0.2), 3.0)   # the handle
	if not game.torn:
		_ellipse(c, mid, r, Color(POI_PAPER, POI_PAPER.a * (0.4 + 0.6 * game.strength())))
		# Wet patches spread as the paper weakens.
		var wet := 1.0 - game.strength()
		if wet > 0.25:
			_ellipse(c, mid + Vector2(-3, 2), r * 0.5 * wet, Color(0.6, 0.72, 0.78, 0.5))
	else:
		for k in 7:   # the paper's torn shreds round the frame
			var a := TAU * k / 7.0
			c.draw_line(mid + Vector2(cos(a), sin(a) * SQUASH) * r, mid + Vector2(cos(a + 0.3), sin(a + 0.3) * SQUASH) * r * 0.7,
				Color(POI_PAPER, 0.8), 1.0)
	_ring(c, mid, r, POI_RING)
	var inner: float = TUB_R * float(Festivals.game(festival).reach.clean)
	if game.running() and game.under() == "clean":   # a fish right under the paper: the sweet spot shows
		_ring(c, mid, inner, Color(PlaceholderArt.UI_SEAL, 0.8))


## One goldfish at `p` swimming along `dir`, `look` of GoldfishScoop's looks (PlaceholderArt
## "scoop:fish:<look>"), `size` times the tub's size, turned to face the way it swims.
func _fish(c: Control, p: Vector2, dir: Vector2, look: int, size: float) -> void:
	var tex := PlaceholderArt.tex(PlaceholderArt.scoop_fish_key(look))
	var d := Vector2(dir.x, dir.y * SQUASH)
	c.draw_set_transform(p, d.angle(), Vector2.ONE * size * 0.75)
	c.draw_texture(tex, Vector2(-14, -tex.get_height() / 2.0))
	c.draw_set_transform(Vector2.ZERO)


func _ellipse(c: Control, mid: Vector2, r: float, color: Color) -> void:
	c.draw_set_transform(mid, 0.0, Vector2(1.0, SQUASH))
	c.draw_circle(Vector2.ZERO, r, color)
	c.draw_set_transform(Vector2.ZERO)


func _ring(c: Control, mid: Vector2, r: float, color: Color) -> void:
	c.draw_set_transform(mid, 0.0, Vector2(1.0, SQUASH))
	c.draw_arc(Vector2.ZERO, r, 0, TAU, 28, color, 1.5)
	c.draw_set_transform(Vector2.ZERO)


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
	var b := UiStyle.panel(null, kind)
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
		dip()


func _on_click(event: InputEvent) -> void:
	if _open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dip()
