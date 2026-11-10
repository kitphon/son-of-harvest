extends Node3D
## The main view: a 3D farm seen through a fixed, diagonal, narrow camera that follows the
## player, with the farmer and field objects as camera-facing sprites. Other maps (the house,
## the village) are MapWorlds; a change of map fades out, rebuilds the world and fades in.
##
## Camera geometry is Harvest Moon: Back to Nature's field camera, measured in the RE project
## (REA-Harvest_moon_ps1 NOTES.md "Ground truth: ePSXe save state" / "Camera"): rotation yaw 45°,
## pitch 26.6°, the player's feet 10087 units in front of the eye, projection H = 1000 on a
## 240-line screen. One cell there is 400 units, here 1 unit. That is the "ps1" lens in
## data/camera.json (CameraLens); the game now uses its wider "medium" lens (the file says which).

const T := 16
const CAM_MARGIN := Vector2(4, 3)                 # keep the view inside the fence
## The light: a warm sun over a cool sky light, so shade is a little blue. Ambient + sun on
## flat ground add up to about white (the ground shader scales the sun to SnowLayer.SUN_SHARE),
## so sunlit ground keeps its picture's colours and shade falls to the ambient alone.
const SUN_COLOR := Color(1.0, 0.93, 0.8)
const SUN_ENERGY := 0.7
const SKY_LIGHT := Color(0.82, 0.88, 1.0)
const SKY_ENERGY := 0.6

var player: Player
var sprite: Sprite3D
var anim := FarmerAnim.new()
var target_mark: MeshInstance3D
var area_marks: Array[MeshInstance3D] = []   # brackets on every cell of a charging tool's area
var charge_pips: Sprite3D
var cam: Camera3D
var lens := CameraLens.current()
var tint: ColorRect
var _mul: CanvasItemMaterial       # the tint's plain multiply
var _lantern: ShaderMaterial       # the tint down the mine: the floor's light and the lantern
var weather: WeatherFX
var world: FarmWorld
var env: Environment
var sun: DirectionalLight3D
var lamps: NightLamps
var flash: ColorRect
var fade: MapFade
## Worlds built earlier today, kept out of the tree for going back (a map build is a long frame):
## map id -> {key: what it was built for (world_key), world}. The newest KEEP_WORLDS are kept.
var _worlds := {}
var _world_order: Array[String] = []   # oldest first
const KEEP_WORLDS := 6
## Building the maps next door ahead (_prebuild): the frame's budget, how long the farmer must
## stand still first, and the maps never built ahead (a mine floor is made fresh each time).
const PREBUILD_MS := 4.0
const PREBUILD_WAIT := 0.4
const PREBUILD_SKIP: Array[String] = ["mine_floor"]
var prebuild := true            # false: no building ahead
var prebuilt := 0                # worlds built ahead so far (tests)
var _pre := {}                   # the one under way: {id, key, world, steps, next}
var _still := 0.0                # seconds the farmer has stood still (with no fade)
## Shader warm-up (ShaderWarm): the new kinds of material of a map entered are drawn once while
## the fade holds black (the first map under MapFade.cover), one of those frames with the sun's
## shadows the other way round (_warm_step), then taken away.
var warm := true
var _warm: Node3D
var _warm_frames := 0           # frames drawn with the warm-up after its first
var _layers: Array[Node] = []   # this visit's layers on the world (villagers, forage, animals ...)
var lightning := Lightning.new()
var held_sprite: Sprite3D        # the item carried overhead
var lantern_sprite: Sprite3D     # the lantern in the farmer's hand down the mine
var flying: Sprite3D             # a thrown item on its way
var _flight := {}                # from, to, time, seconds, height, cell (while flying)
var bobber: Sprite3D             # the float on the water while the line is out
var bite_mark: Sprite3D          # the "!" over the head when a fish bites
var fish_line: MeshInstance3D    # from the rod tip to the bobber
var _line_mesh := ImmediateMesh.new()
const RING_EVERY := 1.7            # seconds between the gentle rings round a waiting bobber
const RING_BITE_EVERY := 0.4       # and between the strong ones in a bite
var _ring_state := "idle"
var _ring_next := 0.0


