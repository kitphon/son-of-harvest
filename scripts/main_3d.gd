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
	var shadow := MeshInstance3D.new()
	var disc := PlaneMesh.new()
	disc.size = Vector2(0.6, 0.6)
	shadow.mesh = disc
	shadow.material_override = FarmWorld.flat_material(Color(0, 0, 0, 0.3))
	shadow.position = Vector3(0, 0.01, 0)
	sprite.add_child(shadow)

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
	sprite.add_child(charge_pips)
	held_sprite = FarmWorld.make_sprite(PlaceholderArt.tex("item:turnip"))
	held_sprite.visible = false
	sprite.add_child(held_sprite)
	lantern_sprite = FarmWorld.make_sprite(PlaceholderArt.tex("mine:lantern"))
	lantern_sprite.offset.y = -lantern_sprite.texture.get_height() / 2.0   # hangs from its top
	lantern_sprite.visible = false
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
	add_child(EndingScreen.new())
	add_child(EventPlayer.new(player))   # after the Player: moves it during events

	Game.minute_passed.connect(_update_tint)
	Game.day_started.connect(_on_day_started)
	Game.map_changed.connect(func(_id): fade.run(_enter_map))
	Game.settings_changed.connect(func(): lightning.reset({} if Game.sheltered() else Game.lightning_style()))
	Game.thrown.connect(_on_thrown)
	Game.fishing_event.connect(func(kind): FarmActions.on_fishing_event(kind))
	_enter_map()
	Game.map_arrived()
	FarmActions.connect_view(player)   # the actions, and the --talk flag


## Builds the world for Game.maps and puts the farmer where it says.
func _enter_map() -> void:
	if world != null:
		world.queue_free()
	var m := Game.maps.current()
	if Game.maps.on_farm():
		world = FarmWorld.new()
		world.setup(Game.farm, m.gate_cells())
		world.make_story_props(m)   # the door bell, once Hachiro has given it
	else:
		world = MapWorld.new()
		(world as MapWorld).build(m)
	world.add_child(FestivalProps.new(m.id))   # today's festival decorations, in its hours
	world.add_child(VillagerSprites.new(m.id))
	world.add_child(ForageLayer.new(m.id))   # what grows wild there today (data/forage.json)
	add_child(world)
	move_child(world, 0)
	var animals := AnimalLayer.new()   # the animals, eggs and feed (coop, barn, or the farm and its dog)
	world.add_child(animals)
	animals.setup(m, Game.maps.on_farm(), player)
	if Game.maps.mine_floor != null:   # rocks, soft spots and the hole down
		var rocks := MineLayer.new()
		world.add_child(rocks)
		rocks.setup(Game.maps.mine_floor)
	player.farm = Game.farm
	player.position = Game.maps.pos
	player.facing = Game.maps.facing
	player.cancel_charge()
	target_mark.visible = _tools_work()
	_show_weather()
	_update_tint()
	_follow()


## Do the tools work here (the farm, a mine floor)? Then the target brackets show.
func _tools_work() -> bool:
	return Game.maps.on_farm() or Game.maps.mine_floor != null


## Weather falls outdoors only (not in buildings or the mine); the ground outdoors shows the snow lying.
func _show_weather() -> void:
	weather.show_weather({} if Game.sheltered() else Game.weather_style())
	lightning.reset({} if Game.sheltered() else Game.lightning_style())
	world.set_snow(Game.snow_cover / 100.0)
	world.set_wind(0.0 if Game.sheltered() else Game.wind_strength())


func _unhandled_input(event: InputEvent) -> void:
	FarmActions.handle_input(event)


func _process(delta: float) -> void:
	anim.step(delta, player.moving, player.running, Game.body_state() != "fine", Game.holding(), Game.fishing.state, Game.eat_pose)
	_update_flash(delta)
	_follow()
	world.occluders.update(sprite.position, lens.back, delta)
	world.set_farmer(sprite.position)   # the grass and tall crops part round the feet
	_aim_lantern()
	_fly(delta)
	_show_fishing()


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
	var inside := m.indoor or f != null or m.light != null
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


## Sun shadows outdoors only (Game.sun_shadow: by the daylight and the sky).
func _show_shadows(inside: bool) -> void:
	var strength := 0.0 if inside else Game.sun_shadow()
	sun.shadow_enabled = strength > 0.0
	sun.shadow_opacity = strength


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
