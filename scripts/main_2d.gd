extends Node2D
## The flat top-down view (scenes/main_2d.tscn). The main scene is the 3D one (main_3d.gd).
## Same game as the 3D view: the Player's actions go to FarmActions (connect_view).
## The farm is a FarmView, other maps a MapView; a change of map fades and swaps them.

const T := 16

var view: Node2D
var player: Player
var cam: Camera2D
var tint: CanvasModulate
var mine_light: ColorRect   # down the mine: the floor's light and the lantern (MineLight), over the view
var fade: MapFade
var flying: Sprite2D   # a thrown item on its way
var _flight := {}      # from, to, time, seconds, height (while flying)


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
	add_child(Hud.new())
	fade = MapFade.new()
	add_child(fade)
	add_child(TextBox.new())
	add_child(PauseScreen.new())
	add_child(InventoryScreen.new())
	add_child(ShopScreen.new())
	add_child(CookingScreen.new())
	add_child(EndingScreen.new())
	add_child(EventPlayer.new(player))   # after the Player: moves it during events
	flying = Sprite2D.new()
	flying.visible = false
	add_child(flying)   # after the Player: over the farmer

	Game.minute_passed.connect(_update_tint)
	Game.day_started.connect(_on_day_started)
	Game.map_changed.connect(func(_id): fade.run(_enter_map))
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
	view.add_child(StoryView.new(m))   # what the heart events left (the bell, the store's sign)
	view.add_child(FestivalView.new(m.id))   # today's festival decorations, in its hours
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
	_update_tint()


## The farmer is put home by the map change (Game.go_home) that comes with the new day.
func _on_day_started() -> void:
	player.cancel_charge()
	_update_tint()
	if view is FarmView:
		view.set_snow(Game.snow_cover / 100.0)


func _update_tint() -> void:
	var m := Game.maps.current()
	var f := Game.maps.mine_floor
	tint.color = Color.WHITE if f != null else (m.light if m.light != null else Game.light_color())
	mine_light.visible = f != null
	if f != null:
		mine_light.color = f.light
	_aim_lantern()


func _process(delta: float) -> void:
	_aim_lantern()
	_fly(delta)


## A throw: the item flies in an arc from over the head to the cell it ends up on (the bin,
## the pond, the ground); one that lands shows on its cell only when it gets there.
func _on_thrown(item: String, _from: Vector2i, to: Vector2i, result: String) -> void:
	flying.texture = PlaceholderArt.tex(PlaceholderArt.world_item_key(item))
	flying.visible = true
	var h := flying.texture.get_height()
	_flight = {
		"from": player.position + Vector2(0, -19 - h / 2.0), "to": Vector2(to * T) + Vector2(T / 2.0, T / 2.0),
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
