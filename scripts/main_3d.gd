extends Node3D
## The main view: a 3D farm seen through a fixed, diagonal, narrow camera that follows the
## player, with the farmer and field objects as camera-facing sprites.
##
## Camera geometry is Harvest Moon: Back to Nature's field camera, measured in the RE project
## (REA-Harvest_moon_ps1 NOTES.md "Ground truth: ePSXe save state" / "Camera"): rotation yaw 45°,
## pitch 26.6°, the player's feet 10087 units in front of the eye, projection H = 1000 on a
## 240-line screen. One cell there is 400 units, here 1 unit.

const T := 16
const CAM_BACK := Vector3(0.634, 0.448, 0.634)   # from the target towards the eye (unit)
const CAM_DIST := 10087.0 / 400.0                 # 25.2 cells
const CAM_FOV := 13.69                            # vertical, 2 * atan(120 / 1000)
const CAM_MARGIN := Vector2(4, 3)                 # keep the view inside the fence

var player: Player
var sprite: Sprite3D
var anim := FarmerAnim.new()
var target_mark: MeshInstance3D
var area_marks: Array[MeshInstance3D] = []   # brackets on every cell of a charging tool's area
var charge_pips: Sprite3D
var cam: Camera3D
var tint: ColorRect
var weather: WeatherFX
var world: FarmWorld
var flash: ColorRect
var lightning := Lightning.new()
var held_sprite: Sprite3D        # the item carried overhead
var flying: Sprite3D             # a thrown item on its way
var _flight := {}                # from, to, time, seconds, height, cell (while flying)


func _ready() -> void:
	world = FarmWorld.new()
	add_child(world)
	world.setup(Game.farm)

	# The player's movement / collision is the 2D Player (in cell pixels), kept invisible;
	# the 3D sprite follows it.
	player = Player.new()
	player.farm = Game.farm
	player.position = FarmActions.HOME
	player.visible = false
	player.action.connect(FarmActions.on_action)
	add_child(player)

	sprite = FarmWorld.make_sprite(PlaceholderArt.tex(anim.key(Vector2i.DOWN)))
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
	charge_pips.position = Vector3(0, 1.3, 0)   # over the farmer's head
	charge_pips.visible = false
	sprite.add_child(charge_pips)
	held_sprite = FarmWorld.make_sprite(PlaceholderArt.tex("item:turnip"))
	held_sprite.visible = false
	sprite.add_child(held_sprite)
	flying = FarmWorld.make_sprite(PlaceholderArt.tex("item:turnip"))
	flying.visible = false
	add_child(flying)

	cam = Camera3D.new()
	cam.fov = CAM_FOV
	cam.far = 200.0
	add_child(cam)
	cam.make_current()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("8fc6e8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 0.7
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
	var mul := CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	tint.material = mul
	layer.add_child(tint)
	# Lightning: a short wash of pale sky light added over the picture (Lightning times it).
	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flash.material = add
	flash.color = Color.BLACK
	layer.add_child(flash)
	add_child(layer)
	add_child(Hud.new())
	add_child(TextBox.new())
	add_child(PauseScreen.new())

	Game.minute_passed.connect(_update_tint)
	Game.day_started.connect(_on_day_started)
	Game.settings_changed.connect(func(): lightning.reset(Game.lightning_style()))
	Game.thrown.connect(_on_thrown)
	_update_tint()
	_follow()


func _unhandled_input(event: InputEvent) -> void:
	FarmActions.handle_input(event)


func _process(delta: float) -> void:
	anim.step(delta, player.moving, player.running, Game.body_state() != "fine", Game.holding())
	_update_flash(delta)
	_follow()
	_fly(delta)


func _follow() -> void:
	var feet := Vector3(player.position.x / T, 0, player.position.y / T)
	sprite.position = feet
	sprite.texture = PlaceholderArt.tex(anim.key(player.facing))
	sprite.flip_h = FarmerAnim.is_mirrored(player.facing)
	var tc := player.target_cell()
	target_mark.position = Vector3(tc.x + 0.5, 0.02, tc.y + 0.5)
	_show_charge()
	_show_held()

	var target := Vector3(
		clampf(feet.x, CAM_MARGIN.x, FarmGrid.W - CAM_MARGIN.x), 0,
		clampf(feet.z, CAM_MARGIN.y, FarmGrid.H - CAM_MARGIN.y))
	cam.position = target + CAM_BACK * CAM_DIST
	cam.look_at(target, Vector3.UP)
	weather.follow(target)


## While a tool charges: the brackets cover the whole area and pips count the steps.
func _show_charge() -> void:
	var cells: Array[Vector2i] = []
	if player.charging:
		cells = player.area_preview()
	target_mark.visible = not player.charging
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
		held_sprite.texture = PlaceholderArt.tex(PlaceholderArt.item_key(Game.held))
		var top := 24 - PlaceholderArt.farmer_drop(anim.pose, anim.frame()) - 1
		held_sprite.position = Vector3(0, top * FarmWorld.PX, 0)


## A throw: the item flies in an arc from over the head to where it ends up; one that lands
## on the ground shows on its cell only when it gets there.
func _on_thrown(item: String, _from: Vector2i, to: Vector2i, result: String) -> void:
	var end_y := 0.0
	if result == "ship":
		end_y = 0.6    # into the bin under its lid
	flying.texture = PlaceholderArt.tex(PlaceholderArt.item_key(item))
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


func _on_day_started() -> void:
	player.position = FarmActions.HOME
	player.facing = Vector2i.DOWN
	player.cancel_charge()
	weather.show_weather(Game.weather_style())
	lightning.reset(Game.lightning_style())
	world.set_snow(Game.snow_cover / 100.0)
	_update_tint()


func _update_flash(delta: float) -> void:
	var b := lightning.step(delta) if Game.ticking() else 0.0
	if lightning.started: Sfx.thunder_after_flash()
	var style := Game.lightning_style()
	var sky := Color(style.get("sky", "ffffff")) * float(style.get("strength", 0.0)) * b
	flash.color = Color(sky.r, sky.g, sky.b, 1.0)


func _update_tint() -> void:
	tint.color = Game.light_color()
