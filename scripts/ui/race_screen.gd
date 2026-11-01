class_name RaceScreen
extends CanvasLayer
## The fishing race (a festival's `game`, kind fishing) on screen in both views: a small wood
## box under the message line with the race's name and the fish landed, and on its paper the
## time left (big), a bar running down and the creel, one fish picture for each fish landed.
## The farmer fishes in the village meanwhile, so nothing here takes input; it only reads
## Game.race and plays the cues on Game.race_changed: a click each second of the count-in, the
## start, and the call when time is up. `--contest=fishing:auto` casts and reels by itself
## (for screenshots and the headless runs).

const BOX := Rect2(152, 26, 176, 44)   # on the 480 x 270 screen: top middle, under the message line
const TOP := 16                        # the heading strip on the wood
const CREEL := 8                       # fish pictures shown (the last ones landed)
const ICON := 12                       # a fish picture's size on the paper
const AUTO_REEL := 0.25                # --contest=fishing:auto: seconds into a bite before it reels

var _wood: NinePatchRect
var _paper: NinePatchRect
var _name: Label
var _count: Label
var _clock: Label
var _call: Label
var _bar: ColorRect
var _bar_back: ColorRect
var _icons: Array[TextureRect] = []
var _ticks := 0                        # count-in clicks played
var _auto := false


func _ready() -> void:
	layer = 9   # over the HUD, under the menus
	_wood = _box(self, "wood")
	_wood.position = BOX.position
	_wood.size = BOX.size
	_name = _label(_wood, Vector2i(7, 4), PlaceholderArt.UI_PAPER)
	_count = _label(_wood, Vector2i(0, 4), PlaceholderArt.UI_PAPER)
	_paper = _box(_wood, "paper")
	_paper.position = Vector2(4, TOP)
	_paper.size = Vector2(BOX.size.x - 8, BOX.size.y - TOP - 4)
	_clock = _label(_paper, Vector2i(6, 3))
	_call = _label(_paper, Vector2i(6, 3), PlaceholderArt.UI_SEAL)
	_bar_back = ColorRect.new()
	_bar_back.color = Hud.RULE
	_bar_back.position = Vector2(6, 15)
	_bar_back.size = Vector2(34, 3)
	_paper.add_child(_bar_back)
	_bar = ColorRect.new()
	_bar.color = PlaceholderArt.UI_SEAL
	_bar.position = _bar_back.position
	_bar.size = _bar_back.size
	_paper.add_child(_bar)
	for i in CREEL:
		var t := TextureRect.new()
		t.position = Vector2(46 + i * (ICON + 2), 6)
		t.size = Vector2(ICON, ICON)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_paper.add_child(t)
		_icons.append(t)
	var screen := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	UiScale.apply_layer(self, BOX, Game.ui_scale, screen)   # the UI size setting
	Game.settings_changed.connect(func(): UiScale.apply_layer(self, BOX, Game.ui_scale, screen))
	Game.race_changed.connect(_on_race)
	_auto = Array(OS.get_cmdline_user_args()).any(func(a): return a == "--contest=fishing:auto")
	_ticks = 0
	_refresh()


func is_shown() -> bool:
	return _wood.visible


func _on_race(what: String) -> void:
	match what:
		"start":
			_ticks = 0
		"go":
			Sfx.play("chime_morning")
		"time":
			Sfx.play("mochi_count")
	_refresh()


func _process(_delta: float) -> void:
	var r := Game.race
	if r != null and not r.running() and not r.over():
		var tick := int(r.lead) - ceili(r.to_go())   # one click as each second of the count-in starts
		while _ticks <= tick:
			_ticks += 1
			Sfx.play("mochi_count")
	if _auto and r != null and r.running() and not Game.paused():
		_auto_fish()
	_refresh()


## `--contest=fishing:auto`: casts when the line is in, reels a moment into each bite.
func _auto_fish() -> void:
	var cell := Player.cell_of(Game.maps.pos)
	if not Game.fishing.active():
		FarmActions.cast(cell, Game.maps.facing)
	elif Game.fishing.state == "bite" and Game.fishing.time >= AUTO_REEL:
		FarmActions.reel()


func _refresh() -> void:
	var r := Game.race
	_wood.visible = r != null
	if r == null:
		return
	_name.text = str(Festivals.game(Game.festival_today()).get("name", "Fishing race"))
	_count.text = "%d fish" % r.score()
	_count.position.x = BOX.size.x - 7 - PixelFont.width(_count.text)
	var call := ""
	if not r.running() and not r.over():
		call = "Ready... %d" % ceili(r.to_go()) if r.to_go() > 0.5 else "Ready..."
	elif r.over():
		call = "Time!"
	elif r.time - r.lead < 0.8:
		call = "Go!"
	_call.text = call
	_clock.visible = call == ""
	var left := ceili(r.left())
	_clock.text = "%d:%02d" % [left / 60, left % 60]
	_clock.add_theme_color_override("font_color", PlaceholderArt.UI_SEAL if r.running() and r.left() <= 10.0 else Hud.INK)
	_bar.size.x = roundf(_bar_back.size.x * r.left() / maxf(r.seconds, 0.01))
	var shown := r.fish.slice(maxi(r.fish.size() - CREEL, 0))
	for i in CREEL:
		_icons[i].texture = PlaceholderArt.tex(PlaceholderArt.item_key(shown[i])) if i < shown.size() else null


func _label(parent: Control, pos: Vector2i, color := Hud.INK) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", PixelFont.font())
	l.add_theme_font_size_override("font_size", PixelFont.size())
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _box(parent: Node, kind: String) -> NinePatchRect:
	var b := NinePatchRect.new()
	b.texture = PlaceholderArt.tex("ui:frame:" + kind)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		b.set_patch_margin(side, Hud.NINE_MARGIN)
	b.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b
