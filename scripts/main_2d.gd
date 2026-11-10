extends Node2D
## The flat top-down view (scenes/main_2d.tscn). The main scene is the 3D one (main_3d.gd).
## Same game as the 3D view: the Player's actions go to FarmActions (connect_view).
## The farm is a FarmView, other maps a MapView; a change of map fades and swaps them.
## Weather and festival lights read the same rules as the 3D view: WeatherView for rain and
## snow, Lightning for the flashes, FestivalGlow for the lanterns and fireworks at night,
## NightView for the lit windows, stone lanterns and the warm pools under them, FlatLight for
## the sun's share and the warm night lift on the farmer, villagers, animals and field pictures.

const T := 16

var view: Node2D
var player: Player
var cam: Camera2D
var tint: CanvasModulate
var mine_light: ColorRect   # down the mine: the floor's light and the lantern (MineLight), over the view
var fade: MapFade
var weather: WeatherView
var flash: ColorRect   # lightning: pale sky light added over the picture
var lightning := Lightning.new()
var glow: FestivalGlow
var smoke: SmokeView        # hearth smoke at meal times (the current view's)
var night: NightView        # the lit windows, lanterns and festival lights (the current view's)
var prints: FootprintView   # footprints in lying snow (the current view's)
var flying: Sprite2D  # a thrown item on its way
var _flight := {}      # from, to, time, seconds, height (while flying)
const RING_EVERY := 1.7        # seconds between the gentle rings round a waiting bobber (as Main3D)
const RING_BITE_EVERY := 0.4   # and between the strong ones in a bite
var _ring_state := "idle"
var _ring_next := 0.0


func _ready() -> void:
	player = Player.new()
	player.farm = Game.farm
	add_child(player)

	cam = Camera2D.new()
	player.add_child(cam)

	tint = CanvasModulate.new()
	add_child(tint)
	mine_light = ColorRect.new()
	mine_light.material = MineLight.material()
	mine_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mine_light.z_index = 100
	mine_light.size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	mine_light.visible = false
	add_child(mine_light)
	weather = WeatherView.new()
	add_child(weather)
	# Lightning and the festival glow: added over the tinted picture, under the HUD.
	var layer := CanvasLayer.new()
	layer.layer = 0
	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flash.material = add
	flash.color = Color.BLACK
	layer.add_child(flash)
	glow = FestivalGlow.new()
	layer.add_child(glow)
	add_child(layer)
	add_child(Hud.new())
	fade = MapFade.new()
	add_child(fade)
	add_child(TextBox.new())
	add_child(PauseScreen.new())
	add_child(InventoryScreen.new())
	add_child(ShopScreen.new())
	add_child(CookingScreen.new())
	add_child(MochiScreen.new())
	add_child(RaceScreen.new())
	add_child(ScoopScreen.new())
	add_child(EndingScreen.new())
	add_child(EventPlayer.new(player))   # after the Player: moves it during events
	flying = Sprite2D.new()
	flying.visible = false
	add_child(flying)   # after the Player: over the farmer

	Game.minute_passed.connect(_update_tint)
	Game.day_started.connect(_on_day_started)
	Game.minute_passed.connect(_age_prints)   # footprints in snow fill in
	Game.map_changed.connect(func(_id): fade.run(_enter_map))
	Game.settings_changed.connect(func(): lightning.reset({} if Game.sheltered() else Game.lightning_style()))
	Game.fishing_event.connect(func(kind): FarmActions.on_fishing_event(kind))
	Game.thrown.connect(_on_thrown)
	_enter_map()
	Game.map_arrived()
	FarmActions.connect_view(player)   # tools, doors, talking, fishing ... and the --talk flag


func _unhandled_input(event: InputEvent) -> void:
	FarmActions.handle_input(event)