func _ready() -> void:
	# The player's movement / collision is the 2D Player (in cell pixels), kept invisible;
	# the 3D sprite follows it.
	player = Player.new()
	player.farm = Game.farm
	player.visible = false
	add_child(player)

	sprite = FarmWorld.make_figure(PlaceholderArt.tex(anim.key(Vector2i.DOWN)))
	NightLights.figure(sprite)   # lit windows behind the farmer don't glow over them
	add_child(sprite)
	SpriteShadow.attach(sprite)   # blob and the sun's real shadow (data/light.json "sprite_shadows")

	target_mark = MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(1, 1)
	target_mark.mesh = quad
	# Brackets on the cell in front, where the tool lands (not the cell the farmer stands on).
	var mark_mat := FarmWorld.flat_material(Color(1, 1, 1, 0.99))
	mark_mat.albedo_texture = PlaceholderArt.tex("target")
	mark_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	target_mark.material_override = mark_mat
	add_child(target_mark)
	charge_pips = FarmWorld.make_sprite(PlaceholderArt.tex(PlaceholderArt.charge_key(0, 1)))
	charge_pips.position = Vector3(0, 1.38, 0)   # over the farmer's head (its top about 1.17)
	charge_pips.visible = false
	SpriteLight.unlit(charge_pips)   # a mark, as drawn
	sprite.add_child(charge_pips)
	held_sprite = FarmWorld.make_sprite(PlaceholderArt.tex("item:turnip"))
	held_sprite.visible = false
	sprite.add_child(held_sprite)
	lantern_sprite = FarmWorld.make_sprite(PlaceholderArt.tex("mine:lantern"))
	lantern_sprite.offset.y = -lantern_sprite.texture.get_height() / 2.0   # hangs from its top
	lantern_sprite.visible = false
	SpriteLight.unlit(lantern_sprite)   # it gives light
	sprite.add_child(lantern_sprite)
	flying = FarmWorld.make_sprite(PlaceholderArt.tex("item:turnip"))
	flying.visible = false
	add_child(flying)
	bobber = FarmWorld.make_sprite(PlaceholderArt.tex("fish_fx:bobber"))
	bobber.visible = false
	add_child(bobber)
	bite_mark = FarmWorld.make_sprite(PlaceholderArt.tex("fish_fx:alert"))
	bite_mark.position = Vector3(0, 1.3, 0)   # clear of the head
	bite_mark.visible = false
	SpriteLight.unlit(bite_mark)   # a mark, as drawn
	sprite.add_child(bite_mark)
	fish_line = MeshInstance3D.new()
	fish_line.mesh = _line_mesh
	fish_line.material_override = FarmWorld.flat_material(Color(0.95, 0.95, 0.9, 0.8))
	add_child(fish_line)

	cam = Camera3D.new()
	cam.fov = lens.fov
	cam.far = 200.0
	add_child(cam)
	cam.make_current()

	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("8fc6e8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = SKY_LIGHT
	env.ambient_light_energy = SKY_ENERGY
	env.glow_enabled = true   # a soft bloom on the brightest things (snow, festival lights)
	env.glow_intensity = 0.4
	env.glow_hdr_threshold = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	# From the upper left of the screen: the walls turned down-left (the long fronts) are
	# sunlit and shadows fall to the right, where they show (not behind what casts them).
	# This is the plain sun of rooms, mines and the night; outdoors by day _aim_sun moves it
	# with the clock (data/light.json "sun").
	sun.rotation_degrees = Vector3(-48, -40, 0)
	sun.light_color = SUN_COLOR
	sun.light_energy = SUN_ENERGY
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 45.0   # the eye is 25 cells away; the view is narrow
	add_child(sun)

	weather = WeatherFX.new()
	add_child(weather)
	weather.show_weather(Game.weather_style())
	lightning.reset(Game.lightning_style())

	# Day / night and the weather tint: multiply the whole 3D picture, under the HUD.
	var layer := CanvasLayer.new()
	layer.layer = 0
	tint = ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mul = CanvasItemMaterial.new()
	_mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	_lantern = MineLight.material()
	tint.material = _mul
	layer.add_child(tint)
	lamps = NightLamps.new()   # real warm lights at lit windows, lanterns and festival lights
	lamps.tint = tint
	add_child(lamps)
	# Lightning: a short wash of pale sky light added over the picture (Lightning times it).
	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flash.material = add
	flash.color = Color.BLACK
	layer.add_child(flash)
	layer.add_child(NightLights.new())    # lit house windows, over the night tint
	layer.add_child(FestivalGlow.new())  # festival lanterns and fireworks, over the night tint
	layer.add_child(DriftGlow.new())     # summer fireflies, over the night tint
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

	Game.minute_passed.connect(_update_tint)
	Game.day_started.connect(_on_day_started)
	Game.minute_passed.connect(func(): world.age_prints(1.0))   # footprints in snow fill in
	Game.map_changed.connect(func(_id): fade.run(_enter_map))
	Game.settings_changed.connect(func(): lightning.reset({} if Game.sheltered() else Game.lightning_style()))
	Game.thrown.connect(_on_thrown)
	Game.fishing_event.connect(func(kind): FarmActions.on_fishing_event(kind))
	if warm:
		fade.cover()   # the first map is built and warmed behind black too (no fade led here)
	_enter_map()
	Game.map_arrived()
	FarmActions.connect_view(player)   # the actions, and the --talk flag


## Builds the world for Game.maps and puts the farmer where it says.
func _enter_map() -> void:
	var m := Game.maps.current()
	var key := world_key(m)
	var kept: Dictionary = _worlds.get(m.id, {})
	if not kept.is_empty() and kept.key == key:
		_worlds.erase(m.id)   # taken out first, so keeping the world left can't drop it
		_world_order.erase(m.id)
	else:
		kept = {}
	_leave_world()
	if kept.is_empty():
		kept = _worlds.get(m.id, {})   # the same map again: the world just left
	if not kept.is_empty() and kept.key == key:
		world = kept.world   # been here today and nothing changed: no rebuild
		world.come_back()
		_worlds.erase(m.id)
		_world_order.erase(m.id)
	else:
		if not kept.is_empty():
			_drop_world(m.id)
		if not _pre.is_empty() and _pre.id == m.id and _pre.key == key:
			world = _pre.world   # was being built ahead: only the rest of its steps now
			for i in range(_pre.next, _pre.steps.size()):
				_pre.steps[i].call()
			_pre = {}
		else:
			var made := new_world(m)
			world = made[0]
			for step: Callable in made[1]:
				step.call()
		world.set_meta("key", key)
		world.set_meta("map_id", m.id)
	world.clear_prints()   # no trail from before the map change
	_stop_prebuild()
	_still = 0.0
	if world.backdrop != null:
		world.backdrop.refresh()
	_add_layer(FestivalProps.new(m.id))   # today's festival decorations, in its hours
	_add_layer(VillagerSprites.new(m.id))
	_add_layer(ForageLayer.new(m.id))   # what grows wild there today (data/forage.json)
	_add_layer(CradleLayer.new(m.id))   # the baby's cradle in the second room, while the child is a baby
	add_child(world)
	move_child(world, 0)
	var animals := AnimalLayer.new()   # the animals, eggs and feed (coop, barn, or the farm and its dog)
	_add_layer(animals)
	animals.setup(m, Game.maps.on_farm(), player)
	if Game.maps.mine_floor != null:   # rocks, soft spots and the hole down
		var rocks := MineLayer.new()
		_add_layer(rocks)
		rocks.setup(Game.maps.mine_floor)
	player.farm = Game.farm
	player.position = Game.maps.pos
	player.facing = Game.maps.facing
	player.cancel_charge()
	target_mark.visible = _tools_work()
	_show_weather()
	if Game.demo_footprints:   # `--footprints`: a trail already there to look at
		world.seed_prints(Vector3(player.position.x / T, 0, player.position.y / T))
	_update_tint()
	_follow()
	_end_warm()
	if warm and fade.busy():
		_warm = ShaderWarm.show(self, cam, ShaderWarm.news(world))
		_warm_frames = 0


## Takes the warm-up quads away (before the picture comes back from black), the sun's shadows
## as they should be.
func _end_warm() -> void:
	if _warm != null:
		_warm.free()
		_warm = null
		_show_shadows(_inside())


## One frame of the warm-up after the first (the screen still black): the sun's shadows the
## other way round, so the quads (and the world under the black) also draw the variant they
## have with them off (night, rooms) or on (day outdoors). Measured 2026-11-07: the village's
## frame at dusk when the sun's shadows went off took 450..560 ms before.
func _warm_step() -> void:
	_warm_frames += 1
	if _warm_frames == 1:
		sun.shadow_enabled = not sun.shadow_enabled
		if sun.shadow_enabled:
			sun.shadow_opacity = 1.0
	elif _warm_frames == 2:
		_show_shadows(_inside())


## A room, a mine floor or a map with its own light: the plain sun, no sun shadows.
func _inside() -> bool:
	var m := Game.maps.current()
	return m.indoor or Game.maps.mine_floor != null or m.light != null


## A new world for map `m` (not built yet) and its build steps, in order: the farm (FarmWorld,
## its story props last) or another map (MapWorld).
static func new_world(m: MapData) -> Array:
	if m.farm:
		var fw := FarmWorld.new()
		var steps := fw.setup_steps(Game.farm, m.gate_cells())
		steps.append(func() -> void: fw.add_child(DriftLayer.new(m, Game.farm)))   # petals, leaves, fireflies
		steps.append(func() -> void: fw.add_child(PuddleLayer.new(m, Game.farm)))   # puddles in rain
		steps.append(fw.make_story_props.bind(m))   # the door bell, once Hachiro has given it
		return [fw, steps]
	var mw := MapWorld.new()
	return [mw, mw.build_steps(m)]


## Builds the maps next door ahead, while the farmer stands still (PREBUILD_WAIT seconds), a
## few steps a frame (PREBUILD_MS), so going through the door finds the world ready (kept as
## if visited). Outdoor maps first (the dearer builds); never more than KEEP_WORLDS kept (room
## is made by dropping a kept map that is not next door), never a mine floor; a change of map
## finishes the one under way if it is the map entered, or drops it.
func _prebuild(delta: float) -> void:
	if not prebuild or fade.busy() or Game.maps.mine_floor != null or player.moving or player.charging:
		_still = 0.0
		return
	_still += delta
	if _still < PREBUILD_WAIT:
		return
	if _pre.is_empty():
		var m := _next_prebuild()
		if m == null:
			return
		var made := new_world(m)
		_pre = {"id": m.id, "key": world_key(m), "world": made[0], "steps": made[1], "next": 0}
	var start := Time.get_ticks_usec()
	while _pre.next < _pre.steps.size() and (Time.get_ticks_usec() - start) < PREBUILD_MS * 1000.0:
		_pre.steps[_pre.next].call()
		_pre.next += 1
	if _pre.next < _pre.steps.size():
		return
	var w: FarmWorld = _pre.world
	var id: String = _pre.id
	var key: String = _pre.key
	_pre = {}
	if MapManager.data(id) == null or world_key(MapManager.data(id)) != key or (_worlds.has(id) and _worlds[id].key == key):
		w.queue_free()   # its map changed meanwhile (a flag, an extension)
		return
	_drop_world(id)   # one kept from before the change, if any
	w.set_meta("key", key)
	w.set_meta("map_id", id)
	w.away = true
	_worlds[id] = {"key": key, "world": w}
	_world_order.append(id)
	prebuilt += 1
	_trim_worlds()


## The next map to build ahead: a door's map from here not kept yet (outdoor ones first), or
## null; nothing when the kept worlds are KEEP_WORLDS of the maps next door already.
func _next_prebuild() -> MapData:
	var near := _maps_next_door()
	if _worlds.size() >= KEEP_WORLDS and _spare_world(near) == "":
		return null
	for m in near:
		if not (_worlds.has(m.id) and _worlds[m.id].key == world_key(m)):
			return m
	return null


## The maps the doors here lead to (none built fresh each time: PREBUILD_SKIP), outdoor first.
func _maps_next_door() -> Array[MapData]:
	var here := Game.maps.current()
	var outdoor: Array[MapData] = []
	var indoor: Array[MapData] = []
	for door in here.doors:
		var to := str(door.to)
		if to == "" or to == here.id or to in PREBUILD_SKIP or not MapManager.has(to):
			continue
		var m := MapManager.data(to)
		if m == null or m in outdoor or m in indoor:
			continue
		(indoor if m.indoor else outdoor).append(m)
	return outdoor + indoor


## The kept world to drop first: the oldest of a map not next door (`near`), "" when all are.
func _spare_world(near: Array[MapData]) -> String:
	var ids := near.map(func(m: MapData) -> String: return m.id)
	for id in _world_order:
		if not id in ids:
			return id
	return ""


## Keeps KEEP_WORLDS worlds at most, dropping the oldest of maps not next door first.
func _trim_worlds() -> void:
	while _world_order.size() > KEEP_WORLDS:
		var id := _spare_world(_maps_next_door())
		_drop_world(id if id != "" else _world_order[0])


func _stop_prebuild() -> void:
	if not _pre.is_empty():
		(_pre.world as Node).free()
		_pre = {}


## What a world was built for: the map (a new MapData when its story props or extensions
## change), the farm, the day, the weather and the snow lying. A kept world with the same key is
## used again; a mine floor ("" here) is always built fresh.
static func world_key(m: MapData) -> String:
	if Game.maps.mine_floor != null:
		return ""
	return "%d/%d/%d-%d-%d/%s/%d" % [m.get_instance_id(), Game.farm.get_instance_id(), Game.year, Game.season, Game.day,
		Game.weather_today, Game.snow_cover]


## Takes this visit's layers off the world and keeps the world (out of the tree) for going back.
func _leave_world() -> void:
	for n in _layers:
		if is_instance_valid(n):
			n.get_parent().remove_child(n)
			n.queue_free()
	_layers.clear()
	if world == null:
		return
	remove_child(world)
	var id := str(world.get_meta("map_id", ""))
	var key := str(world.get_meta("key", ""))
	if world.hidden_item != Vector2i(-1, -1):
		world.hidden_item = Vector2i(-1, -1)
	if key == "" or id == "":
		world.queue_free()
	else:
		_drop_world(id)
		world.away = true   # the farm's field changes wait until it is back
		_worlds[id] = {"key": key, "world": world}
		_world_order.append(id)
		_trim_worlds()
	world = null


func _drop_world(id: String) -> void:
	if _worlds.has(id):
		_worlds[id].world.queue_free()
		_worlds.erase(id)
	_world_order.erase(id)


func _add_layer(n: Node) -> void:
	world.add_child(n)
	_layers.append(n)


## Frees the kept worlds (a new day, and leaving the view).
func _drop_worlds() -> void:
	for id in _worlds.keys():
		_drop_world(id)


func _exit_tree() -> void:
	_end_warm()
	_stop_prebuild()
	_drop_worlds()


## Do the tools work here (the farm, a mine floor)? Then the target brackets show.
func _tools_work() -> bool:
	return Game.maps.on_farm() or Game.maps.mine_floor != null


## Weather falls outdoors only (not in buildings or the mine); the ground outdoors shows the snow lying.
func _show_weather() -> void:
	weather.show_weather({} if Game.sheltered() else Game.weather_style())
	lightning.reset({} if Game.sheltered() else Game.lightning_style())
	world.set_snow(Game.snow_cover / 100.0)
	world.set_wind(0.0 if Game.sheltered() else Game.wind_strength())
	world.set_rain({} if Game.sheltered() else Game.dimple_style())
	world.set_ice({} if Game.sheltered() else Game.ice_style(), Game.snow_cover / 100.0)


func _unhandled_input(event: InputEvent) -> void:
	FarmActions.handle_input(event)


func _process(delta: float) -> void:
	anim.step(delta, player.moving, player.running, Game.body_state() != "fine", Game.holding(), Game.fishing.state, Game.eat_pose, Game.scoop_pose())
	_update_flash(delta)
	_follow()
	world.occluders.update(sprite.position, lens.back, delta)
	world.set_farmer(sprite.position)   # the grass and tall crops part round the feet
	_aim_lantern()
	_fly(delta)
	_show_fishing()
	_prebuild(delta)
	if _warm != null and not fade.holding():
		_end_warm()
	elif _warm != null:
		_warm_step()


func _follow() -> void:
	var feet := Vector3(player.position.x / T, 0, player.position.y / T)
	sprite.position = feet
	sprite.texture = PlaceholderArt.tex(anim.key(player.facing))
	sprite.flip_h = FarmerAnim.is_mirrored(player.facing)
	var tc := player.target_cell()
	target_mark.position = Vector3(tc.x + 0.5, 0.02, tc.y + 0.5)
	if _tools_work():
		_show_charge()
	_show_held()
	_show_lantern()

	var m := Game.maps.current()
	var target := Vector3(_clamp_view(feet.x, CAM_MARGIN.x, m.w), 0, _clamp_view(feet.z, CAM_MARGIN.y, m.h))
	cam.position = target + lens.back * lens.dist
	cam.look_at(target, Vector3.UP)
	weather.follow(target)


## The camera target kept `margin` inside a map side of `size`; a small room stays centred.
static func _clamp_view(v: float, margin: float, size: int) -> float:
	if size <= margin * 2:
		return size / 2.0
	return clampf(v, margin, size - margin)


## While a tool charges: the brackets cover the whole area and pips count the steps.
func _show_charge() -> void:
	var cells: Array[Vector2i] = []
	if player.charging:
		cells = player.area_preview()
	target_mark.visible = not player.charging and not Game.fishing.active()
	while area_marks.size() < cells.size():
		var m := MeshInstance3D.new()
		m.mesh = target_mark.mesh
		m.material_override = target_mark.material_override
		add_child(m)
		area_marks.append(m)
	for i in area_marks.size():
		area_marks[i].visible = i < cells.size()
		if i < cells.size():
			area_marks[i].position = Vector3(cells[i].x + 0.5, 0.02, cells[i].y + 0.5)
	charge_pips.visible = player.charging
	if player.charging:
		charge_pips.texture = PlaceholderArt.tex(
			PlaceholderArt.charge_key(player.charge, Game.max_charge(Game.current_tool())))


## The held item rests on the raised hands at the top of the sprite and bobs with the body.
func _show_held() -> void:
	held_sprite.visible = Game.holding()
	if Game.holding():
		held_sprite.texture = PlaceholderArt.tex(Game.held_key())
		var top := PlaceholderArt.FIGURE_SIZE.y - PlaceholderArt.hold_row(anim.pose, anim.frame())
		held_sprite.position = Vector3(0, top * FarmWorld.FIGURE_PX, 0)


## Down the mine the lantern hangs at its pixel on the farmer's frame (PlaceholderArt.lantern_at),
## placed along the camera's right and up like the rod tip, a hair towards the camera so it
## shows in front of the body.
func _show_lantern() -> void:
	lantern_sprite.visible = Game.maps.mine_floor != null
	if not lantern_sprite.visible:
		return
	var at := PlaceholderArt.lantern_at(anim.pose, anim.frame(), FarmerAnim.is_back(player.facing))
	var axes := cam.global_transform.basis
	var fig := PlaceholderArt.FIGURE_SIZE
	var side := (at.x + 3.5 - fig.x / 2.0) * (-1.0 if sprite.flip_h else 1.0)
	lantern_sprite.position = axes.x * side * FarmWorld.FIGURE_PX + axes.y * (fig.y - at.y) * FarmWorld.FIGURE_PX + axes.z * 0.02


## While the line is out: the bobber rocks on its cell (on a bite it dips under and shakes),
## the line runs from the rod tip to it, and a "!" pops up over the head on a bite.
func _show_fishing() -> void:
	var f := Game.fishing
	_ring_bobber(f)
	bobber.visible = f.active()
	bite_mark.visible = f.state == "bite"
	fish_line.visible = f.active()
	if not f.active():
		return
	var bite := f.state == "bite"
	var dip := -3.0 * FarmWorld.PX if bite else sin(f.time * 3.0) * 0.4 * FarmWorld.PX
	var shake := sin(f.time * 40.0) * FarmWorld.PX if bite else 0.0
	bobber.position = Vector3(f.spot.x + 0.5 + shake, dip, f.spot.y + 0.5)
	# The rod tip: a pixel of the billboard sprite, so along the camera's right and up.
	var tip := PlaceholderArt.rod_tip(anim.pose, anim.frame())
	var axes := cam.global_transform.basis
	var fig := PlaceholderArt.FIGURE_SIZE
	var side := (tip.x + 0.5 - fig.x / 2.0) * (-1.0 if sprite.flip_h else 1.0)
	var from := sprite.position + axes.x * side * FarmWorld.FIGURE_PX + axes.y * (fig.y - tip.y - 0.5) * FarmWorld.FIGURE_PX
	_line_mesh.clear_surfaces()
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_line_mesh.surface_add_vertex(from)
	_line_mesh.surface_add_vertex(bobber.position + Vector3(0, 5.5 * FarmWorld.PX, 0))
	_line_mesh.surface_end()


## Ripple rings on the water round the bobber: a strong one as it lands, a gentle one every
## RING_EVERY seconds while it waits, and strong ones as a fish bites.
func _ring_bobber(f: Fishing) -> void:
	var was := _ring_state
	_ring_state = f.state
	if not f.active():
		return
	var sheet: WaterSurface = null
	if world != null and world.surroundings != null:
		sheet = world.surroundings.water
	if sheet == null:
		return
	var at := Vector2(f.spot.x + 0.5, f.spot.y + 0.5)
	if was == "idle" or (f.state == "bite" and was != "bite"):
		sheet.ripple(at, true)
		_ring_next = RING_EVERY if f.state == "wait" else RING_BITE_EVERY
		return
	_ring_next -= get_process_delta_time()
	if _ring_next <= 0.0:
		sheet.ripple(at, f.state == "bite")
		_ring_next = RING_EVERY if f.state == "wait" else RING_BITE_EVERY


## A throw: the item flies in an arc from over the head to where it ends up; one that lands
## on the ground shows on its cell only when it gets there.
func _on_thrown(item: String, _from: Vector2i, to: Vector2i, result: String) -> void:
	var end_y := 0.0
	if result == "ship":
		end_y = 0.6    # into the bin under its lid
	flying.texture = PlaceholderArt.tex(PlaceholderArt.world_item_key(item))
	flying.visible = true
	_flight = {
		"from": sprite.position + held_sprite.position, "to": Vector3(to.x + 0.5, end_y, to.y + 0.5),
		"time": 0.0, "seconds": float(Game.hold_rules.get("flight_seconds", 0.35)),
		"height": float(Game.hold_rules.get("arc_height", 1.2)),
	}
	world.hidden_item = to if result == "land" else Vector2i(-1, -1)
	_fly(0.0)


func _fly(delta: float) -> void:
	if _flight.is_empty():
		return
	_flight.time += delta
	var t := clampf(_flight.time / maxf(_flight.seconds, 0.01), 0.0, 1.0)
	var p: Vector3 = _flight.from.lerp(_flight.to, t)
	p.y += _flight.height * 4.0 * t * (1.0 - t)
	flying.position = p
	if t >= 1.0:
		flying.visible = false
		_flight = {}
		world.hidden_item = Vector2i(-1, -1)


## The farmer is put home by the map change (Game.go_home) that comes with the new day.
func _on_day_started() -> void:
	_stop_prebuild()
	_drop_worlds()   # built for yesterday
	world.clear_prints()
	player.cancel_charge()
	_show_weather()
	_update_tint()


func _update_flash(delta: float) -> void:
	var b := lightning.step(delta) if Game.ticking() else 0.0
	if lightning.started: Sfx.thunder_after_flash()
	flash.color = Lightning.flash_color(Game.lightning_style(), b)


## Day / night light outdoors; a room has its own steady lamp light; a mine floor its own
## (darker deeper) with the farmer's lantern. The clear colour behind the land follows the
## clock outdoors too (Game.sky_background; rooms and mines keep their map's background).
func _update_tint() -> void:
	var m := Game.maps.current()
	var f := Game.maps.mine_floor
	tint.material = _lantern if f != null else _mul
	tint.color = f.light if f != null else (m.light if m.light != null else Game.light_color())
	var inside := _inside()
	env.background_color = Game.sky_background(inside, m.background)
	_aim_sun(inside)
	_show_shadows(inside)
	_aim_lantern()


## The sun follows the clock outdoors (Game.sun_light, data/light.json "sun"): low and golden
## in the morning and evening, high and plain at midday, back to the plain fixed sun under
## the night tint. Rooms and mine floors keep the plain sun.
func _aim_sun(inside: bool) -> void:
	var s := Game.sun_light(inside)
	sun.rotation_degrees = Vector3(-float(s.elevation), float(s.yaw), 0)
	sun.light_color = s.color
	sun.light_energy = s.energy
	SpriteShadow.sun_yaw = SpriteShadow.face_yaw(Game.sun_direction(s))
	# The sprites take a share of the sun's colour (SpriteLight; white for the plain sun).
	SpriteLight.apply(get_tree(), SpriteLight.sun_tint(s.color, SpriteLight.rules_of(Game.light_data())))


## Sun shadows outdoors only (Game.sun_shadow: by the daylight and the sky).
func _show_shadows(inside: bool) -> void:
	var strength := 0.0 if inside else Game.sun_shadow()
	sun.shadow_enabled = strength > 0.0
	sun.shadow_opacity = strength
	SpriteShadow.sun_strength = strength


## The lantern circle follows the farmer on screen, one cell measured across at their feet.
func _aim_lantern() -> void:
	var f := Game.maps.mine_floor
	if f == null or tint.material != _lantern:
		return
	var at := sprite.global_position + Vector3(0, 0.6, 0)
	if not cam.is_inside_tree() or cam.is_position_behind(at):   # before the camera follows on a new map
		return
	var center := cam.unproject_position(at)
	var cell := center.distance_to(cam.unproject_position(at + cam.global_basis.x))
	MineLight.aim(_lantern, f, center, cell, tint.size)