## Swaps in the view for Game.maps and puts the farmer where it says.
func _enter_map() -> void:
	if view != null:
		view.queue_free()
	var m := Game.maps.current()
	if Game.maps.on_farm():
		var fv := FarmView.new()
		fv.farm = Game.farm
		fv.gaps = m.gate_cells()
		view = fv
		add_child(view)
		fv.show_snow(Game.snow_rules)
		fv.set_snow(Game.snow_cover / 100.0)
	else:
		var mv := MapView.new()
		mv.map = m
		view = mv
		add_child(view)
		mv.show_snow(Game.snow_rules)   # outdoors only
		mv.set_snow(Game.snow_cover / 100.0)
		mv.set_season(Game.season_name())
	view.add_child(PuddleView.new().setup(m, Game.farm if Game.maps.on_farm() else null))   # puddles in rain, on the ground
	prints = FootprintView.new()   # footprints in lying snow, over the ground, under everything else
	view.add_child(prints)
	night = NightView.new().setup(m.props, Game.maps.on_farm(), m.id)
	night.tint = tint
	view.add_child(night)   # lit windows and lanterns, under the figures
	smoke = SmokeView.new().setup(m.props, Game.maps.on_farm(), m.indoor)   # hearth smoke over the roofs
	view.add_child(smoke)
	var drift := DriftView.new().setup(m, Game.farm if Game.maps.on_farm() else null)   # petals, leaves, fireflies
	drift.tint = tint
	view.add_child(drift)
	view.add_child(StoryView.new(m))   # what the heart events left (the bell, the store's sign)
	view.add_child(FerryView.new(m))   # Mio's ferry boat, moving when she takes it across
	view.add_child(DyeClothView.new(m))   # Shino's indigo drying by her vats, in her hours on dry days
	view.add_child(CradleView.new())   # the baby's cradle in the second room, while the child is a baby
	view.add_child(FestivalView.new(m.id))   # today's festival decorations, in its hours
	view.add_child(ForageView.new(m.id))   # what grows wild there today (data/forage.json)
	view.add_child(VillagerView.new(m.id))
	if Game.maps.mine_floor != null:   # rocks, soft spots and the hole down
		view.add_child(MineView.new(Game.maps.mine_floor))
	move_child(view, 0)
	var animals := AnimalView.new()   # the animals and eggs (coop, barn, or the farm and its dog)
	view.add_child(animals)
	animals.setup(m, Game.maps.on_farm(), player)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = m.w * T
	cam.limit_bottom = m.h * T
	player.farm = Game.farm
	player.position = Game.maps.pos
	player.facing = Game.maps.facing
	player.cancel_charge()
	_show_weather()
	_update_tint()


## Weather falls outdoors only (not in buildings or the mine).
func _show_weather() -> void:
	weather.show_weather({} if Game.sheltered() else Game.weather_style())
	lightning.reset({} if Game.sheltered() else Game.lightning_style())
	weather.follow(cam.get_screen_center_position())
	var sheet := view.get("_water") as WaterView if view != null else null
	if sheet != null:
		sheet.set_rain({} if Game.sheltered() else Game.dimple_style())
		sheet.set_ice({} if Game.sheltered() else Game.ice_style(), Game.snow_cover / 100.0)


## The farmer is put home by the map change (Game.go_home) that comes with the new day.
func _on_day_started() -> void:
	player.cancel_charge()
	_show_weather()
	_update_tint()
	prints.clear()
	view.set_snow(Game.snow_cover / 100.0)
	if view is MapView:
		view.set_season(Game.season_name())


func _update_tint() -> void:
	var m := Game.maps.current()
	var f := Game.maps.mine_floor
	tint.color = Color.WHITE if f != null else (m.light if m.light != null else Game.light_color())
	mine_light.visible = f != null
	if f != null:
		mine_light.color = f.light
	_aim_lantern()
	_update_light()


## The world's light on the pictures (FlatLight, by SpriteLight's rules): the sun's share by the
## clock (plain in rooms, down the mine and in a house's own light, as Main3D's _inside) and the
## lights burning now on this map; the views in FlatLight.GROUP redraw when it changed.
func _update_light() -> void:
	var m := Game.maps.current()
	var inside := m.indoor or Game.maps.mine_floor != null or m.light != null
	var rules := SpriteLight.rules_of(Game.light_data())
	var sun_c := SpriteLight.sun_tint(Game.sun_light(inside).color, rules)
	var lit := night != null and is_instance_valid(night)
	var spots := FlatLight.spots_from(night if lit else null, Game.window_light(), night.festival_dark() if lit else 0.0, rules)
	if FlatLight.update(sun_c, spots, tint.color, rules):
		get_tree().call_group(FlatLight.GROUP, "queue_redraw")


## The farmer (and what the farmer carries) and a thrown item in flight take the light where they
## are, each frame (they move); the villagers' VillagerView does the same for them.
func _light_figures() -> void:
	var c := FlatLight.at(player.position, PlaceholderArt.FIGURE_SIZE.y, FarmWorld.FIGURE_PX)
	player.figure.self_modulate = c
	player.light = c
	if flying.visible and flying.texture != null:
		flying.modulate = FlatLight.at(flying.position, flying.texture.get_height(), FarmWorld.PX)


func _process(delta: float) -> void:
	_leave_prints()
	_aim_lantern()
	_fly(delta)
	_light_figures()
	_ring_bobber(delta)
	weather.follow(cam.get_screen_center_position())
	_update_flash(delta)


func _age_prints() -> void:
	if prints != null:
		prints.age(1.0)


## Footprints in snow (Footprints): the farmer, the villagers here and the dog leave them.
func _leave_prints() -> void:
	if prints == null or view == null:
		return
	var walkers := {"farmer": player.position / T}
	for n in view.get_children():
		if n is VillagerView:
			walkers.merge((n as VillagerView).feet())
	var dog: Dictionary = Game.animals.dog
	if Game.maps.on_farm() and not dog.get("held", false) and not dog.get("lifted", false):
		walkers["dog"] = Vector2(dog.cell) + Vector2(0.5, 0.5)
	prints.feed(walkers)


## Ripple rings on the pond round the bobber, timed as Main3D._ring_bobber: a strong one as it
## lands and as a fish bites, a gentle one every RING_EVERY while it waits, strong ones every
## RING_BITE_EVERY in a bite. The water is the view's WaterView (FarmView and MapView keep it
## as `_water`); the bobber's cell centre in map pixels is where the ring starts.
func _ring_bobber(delta: float) -> void:
	var f := Game.fishing
	var was := _ring_state
	_ring_state = f.state
	if not f.active() or view == null:
		return
	var sheet := view.get("_water") as WaterView
	if sheet == null:
		return
	var at := (Vector2(f.spot) + Vector2(0.5, 0.5)) * T
	if was == "idle" or (f.state == "bite" and was != "bite"):
		sheet.ripple(at, true)
		_ring_next = RING_EVERY if f.state == "wait" else RING_BITE_EVERY
		return
	_ring_next -= delta
	if _ring_next <= 0.0:
		sheet.ripple(at, f.state == "bite")
		_ring_next = RING_EVERY if f.state == "wait" else RING_BITE_EVERY


func _update_flash(delta: float) -> void:
	var b := lightning.step(delta) if Game.ticking() else 0.0
	if lightning.started: Sfx.thunder_after_flash()
	flash.color = Lightning.flash_color(Game.lightning_style(), b)


## A throw: the item flies in an arc from over the head to the cell it ends up on (the bin,
## the pond, the ground); one that lands shows on its cell only when it gets there.
func _on_thrown(item: String, _from: Vector2i, to: Vector2i, result: String) -> void:
	flying.texture = PlaceholderArt.tex(PlaceholderArt.world_item_key(item))
	flying.visible = true
	var h := flying.texture.get_height()
	_flight = {
		"from": player.position + Vector2(0, Player.FIGURE_TOP + PlaceholderArt.hold_row("hold_idle", 0) - h / 2.0), "to": Vector2(to * T) + Vector2(T / 2.0, T / 2.0),
		"time": 0.0, "seconds": float(Game.hold_rules.get("flight_seconds", 0.35)),
		"height": float(Game.hold_rules.get("arc_height", 1.2)) * T,
	}
	if view is FarmView:
		view.hidden_item = to if result == "land" else Vector2i(-1, -1)
	_fly(0.0)


func _fly(delta: float) -> void:
	if _flight.is_empty():
		return
	_flight.time += delta
	var t := clampf(_flight.time / maxf(_flight.seconds, 0.01), 0.0, 1.0)
	var p: Vector2 = _flight.from.lerp(_flight.to, t)
	p.y -= _flight.height * 4.0 * t * (1.0 - t)
	flying.position = p
	if t >= 1.0:
		flying.visible = false
		_flight = {}
		if view is FarmView:
			view.hidden_item = Vector2i(-1, -1)


## Down the mine the light rectangle covers what the camera sees; the lantern is on the farmer.
func _aim_lantern() -> void:
	var f := Game.maps.mine_floor
	if f == null:
		return
	var z := cam.zoom.x
	mine_light.scale = Vector2.ONE / z
	mine_light.position = cam.get_screen_center_position() - mine_light.size / (2.0 * z)
	MineLight.aim(mine_light.material, f, (player.global_position - mine_light.position) * z, T * z, mine_light.size)
