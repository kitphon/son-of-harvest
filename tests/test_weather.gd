extends SceneTree
## Headless checks for snow lying on the ground and lightning timing. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_weather.gd

var failures := 0


func _init() -> void:
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/snow_cover.json"))
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weather_fx.json"))
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))

	# Snow cover: snowfall builds it up, a blizzard covers all, clear winter days thin it,
	# rain washes more away, and it is gone the first day after winter.
	var next := func(cover: int, look: String, season_id: String) -> int:
		return game_script.next_snow_cover(cover, look, season_id, rules)
	check(next.call(0, "sunny", "winter") == 0, "no snow, no cover")
	var one: int = next.call(0, "snow", "winter")
	check(one > 0 and one < 100, "a snow day lays some snow (%d)" % one)
	check(next.call(one, "snow", "winter") > one, "more snow piles up")
	check(next.call(0, "blizzard", "winter") == 100, "a blizzard covers everything")
	check(next.call(100, "blizzard", "winter") == 100, "cover tops out at 100")
	var thin: int = next.call(100, "sunny", "winter")
	check(thin > 0 and thin < 100, "a clear winter day thins it (%d)" % thin)
	var days := 0
	var c := 100
	while c > 0 and days < 30:
		c = next.call(c, "sunny", "winter")
		days += 1
	check(days >= 3 and days <= 10, "full cover lasts a few clear winter days (%d)" % days)
	check(next.call(60, "rain", "winter") < next.call(60, "sunny", "winter"), "rain melts more")
	for season_id in ["spring", "summer", "fall"]:
		check(next.call(100, "sunny", season_id) == 0, "snow gone on a %s day" % season_id)
	check(next.call(40, "snow", "spring") > 40, "a late snow day still lays snow")

	# Through Game: the cover is updated each morning from today's weather (winter storm = blizzard).
	var g: Node = game_script.new()
	g.crops = crops
	g.snow_rules = rules
	g.weather_fx = fx
	g.rng.seed = 3
	g.farm = FarmGrid.new(crops)
	g.farm.generate(g.rng)
	g.season = 3
	g.day = 28
	g.weather_tomorrow = "storm"
	g.end_day()
	check(g.weather_today == "storm" and g.snow_cover == 100, "winter storm morning: full snow (%d)" % g.snow_cover)
	g.weather_tomorrow = "sunny"
	g.end_day()
	check(g.snow_cover > 0 and g.snow_cover < 100, "winter 30, clear: snow thins (%d)" % g.snow_cover)
	g.weather_tomorrow = "sunny"
	g.end_day()
	check(g.season == 0 and g.snow_cover == 0, "spring 1: snow gone (%d)" % g.snow_cover)

	# How much snow each ground holds: grass the most, tilled and wet soil less, water none.
	for x in [10, 11]:
		g.farm.cell(Vector2i(x, 10)).obj = FarmGrid.Obj.NONE
		g.farm.till(Vector2i(x, 10))
	g.farm.water_cell(Vector2i(11, 10))
	var grass := Vector2i(12, 12)
	g.farm.cell(grass).obj = FarmGrid.Obj.NONE
	var h_grass := SnowLayer.hold(g.farm, grass, rules)
	var h_tilled := SnowLayer.hold(g.farm, Vector2i(10, 10), rules)
	var h_wet := SnowLayer.hold(g.farm, Vector2i(11, 10), rules)
	check(h_grass == 1.0 and h_tilled < h_grass and h_wet < h_tilled and h_wet > 0.0, "grass > tilled > wet soil (%s %s %s)" % [h_grass, h_tilled, h_wet])
	var mask := SnowLayer.mask_image(g.farm, rules)
	var k := SnowLayer.MASK_PER_CELL
	check(mask.get_size() == Vector2i(FarmGrid.W * k, FarmGrid.H * k), "mask covers the farm")
	check(is_equal_approx(mask.get_pixel(10 * k + 1, 10 * k + 1).r, h_tilled), "mask holds the tilled value")
	for kind in ["grass", "path", "tilled", "wet", "water"]:
		check(rules.ground.has(kind), "snow hold for %s ground" % kind)
	var noise := SnowLayer.noise_image()
	var low := 0
	for y in noise.get_height():
		for x in noise.get_width():
			low += 1 if noise.get_pixel(x, y).r < 0.4 else 0
	var share := float(low) / (noise.get_width() * noise.get_height())
	check(absf(share - 0.4) < 0.01, "equalised noise: cover 0.4 whitens 40%% of pixels (%.3f)" % share)
	# Snow tops (roofs) fill up faster than the ground: whole from TOP_FULL up, so a roof at
	# high cover has no bare clumps (they read as holes), while the ground keeps its patches.
	var shares := func(amount: float) -> Vector2:   # x: snow, y: bare, shares of the noise pixels
		var n_snow := 0
		var n_bare := 0
		for y in noise.get_height():
			for x in noise.get_width():
				var kind := SnowLayer.snow_kind(noise.get_pixel(x, y).r, amount)
				n_snow += 1 if kind == 2 else 0
				n_bare += 1 if kind == 0 else 0
		return Vector2(n_snow, n_bare) / float(noise.get_width() * noise.get_height())
	var top80: Vector2 = shares.call(SnowLayer.top_amount(0.8))
	var top_full: Vector2 = shares.call(SnowLayer.top_amount(SnowLayer.TOP_FULL))
	var ground80: Vector2 = shares.call(0.8)
	var ground100: Vector2 = shares.call(1.0)
	var top30: Vector2 = shares.call(SnowLayer.top_amount(0.3))
	check(top80.x == 1.0 and top_full.x == 1.0, "roof snow whole at cover 0.8 and at TOP_FULL (%.3f %.3f)" % [top80.x, top_full.x])
	check(ground80.y > 0.1 and ground80.x < 0.85, "ground at cover 0.8 keeps bare patches (snow %.3f, bare %.3f)" % [ground80.x, ground80.y])
	check(ground100.x == 1.0, "ground at full cover is all snow (%.4f)" % ground100.x)
	check(top30.y > 0.2 and top30.x > 0.3 and top30.x > shares.call(0.3).x, "light snow: roofs thin in patches, still whiter than the ground (snow %.3f, bare %.3f)" % [top30.x, top30.y])
	var top_mat := SnowLayer.top_material()
	check(is_equal_approx(top_mat.get_shader_parameter("top_full"), SnowLayer.TOP_FULL)
		and SnowLayer.TOP_SHADER.contains("min(cover / top_full, 1.0)"),
		"the top shader fills by cover / top_full, whole at 1")

	# The 2D view: the overlay starts hidden, follows the cover, and its mask follows the ground.
	var view := FarmView.new()
	view.farm = g.farm
	view.show_snow(rules)
	var overlay: Sprite2D = view.get_child(0)
	var mat := overlay.material as ShaderMaterial
	check(overlay.get_rect().size * overlay.scale == Vector2(FarmGrid.W, FarmGrid.H) * FarmView.T, "2D snow spans the farm")
	view.set_snow(0.0)
	check(not overlay.visible, "2D: no cover, no overlay")
	view.set_snow(0.6)
	check(overlay.visible and is_equal_approx(mat.get_shader_parameter("cover"), 0.6), "2D: overlay takes the cover")
	var spot := Vector2i(13, 12)
	g.farm.cell(spot).obj = FarmGrid.Obj.NONE
	var before := view.snow_mask.get_pixel(spot.x * k + 1, spot.y * k + 1).r
	g.farm.till(spot)
	g.farm.cells_changed.emit()
	var after := view.snow_mask.get_pixel(spot.x * k + 1, spot.y * k + 1).r
	check(is_equal_approx(before, h_grass) and is_equal_approx(after, h_tilled), "2D: tilling thins the snow there (%s -> %s)" % [before, after])
	view.free()
	g.free()

	# Lightning: only in a (rain) storm, never in a blizzard, short double pulse, gaps from data,
	# far below 3 flashes a second, and nothing when flashes are turned off.
	var style: Dictionary = fx.storm.lightning
	check(not fx.blizzard.has("lightning") and not fx.rain.has("lightning"), "lightning only in storms")
	check(Lightning.duration(style) < 0.6, "a flash is short (%.2f s)" % Lightning.duration(style))
	check(Lightning.pulse_at(0.0, style) == 1.0 and Lightning.pulse_at(Lightning.duration(style), style) == 0.0, "pulse starts bright, ends dark")
	check(float(style.strength) <= 0.5, "a flash adds at most half white")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var l := Lightning.new(rng)
	l.reset(style)
	var dt := 1.0 / 60.0
	var starts: Array[float] = []
	var last_lit := -INF
	var t := 0.0
	var peak := 0.0
	while t < 600.0:
		var b := l.step(dt)
		peak = maxf(peak, b)
		if b > 0.0:
			if t - last_lit > 1.0:   # dark for a second: a new flash, not its second pulse
				starts.append(t)
			last_lit = t
		t += dt
	check(starts.size() >= 600.0 / float(style.gap[1]) * 0.5 and peak <= 1.0, "flashes keep coming (%d in 10 min)" % starts.size())
	check(starts[0] >= float(style.first[0]) - dt and starts[0] <= float(style.first[1]) + dt, "first flash within 'first' (%.2f)" % starts[0])
	var min_gap := INF
	for i in range(1, starts.size()):
		min_gap = minf(min_gap, starts[i] - starts[i - 1])
	check(min_gap >= float(style.gap[0]), "gaps at least gap[0] (%.2f)" % min_gap)
	var pulses_per_flash := 0
	var on := false
	for i in 120:
		var b := Lightning.pulse_at(i / 120.0, style)
		if b > 0.0 and not on:
			pulses_per_flash += 1
		on = b > 0.0
	check(pulses_per_flash <= 3, "at most 3 bright pulses a second (%d)" % pulses_per_flash)
	l.reset({})
	var any := 0.0
	for i in 600:
		any = maxf(any, l.step(0.1))
	check(any == 0.0, "no lightning without a style")
	var gm: Node = game_script.new()
	gm.weather_fx = fx
	gm.weather_today = "storm"
	check(not gm.lightning_style().is_empty(), "storm day has lightning")
	gm.flashes_enabled = false
	check(gm.lightning_style().is_empty(), "flashes off: no lightning")
	gm.flashes_enabled = true
	gm.season = 3
	check(gm.lightning_style().is_empty(), "winter storm (blizzard): no lightning")

	# Sun shadows: full on a clear morning, fading at dusk, none at night or under cloud.
	gm.season = 0
	gm.weather_today = "sunny"
	gm.hour = 10
	gm.minute = 0
	check(is_equal_approx(gm.sun_shadow(), 1.0), "clear morning: full shadows (%.2f)" % gm.sun_shadow())
	gm.hour = 18
	var dusk: float = gm.sun_shadow()
	check(dusk > 0.0 and dusk < 1.0, "dusk: fading shadows (%.2f)" % dusk)
	gm.hour = 22
	check(gm.sun_shadow() == 0.0, "night: no shadows")
	gm.hour = 10
	for w in ["rain", "storm", "snow"]:
		gm.weather_today = w
		check(gm.sun_shadow() == 0.0, "%s: no shadows" % w)
	gm.free()

	_night_light(game_script, fx)
	_sun_by_clock(game_script, fx)
	_sky_by_clock(game_script, fx)
	_sprite_shadows(game_script)
	_finish(game_script, fx)


## The wind checks wait a frame: the world scripts read the Game autoload, which is on the root
## only once the main loop runs (test_maps does its world checks in _process for the same reason).

## The figures' shadows (SpriteShadow, data/light.json "sprite_shadows"): the data, the blob's
## share by sun, the caster facing the sun, sizes read from the texture, the caster following
## the sprite's picture and flip, the blob and caster by the sun's strength (0 in rain, night, rooms).
func _sprite_shadows(game_script: GDScript) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
	var raw: Dictionary = data.get("sprite_shadows", {})
	check(raw.get("mode", "") in ["real", "blob"], "sprite shadows: data mode is real or blob (%s)" % raw.get("mode", ""))
	var r := SpriteShadow.merged(raw)
	for k in ["blob_in_sun", "blob_width", "blob_depth", "blob_min"]:
		check(raw.has(k) and float(raw[k]) > 0.0, "sprite shadows: data has %s" % k)
	check(float(r.blob_in_sun) < 1.0, "sprite shadows: the blob is fainter under the sun")
	check(SpriteShadow.merged({"mode": "blob"}).blob_depth == r.blob_depth, "sprite shadows: unset keys keep their defaults")
	# The blob by sun: whole where there is none, faint under full sun, whole in blob mode.
	check(is_equal_approx(SpriteShadow.blob_share(true, 0.0, 0.35), 1.0), "blob share: no sun shadows, whole blob")
	check(is_equal_approx(SpriteShadow.blob_share(true, 1.0, 0.35), 0.35), "blob share: full sun, contact blob only")
	var half := SpriteShadow.blob_share(true, 0.5, 0.35)
	check(half > 0.35 and half < 1.0, "blob share: dusk eases between (%.2f)" % half)
	check(is_equal_approx(SpriteShadow.blob_share(false, 1.0, 0.35), 1.0), "blob share: blob mode stays whole at any sun")
	# The caster faces the sun: its normal (sin, cos of the yaw) points against the light's heading.
	for pose in [[46.0, -34.0], [16.0, -74.0], [60.0, -44.0], [30.0, 120.0]]:
		var dir: Vector3 = game_script.sun_direction({"elevation": pose[0], "yaw": pose[1]})
		var y := SpriteShadow.face_yaw(dir)
		var normal := Vector3(sin(y), 0.0, cos(y))
		var h := Vector3(dir.x, 0.0, dir.z).normalized()
		check(normal.dot(h) < -0.999, "caster faces the sun at elevation %d yaw %d" % [pose[0], pose[1]])
	check(SpriteShadow.face_yaw(Vector3.DOWN) == 0.0, "caster: a sun straight overhead keeps the quad as it is")
	# Sizes come from the texture, so any redrawn sprite fits.
	var small := Image.create(10, 20, false, Image.FORMAT_RGBA8)
	small.fill_rect(Rect2i(2, 0, 6, 20), Color.WHITE)
	var big := Image.create(40, 60, false, Image.FORMAT_RGBA8)
	big.fill_rect(Rect2i(5, 0, 30, 60), Color.WHITE)
	var t_small := ImageTexture.create_from_image(small)
	var t_big := ImageTexture.create_from_image(big)
	check(SpriteShadow.opaque_width(t_small) == 6 and SpriteShadow.opaque_width(t_big) == 30, "opaque width read from the texture (6, 30)")
	var s := _sprite(t_small)
	root.add_child(s)
	var sh := SpriteShadow.attach(s)
	var blob: MeshInstance3D = sh.get_child(0)
	var caster: MeshInstance3D = sh.get_child(1)
	check(caster.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "the caster is shadows-only")
	check(blob.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "the blob casts nothing")
	var px := s.pixel_size
	check(is_equal_approx(blob.mesh.size.x, maxf(6.0 * px * float(r.blob_width), float(r.blob_min))), "blob width follows the opaque pixels (the minimum holds for a narrow one)")
	var s2 := _sprite(t_big)
	root.add_child(s2)
	var sh2 := SpriteShadow.attach(s2)
	check(sh2.get_child(0).mesh.size.x > blob.mesh.size.x, "a bigger sprite gets a bigger blob")
	# The caster: the sprite's size, standing on its feet, in the sun's heading; the blob fades with the sun.
	SpriteShadow._mode = "real"
	SpriteShadow.sun_strength = 1.0
	SpriteShadow.sun_yaw = 0.7
	sh._process(0.0)
	check(caster.visible and is_equal_approx(caster.rotation.y, 0.7), "sun on: the caster shows, turned to the sun")
	check((caster.mesh as QuadMesh).size.is_equal_approx(Vector2(10, 20) * px) and is_equal_approx(caster.mesh.center_offset.y, s.offset.y * px), "the caster has the sprite's size and stands on the feet")
	check(is_equal_approx((blob.material_override as StandardMaterial3D).albedo_color.a, 0.3 * float(r.blob_in_sun)), "sun on: the blob is only a contact shadow")
	s.flip_h = true
	sh._process(0.0)
	check(caster.scale.x < 0.0, "a mirrored sprite's caster is mirrored")
	s.texture = t_big
	sh._process(0.0)
	check((caster.mesh as QuadMesh).size.is_equal_approx(Vector2(40, 60) * px), "a new picture resizes the caster")
	SpriteShadow.sun_strength = 0.0
	sh._process(0.0)
	check(not caster.visible and is_equal_approx((blob.material_override as StandardMaterial3D).albedo_color.a, 0.3), "no sun (rain, night, rooms): no caster, the whole blob")
	SpriteShadow._mode = "blob"
	SpriteShadow.sun_strength = 1.0
	sh._process(0.0)
	check(not caster.visible and is_equal_approx((blob.material_override as StandardMaterial3D).albedo_color.a, 0.3), "blob mode: the blob alone, whole under full sun")
	var crop_sprite := _sprite(t_small)
	root.add_child(crop_sprite)
	var crop := SpriteShadow.attach(crop_sprite, 0.0, false)
	check(not (crop.get_child(0) as MeshInstance3D).visible, "a crop gets no blob")
	SpriteShadow._mode = ""
	SpriteShadow.sun_strength = 0.0
	s.free()
	s2.free()
	crop_sprite.free()


## A sprite made like FarmWorld.make_sprite (that needs the autoloads): 0.045 a pixel, on its feet.
func _sprite(tex: Texture2D) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = 0.045
	s.offset = Vector2(0, tex.get_height() / 2.0)
	return s


func _finish(game_script: GDScript, fx: Dictionary) -> void:
	await process_frame
	_wind_by_weather(game_script, fx)
	_sprite_light(game_script, fx)
	print("test_weather: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


## Day / night (data/light.json): plain daylight 7:00..16:00, a deep blue night that is still
## readable, dusk and dawn without jumps, and house windows lit with the dark in their hours.
func _night_light(game_script: GDScript, fx: Dictionary) -> void:
	var light: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
	var gm: Node = game_script.new()
	gm.weather_fx = fx
	var at := func(h: int, m: int) -> Color:
		gm.hour = h
		gm.minute = m
		return gm.light_color()
	for h in [7, 10, 12, 15, 16]:
		check(at.call(h, 0) == Color.WHITE, "%d:00 is plain daylight" % h)
	var night: Color = at.call(21, 0)
	check(night.get_luminance() < 0.36 and night.get_luminance() > 0.2, "21:00 is dark but readable (luminance %.2f)" % night.get_luminance())
	check(night.b > night.r + 0.2 and night.b > night.g + 0.2, "the night is blue %s" % night)
	check(at.call(2, 0) == night and at.call(23, 30) == night, "the same night blue at 2:00 and 23:30")
	var old_night := Color(0.42, 0.45, 0.72)   # the night before FEEDBACK item 6
	check(night.get_luminance() < old_night.get_luminance() - 0.12, "night clearly darker than before (%.2f < %.2f)" % [night.get_luminance(), old_night.get_luminance()])
	var unlit_night := Color("404c8e")   # the night before the real lamps (NightLamps)
	check(night.get_luminance() > unlit_night.get_luminance() + 0.01 and night.get_luminance() < unlit_night.get_luminance() + 0.05,
		"with the lamps the night is a touch lighter (%.3f > %.3f)" % [night.get_luminance(), unlit_night.get_luminance()])
	# Dusk 16:00 -> 20:30 only darkens, and smoothly (no step over 0.06 in 10 minutes); dawn 4:30 -> 7:00 only brightens.
	var steps := {"dusk": [960, 1230, -1], "dawn": [270, 420, 1]}
	for name in steps:
		var s: Array = steps[name]
		var prev: float = game_script.sky_at(s[0], light.sky).get_luminance()
		var ok := true
		var worst := 0.0
		for m in range(s[0] + 10, s[1] + 1, 10):
			var l: float = game_script.sky_at(m, light.sky).get_luminance()
			worst = maxf(worst, absf(l - prev))
			ok = ok and (l - prev) * s[2] >= -0.0001
			prev = l
		check(ok and worst < 0.06, "%s changes one way, smoothly (largest step %.3f)" % [name, worst])
	var dusk: Color = at.call(18, 30)
	check(dusk.get_luminance() < 0.75 and dusk.get_luminance() > night.get_luminance() + 0.15, "18:30 is dusk, between day and night (%.2f)" % dusk.get_luminance())
	check(game_script.sky_at(600, []) == Color.WHITE, "no sky keys: plain white")
	# Windows: dark by day, full at night, half lit at dusk, out after 0:30 until dawn.
	var glow := func(h: int, m: int) -> float:
		gm.hour = h
		gm.minute = m
		return gm.window_light()
	check(glow.call(12, 0) == 0.0 and glow.call(16, 0) == 0.0, "no lit windows by day")
	check(glow.call(21, 0) == 1.0 and glow.call(0, 10) == 1.0, "windows fully lit at 21:00 and 0:10")
	var half: float = glow.call(18, 30)
	check(half > 0.2 and half < 1.0, "windows coming on at 18:30 (%.2f)" % half)
	check(glow.call(19, 0) >= half, "and brighter as it gets darker")
	check(glow.call(2, 0) == 0.0, "windows out at 2:00 (the village sleeps)")
	check(glow.call(5, 0) > 0.5 and glow.call(7, 30) == 0.0, "lit again before dawn, out by day")
	gm.weather_today = "storm"
	check(glow.call(12, 0) == 0.0, "a dark storm at noon lights no windows (outside their hours)")
	check(game_script.window_glow(Color(0.3, 0.3, 0.3), 1200, {"hours": [[0, 1440]], "dark_from": 0.25, "dark_full": 0.6}) == 1.0
		and game_script.window_glow(Color(0.9, 0.9, 0.9), 1200, {"hours": [[0, 1440]], "dark_from": 0.25, "dark_full": 0.6}) == 0.0,
		"window_glow follows dark_from / dark_full")
	gm.free()


## The sun follows the clock (data/light.json "sun"): low, golden and from the front left in
## the morning, high and plain at midday, low and golden from the back left in the evening,
## the plain fixed sun at night, in rooms and mines, and its plain colour under cloud.
func _sun_by_clock(game_script: GDScript, fx: Dictionary) -> void:
	var light: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
	var rules: Dictionary = light.sun
	var keys: Array = rules["keys"]
	var plain: Dictionary = game_script.sun_plain(rules)
	# Main3D's SUN_COLOR / SUN_ENERGY (main_3d.gd needs the Game autoload, so not loaded here).
	check(plain.color.to_html(false) == Color(1.0, 0.93, 0.8).to_html(false) and is_equal_approx(plain.energy, 0.7)
		and plain.elevation == 48.0 and plain.yaw == -40.0, "the plain sun is the measured one (Main3D SUN_COLOR / SUN_ENERGY, 48 / -40)")
	for k in keys:
		check(is_equal_approx(float(k[4]), plain.energy), "sun energy at %d stays plain's (the ground's SUN_SHARE was measured at it)" % int(k[0]))
	check(int(keys[0][0]) == 0 and int(keys[-1][0]) == 1440, "the sun keys cover the whole day")
	# Sampling: linear between keys, held past the ends, plain with no keys.
	var two := [[100, 10.0, -10.0, "000000", 0.5], [200, 30.0, -50.0, "ffffff", 0.9]]
	var mid: Dictionary = game_script.sun_at(150, two)
	check(is_equal_approx(mid.elevation, 20.0) and is_equal_approx(mid.yaw, -30.0) and is_equal_approx(mid.energy, 0.7)
		and mid.color.is_equal_approx(Color(0.5, 0.5, 0.5)), "sun_at halfway is halfway (%s)" % mid)
	check(game_script.sun_at(50, two).elevation == 10.0 and game_script.sun_at(250, two).elevation == 30.0, "sun_at holds past the ends")
	check(game_script.sun_at(600, [], plain).elevation == plain.elevation, "no sun keys: the plain sun")

	var gm: Node = game_script.new()
	gm.weather_fx = fx
	gm.weather_today = "sunny"
	var at := func(h: int, m: int) -> Dictionary:
		gm.hour = h
		gm.minute = m
		return gm.sun_light()
	# The camera looks from +x +z (yaw 45, CameraLens): screen right is (1, 0, -1), up the screen (away) is (-1, 0, -1).
	var right := Vector3(1, 0, -1).normalized()
	var away := Vector3(-1, 0, -1).normalized()
	var morning: Dictionary = at.call(6, 30)
	var noon: Dictionary = at.call(12, 0)
	var evening: Dictionary = at.call(17, 30)
	var dm: Vector3 = game_script.sun_direction(morning)
	var de: Vector3 = game_script.sun_direction(evening)
	var dn: Vector3 = game_script.sun_direction(noon)
	check(dm.y < 0 and de.y < 0 and dn.y < 0, "the sun shines down")
	check(dm.dot(right) > 0.3 and dm.dot(away) > 0.3, "6:30: shadows fall up the screen to the right (%s)" % dm)
	check(de.dot(right) > 0.3 and de.dot(away) < -0.3, "17:30: shadows fall down the screen to the right (%s)" % de)
	check(Vector3(dn.x, 0, dn.z).normalized().dot(right) > 0.9, "noon: shadows fall to the right (%s)" % dn)
	var shadow_len := func(s: Dictionary) -> float: return 1.0 / tan(deg_to_rad(s.elevation))
	check(shadow_len.call(morning) > 3.0 and shadow_len.call(evening) > 3.0 and shadow_len.call(noon) < 0.8,
		"long shadows morning and evening, short at noon (%.1f %.1f %.1f)" % [shadow_len.call(morning), shadow_len.call(evening), shadow_len.call(noon)])
	var highest := 0.0
	for m in range(0, 1440, 10):
		highest = maxf(highest, game_script.sun_at(m, keys).elevation)
	check(noon.elevation >= highest and noon.elevation >= 55.0, "the sun is highest at noon (%.0f)" % noon.elevation)
	var warmth := func(s: Dictionary) -> float: return s.color.r - s.color.b
	check(warmth.call(morning) > 0.25 and warmth.call(evening) > 0.3, "golden morning and evening sun (%.2f %.2f)" % [warmth.call(morning), warmth.call(evening)])
	check(noon.color.is_equal_approx(plain.color), "plain colour at noon (the measured one)")
	check(warmth.call(at.call(10, 0)) < warmth.call(morning) and warmth.call(at.call(16, 0)) < warmth.call(evening),
		"the lower the sun, the warmer")
	# Night: the plain fixed sun, so the night looks as before (FEEDBACK item 6).
	for hm in [[21, 0], [23, 30], [2, 0], [4, 0]]:
		var s: Dictionary = at.call(hm[0], hm[1])
		check(s.elevation == plain.elevation and s.yaw == plain.yaw and s.color.is_equal_approx(plain.color), "%d:%02d: the plain night sun" % hm)
	# Smooth: no jump over 6 degrees or 0.12 of colour in 10 minutes; and the sun swings back to
	# the night pose only while its shadows are off (under the dusk / dawn tint).
	var worst := 0.0
	var swing_lit := 0
	var prev: Dictionary = game_script.sun_at(0, keys)
	for m in range(10, 1441, 10):
		var s: Dictionary = game_script.sun_at(m, keys)
		var c: Color = s.color
		var pc: Color = prev.color
		worst = maxf(worst, maxf(absf(s.elevation - prev.elevation), absf(s.yaw - prev.yaw)) / 6.0)
		worst = maxf(worst, maxf(absf(c.g - pc.g), absf(c.b - pc.b)) / 0.12)
		gm.hour = m / 60 % 24
		gm.minute = m % 60
		var rising: bool = s.elevation > prev.elevation
		if rising and (m > 1110 or m <= 330) and gm.sun_shadow() > 0.0:
			swing_lit += 1
		prev = s
	check(worst <= 1.0, "the sun moves smoothly through the day (worst %.2f of the allowed step)" % worst)
	check(swing_lit == 0, "the sun swings back to the night pose only with its shadows off (%d steps)" % swing_lit)
	# Under cloud the colour stays plain (no golden rainy evening); the direction still follows.
	for w in ["rain", "storm", "snow", "blizzard"]:
		gm.weather_today = w
		var s: Dictionary = at.call(17, 30)
		check(s.color.is_equal_approx(plain.color) and is_equal_approx(s.elevation, evening.elevation), "%s at 17:30: plain colour, low sun" % w)
	gm.weather_today = "sunny"
	# Rooms and mine floors: the plain fixed sun at any hour.
	for hm in [[6, 30], [12, 0], [17, 30], [21, 0]]:
		gm.hour = hm[0]
		gm.minute = hm[1]
		var s: Dictionary = gm.sun_light(true)
		check(s.elevation == plain.elevation and s.yaw == plain.yaw and s.color.is_equal_approx(plain.color) and s.energy == plain.energy,
			"indoors at %d:%02d: the plain sun" % hm)
	gm.free()


## The outdoor sky behind the land (data/light.json "background"): the day blue at noon, linear
## blends between the keys, dark blue at night, greyer and darker under cloud, and a room or a
## mine keeps its own background (Game.sky_background).
func _sky_by_clock(game_script: GDScript, fx: Dictionary) -> void:
	var light: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
	var rules: Dictionary = light.background
	var keys: Array = rules.keys
	var gm: Node = game_script.new()
	gm.weather_fx = fx
	gm.weather_today = "sunny"
	var at := func(h: int, m: int) -> Color:
		gm.hour = h
		gm.minute = m
		return gm.sky_color()
	var lum := func(c: Color) -> float: return c.get_luminance()
	var chroma := func(c: Color) -> float: return maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
	check(at.call(12, 0).is_equal_approx(Color("8fc6e8")), "noon: the day blue the view had before (%s)" % at.call(12, 0))
	check(at.call(15, 0).is_equal_approx(Color("8fc6e8")), "afternoon: still the day blue")
	check(keys.size() >= 6 and int(keys[0][0]) == 0 and int(keys[-1][0]) == 1440, "the sky keys cover the whole day")
	# Blend: 6:00 is halfway between the 5:30 and 6:30 keys (both checked to be those minutes).
	check(int(keys[2][0]) == 330 and int(keys[3][0]) == 390, "the dawn keys are at 5:30 and 6:30")
	var halfway: Color = Color(str(keys[2][1])).lerp(Color(str(keys[3][1])), 0.5)
	check(at.call(6, 0).is_equal_approx(halfway), "6:00 blends the two dawn keys (%s)" % at.call(6, 0))
	check(game_script.sky_at(360, keys).is_equal_approx(halfway), "sky_at blends linearly between keys")
	check(game_script.sky_at(600, []) == Color.WHITE, "no sky keys: plain white")
	# Night: a deep blue, dark, still blue (not black).
	for hm in [[0, 0], [2, 0], [23, 30]]:
		var n: Color = at.call(hm[0], hm[1])
		check(lum.call(n) < 0.15 and n.b > n.r + 0.1 and n.b > n.g, "%d:%02d: a dark blue night (%s)" % [hm[0], hm[1], n])
	check(lum.call(at.call(12, 0)) > lum.call(at.call(18, 30)) and lum.call(at.call(18, 30)) > lum.call(at.call(23, 0)),
		"noon brighter than dusk, dusk brighter than night")
	check(at.call(17, 30).r > at.call(17, 30).b and at.call(6, 30).r > at.call(6, 30).b, "the golden evening and the peach dawn are warm")
	# Smooth: no step over 0.1 of luminance in 10 minutes anywhere in the day.
	var worst := 0.0
	var prev: float = lum.call(at.call(0, 0))
	for m in range(10, 1441, 10):
		var l: float = lum.call(at.call(m / 60 % 24, m % 60))
		worst = maxf(worst, absf(l - prev))
		prev = l
	check(worst < 0.1, "the sky changes smoothly (largest 10-minute step %.3f)" % worst)
	# Clouded: greyer and darker than the clear sky, and rain / storm darker again.
	gm.weather_today = "rain"
	gm.hour = 12
	gm.minute = 0
	var rain: Color = gm.sky_color()
	gm.weather_today = "storm"
	var storm: Color = gm.sky_color()
	gm.weather_today = "sunny"
	var clear: Color = at.call(12, 0)
	check(lum.call(rain) < lum.call(clear) and lum.call(storm) < lum.call(rain), "noon: clear > rain > storm (%.2f %.2f %.2f)" % [lum.call(clear), lum.call(rain), lum.call(storm)])
	check(chroma.call(storm) < chroma.call(clear) and chroma.call(rain) < chroma.call(clear), "clouded skies are greyer (chroma %.2f %.2f %.2f)" % [chroma.call(clear), chroma.call(rain), chroma.call(storm)])
	var all_grey := rules.duplicate()
	all_grey["cloud_grey"] = 1.0
	var grey: Color = game_script.sky_view(720, all_grey, {"sun": 0.0})
	check(is_equal_approx(grey.r, grey.g) and is_equal_approx(grey.g, grey.b), "fully clouded, no tint: a grey sky (%s)" % grey)
	check(game_script.sky_view(720, rules, {}).is_equal_approx(Color("8fc6e8")), "a style without sun or tint keeps the key colour")
	# Rooms and mine floors: their own background at any hour, outdoors the sky.
	var room := Color("1a1410")
	for hm in [[6, 0], [12, 0], [21, 0]]:
		gm.hour = hm[0]
		gm.minute = hm[1]
		check(gm.sky_background(true, room) == room, "indoors at %d:%02d: the room's own background" % hm)
		check(gm.sky_background(false, room).is_equal_approx(gm.sky_color()), "outdoors at %d:%02d: the sky, not the room's" % hm)
	gm.free()


## The wind follows the weather (data/wind.json): calm on sunny days, medium in rain, strong in a
## storm or a blizzard. Game reads it by the look; FarmWorld.set_wind pushes it to the grass
## tufts' shader (a uniform) and to the bamboo sway, which gets a bigger, faster, gustier wave.
func _wind_by_weather(game_script: GDScript, fx: Dictionary) -> void:
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/wind.json"))
	var strength: Dictionary = rules.get("strength", {})
	for look in fx.keys():
		check(strength.has(look), "%s has a wind strength in data/wind.json" % look)
	var gm: Node = game_script.new()
	gm.weather_fx = fx
	gm.wind_rules = rules
	gm.season = 0
	var at := func(w: String) -> float:
		gm.weather_today = w
		return gm.wind_strength()
	var calm: float = at.call("sunny")
	var wet: float = at.call("rain")
	var gale: float = at.call("storm")
	check(calm < wet and wet < gale, "sunny < rain < storm (%.2f %.2f %.2f)" % [calm, wet, gale])
	check(calm <= 0.2 and wet >= 0.4 and wet <= 0.6 and gale >= 0.9, "calm, medium and strong from the data (%.2f %.2f %.2f)" % [calm, wet, gale])
	check(at.call("blizzard") > wet and at.call("snow") < wet, "a blizzard blows hard, light snow lightly")
	gm.season = 3
	check(is_equal_approx(at.call("storm"), float(strength.blizzard)), "a winter storm is a blizzard: its strength (%.2f)" % gm.wind_strength())
	gm.season = 0
	check(is_equal_approx(game_script.wind_for("hail", rules), 0.0) and is_equal_approx(game_script.wind_for("storm", rules), 1.0), "a look without a strength is calm; storm reads 1.0")
	gm.free()

	# The uniform on the grass tufts' material.
	var tufts_script: GDScript = load("res://scripts/world3d/grass_tufts.gd")
	var tufts = tufts_script.new()
	tufts.set_wind(gale)
	check(is_equal_approx(float(tufts.material_override.get_shader_parameter("wind")), gale), "the tufts' wind uniform is set (%.2f)" % gale)
	tufts.set_wind(calm)
	check(is_equal_approx(float(tufts.material_override.get_shader_parameter("wind")), calm), "and set back to calm (%.2f)" % calm)
	tufts.free()
	# Tall crops (rice, corn, the vines on stakes) take the same wind and hold it on every picture.
	var cc_script: GDScript = load("res://scripts/world3d/crop_clusters.gd")
	var cl = cc_script.new()
	cl.plant({Vector2i(2, 2): "stalk:tomato:3:ripe", Vector2i(3, 2): "stalk:rice:3:ripe"}, func(_c: Vector2i) -> float: return 0.0)
	cl.set_wind(gale)
	check(cl.materials().all(func(m: ShaderMaterial) -> bool: return is_equal_approx(float(m.get_shader_parameter("wind")), gale)) and cl.materials().size() >= 3,
		"the crop clusters' wind uniform is set on every picture (%.2f)" % gale)
	cl.plant({Vector2i(2, 2): "stalk:cucumber:3:ripe"}, func(_c: Vector2i) -> float: return 0.0)
	check(cl.materials().all(func(m: ShaderMaterial) -> bool: return is_equal_approx(float(m.get_shader_parameter("wind")), gale)),
		"and a picture made later starts with it")
	check("uniform float wind" in cc_script.SHADER and "wind * 0.02 * k" in cc_script.SHADER and "(1.0 + 1.5 * wind)" in cc_script.SHADER, "the crop shader takes the wind like the grass")
	cl.free()

	# The bamboo sway: over a minute, a storm leans further and swings more often than a calm day.
	var outdoor: GDScript = load("res://scripts/world3d/outdoor_props.gd")
	var sway = outdoor.Sway.new()
	sway.add([], 0.0, 0.5)
	sway.add([], 0.0, 2.0)
	var reach := func(s: float) -> float:
		sway.wind = s
		var top := 0.0
		for i in 600:
			sway.pose(i * 0.1)
			top = maxf(top, absf(sway.angle_of(0)))
		return top
	var turns := func(s: float) -> int:
		sway.wind = s
		var n := 0
		var last := 0.0
		for i in 600:
			sway.pose(i * 0.1)
			var a: float = sway.angle_of(0)
			if i > 0 and signf(a) != signf(last):
				n += 1
			last = a
		return n
	var calm_reach: float = reach.call(calm)
	var rain_reach: float = reach.call(wet)
	var storm_reach: float = reach.call(gale)
	check(calm_reach < rain_reach and rain_reach < storm_reach, "bamboo leans further in rain, further in a storm (%.4f %.4f %.4f)" % [calm_reach, rain_reach, storm_reach])
	check(storm_reach > calm_reach * 2.5, "a storm's lean is well past a calm day's (%.1f times)" % (storm_reach / calm_reach))
	check(turns.call(gale) > turns.call(calm), "and the wave runs faster in a storm (%d turns against %d)" % [turns.call(gale), turns.call(calm)])
	var still: float = reach.call(0.0)
	check(still <= outdoor.Sway.AMPLITUDE + 0.000001 and still > outdoor.Sway.AMPLITUDE * 0.9, "no wind: the old wave, at the old amplitude (%.4f)" % still)
	sway.free()

	# FarmWorld pushes the wind to both: the tufts' uniform and the world's sway (made on demand).
	var farm_world: GDScript = load("res://scripts/world3d/farm_world.gd")
	var world = farm_world.new()
	world.add_tufts()
	world.set_wind(gale)
	check(is_equal_approx(float(world.tufts.material_override.get_shader_parameter("wind")), gale), "FarmWorld.set_wind sets the tufts' uniform")
	var bamboo = outdoor._sway(world)
	check(is_equal_approx(bamboo.wind, gale), "a sway made after the wind takes it (%.2f)" % bamboo.wind)
	world.set_wind(calm)
	check(is_equal_approx(bamboo.wind, calm) and is_equal_approx(float(world.tufts.material_override.get_shader_parameter("wind")), calm), "and the next set_wind moves both back")
	# A layer that is a world of its own (today's FestivalProps) takes the wind too.
	var layer = farm_world.new()
	world.add_child(layer)
	var layer_sway = outdoor._sway(layer)
	world.set_wind(wet)
	check(is_equal_approx(layer_sway.wind, wet) and is_equal_approx(layer.wind, wet), "set_wind reaches a child world's sway (%.2f)" % layer_sway.wind)
	world.free()
	_wind_on_leaves_and_cloth(outdoor, calm, wet, gale)


## Leaves (the kadomatsu's pine, the fence's shoots) and cloth (noren, stall curtains, the race
## banner) in the wind: still at 0; a breeze moves them, a storm further and faster; their hinge
## never moves; a noren only ever blows out from its wall, and its top edge stays on the rod.
func _wind_on_leaves_and_cloth(outdoor: GDScript, calm: float, wet: float, gale: float) -> void:
	var sway = outdoor.Sway.new()
	var leaf_node := Node3D.new()
	var cloth_node := Node3D.new()
	var banner_node := Node3D.new()
	var east_node := Node3D.new()
	var hinge := Vector3(3.0, 1.2, 4.0)
	sway.add_leaves([leaf_node], hinge, 0.0, 0.3, -hinge)
	sway.add_cloth([cloth_node], hinge, 0.0, 1.1, -hinge)
	sway.add_cloth([banner_node], hinge, 0.0, 2.0, -hinge, 0.0)
	sway.add_cloth([east_node], hinge, PI / 2, 0.7, -hinge)   # a noren on an east wall: its rod lies along the wind
	var tip := Vector3(0, 0.3, 0)    # a sprig's tip over its base
	var hem := Vector3(0, -0.36, 0)  # a noren's hem under its rod
	var top := Vector3(0.4, 0, 0)    # a corner of the rod
	# Over a minute: the furthest a point moves, the least a hem lifts and the turns of the lean.
	var run := func(s: float) -> Dictionary:
		sway.wind = s
		var r := {"leaf": 0.0, "cloth": 0.0, "banner": 0.0, "lift_min": 1e9, "lift_max": -1e9, "back": -1e9, "rod": 0.0,
			"hinge": 0.0, "turns": 0, "east_x": 0.0}
		var last := 0.0
		for i in 600:
			sway.pose(i * 0.1)
			var lt: Vector3 = sway.moved(0, tip)
			r.leaf = maxf(r.leaf, (lt - tip).length())
			var ch: Vector3 = sway.moved(1, hem)
			r.cloth = maxf(r.cloth, (ch - hem).length())
			r.lift_min = minf(r.lift_min, ch.z)
			r.lift_max = maxf(r.lift_max, ch.z)
			r.rod = maxf(r.rod, (sway.moved(1, top) - top).length())
			var bh: Vector3 = sway.moved(2, hem)
			r.banner = maxf(r.banner, (bh - hem).length())
			r.back = maxf(r.back, -bh.z)
			r.east_x = maxf(r.east_x, absf(sway.moved(3, hem).x))
			for n: Node3D in [leaf_node, cloth_node, banner_node]:
				r.hinge = maxf(r.hinge, (n.transform * hinge - hinge).length())
			var a: float = lt.x
			if i > 0 and signf(a - last) != 0.0 and signf(a) != signf(last):
				r.turns += 1
			last = a
		return r
	var still: Dictionary = run.call(0.0)
	check(still.leaf < 0.000001 and still.cloth < 0.000001 and still.banner < 0.000001 and still.hinge < 0.000001
		and leaf_node.transform.is_equal_approx(Transform3D.IDENTITY) and cloth_node.transform.is_equal_approx(Transform3D.IDENTITY),
		"no wind: leaves and cloth stand as built (%.6f %.6f %.6f)" % [still.leaf, still.cloth, still.banner])
	var breeze: Dictionary = run.call(calm)
	var rain: Dictionary = run.call(wet)
	var storm: Dictionary = run.call(gale)
	check(breeze.leaf < rain.leaf and rain.leaf < storm.leaf and storm.leaf > 0.04 and storm.leaf < 0.12,
		"a sprig's tip moves further in rain, further in a storm (%.3f %.3f %.3f)" % [breeze.leaf, rain.leaf, storm.leaf])
	check(breeze.cloth > 0.03 and breeze.cloth < rain.cloth and rain.cloth < storm.cloth and storm.cloth < 0.4,
		"a noren's hem stirs on a calm day and blows further in rain and a storm (%.3f %.3f %.3f)" % [breeze.cloth, rain.cloth, storm.cloth])
	check(breeze.banner > 0.02 and breeze.banner < storm.banner, "the banner swings in a breeze, more in a storm (%.3f %.3f)" % [breeze.banner, storm.banner])
	check(storm.lift_min >= -0.000001 and storm.lift_max > 0.1 and rain.lift_min >= -0.000001,
		"a noren only blows out from its wall (hem z %.3f..%.3f in a storm)" % [storm.lift_min, storm.lift_max])
	check(storm.back > 0.02, "a banner free on both faces swings both ways (%.3f back)" % storm.back)
	check(storm.rod < 0.000001 and storm.hinge < 0.000001, "the rod and the hinges stay put (%.6f %.6f)" % [storm.rod, storm.hinge])
	check(storm.east_x < 0.000001, "a noren whose rod lies along the wind does not stream sideways (%.6f)" % storm.east_x)
	check(storm.turns > breeze.turns, "the leaves' wave runs faster in a storm (%d turns against %d)" % [storm.turns, breeze.turns])
	# Back to calm: everything at rest again.
	run.call(0.0)
	check(cloth_node.transform.is_equal_approx(Transform3D.IDENTITY) and banner_node.transform.is_equal_approx(Transform3D.IDENTITY),
		"the wind dropping to 0 sets them back at rest")
	for n in [leaf_node, cloth_node, banner_node, east_node]:
		n.free()
	sway.free()

	# The pieces themselves: the fence's shoots, the kadomatsu's greens, a stall's curtain, the
	# race banner and the noren are in their world's sway; the posts, tubs and roofs are not.
	var fw: GDScript = load("res://scripts/world3d/farm_world.gd")
	var fm: GDScript = load("res://scripts/world3d/festival_meshes.gd")
	var w = fw.new()
	w._make_fence()
	var fs = outdoor._sway(w)
	var fence_meshes: int = w.get_children().filter(func(n): return n is MeshInstance3D).size()
	check(fs.count() >= 10 and fs.count_of("leaves") == fs.count() and fence_meshes > fs.count(),
		"the fence: %d leafy shoots in the wind, the other %d meshes (posts, canes, rails) still" % [fs.count(), fence_meshes - fs.count()])
	w.free()
	w = fw.new()
	fm.kadomatsu(w, Vector3(5.5, 0, 7.5), true)
	var ks = outdoor._sway(w)
	var moving := 0
	for i in ks.count():
		moving += ks.nodes_of(i).size()
	var all_meshes: int = w.get_children().filter(func(n): return n is MeshInstance3D).size()
	check(ks.count_of("leaves") == 6 and ks.count() == 6 and moving < all_meshes,
		"kadomatsu: 5 pine sprigs and the plum twig lean (%d meshes), the tub and culms stand (%d)" % [moving, all_meshes - moving])
	w.free()
	w = fw.new()
	fm.stall(w, Vector3(5.0, 0, 5.5), Rect2(4, 5, 2, 1), Color("c8442c"))
	var ss = outdoor._sway(w)
	check(ss.count_of("cloth") >= 2 and ss.count() == ss.count_of("cloth"), "a stall: its %d curtain pieces hang in the wind" % ss.count_of("cloth"))
	w.free()
	w = fw.new()
	fm.race_flag(w, Vector3(5.5, 0, 5.5))
	var rs = outdoor._sway(w)
	check(rs.count_of("cloth") == 1, "the race flag: one banner in the wind")
	w.free()
	var town = load("res://scripts/world3d/map_world.gd").new()
	town.build(MapManager.data("town"))
	var ts = town.get_node_or_null(outdoor.SWAY)
	var noren := 0
	if ts != null:
		for i in ts.count():
			if ts.kind_of(i) == "cloth" and ts.nodes_of(i)[0].mesh is QuadMesh:
				noren += 1
	check(noren >= 2, "the village's shop noren hang in the wind (%d)" % noren)
	town.free()


## The world's light on the sprites (SpriteLight, data/light.json "sprites"): a share of the
## sun's colour by the clock (white at noon, at night, indoors and under cloud; golden morning
## and evening, never brighter than drawn), set on every lit sprite and crop picture but not on
## the marks; and at night a warm lift from the lit windows, lanterns and festival lights near a
## figure (only on a window's lit side, fading with distance, capped, none by day), drawn by
## NightLights' last pass.
func _sprite_light(game_script: GDScript, fx: Dictionary) -> void:
	# The world scripts read the Game autoload, so they are loaded here, after the first frame.
	var SL: GDScript = load("res://scripts/world3d/sprite_light.gd")
	var FW: GDScript = load("res://scripts/world3d/farm_world.gd")
	var CC: GDScript = load("res://scripts/world3d/crop_clusters.gd")
	var OC: GDScript = load("res://scripts/world3d/occluders.gd")
	var NL: GDScript = load("res://scripts/world3d/night_lights.gd")
	var light: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/light.json"))
	var rules: Dictionary = SL.rules_of(light)
	var share := float(rules.get("share", -1.0))
	check(share > 0.2 and share < 0.7, "sprite light: a modest share of the sun (%.2f)" % share)
	check(Color(str(rules.get("ref", ""))).to_html(false) == game_script.sun_plain(light.sun).color.to_html(false),
		"sprite light: ref is the plain sun's colour")
	var gm: Node = game_script.new()
	gm.weather_fx = fx
	gm.weather_today = "sunny"
	var tint_at := func(h: int, m: int, inside := false) -> Color:
		gm.hour = h
		gm.minute = m
		return SL.sun_tint(gm.sun_light(inside).color, rules)
	for hm in [[12, 0], [21, 0], [2, 0], [23, 30]]:
		check(tint_at.call(hm[0], hm[1]).is_equal_approx(Color.WHITE), "sprite light: plain at %d:%02d" % hm)
	for hm in [[6, 30], [12, 0], [17, 30]]:
		check(tint_at.call(hm[0], hm[1], true).is_equal_approx(Color.WHITE), "sprite light: rooms and mines plain at %d:%02d" % hm)
	var morning: Color = tint_at.call(6, 30)
	var evening: Color = tint_at.call(17, 30)
	for c: Color in [morning, evening]:
		check(is_equal_approx(c.r, 1.0) and c.b < c.g and c.g < 1.0 and c.b >= 1.0 - share - 0.001,
			"sprite light: golden, blue held back most, never past the share (%s)" % c)
	var brightest := 0.0
	var lowest := 1.0
	for m in range(0, 1440, 10):
		var c: Color = tint_at.call(m / 60, m % 60)
		brightest = maxf(brightest, maxf(c.r, maxf(c.g, c.b)))
		lowest = minf(lowest, minf(c.r, minf(c.g, c.b)))
	check(brightest <= 1.0 and lowest >= 1.0 - share - 0.001,
		"sprite light: never brighter than drawn, never darker than the share (%.2f .. %.2f)" % [lowest, brightest])
	for w in ["rain", "storm", "snow", "blizzard"]:
		gm.weather_today = w
		check(tint_at.call(17, 30).is_equal_approx(Color.WHITE), "sprite light: plain under %s" % w)
	gm.weather_today = "sunny"
	gm.free()
	# On the sprites: make_sprite takes the share (now and later), a mark keeps its picture, the
	# modulate's alpha (the occluders' fade) is kept; the crop pictures take it as a uniform.
	var old: Color = SL.now
	var tex: Texture2D = load("res://scripts/art/placeholder_art.gd").tex("item:turnip")
	var s: Sprite3D = FW.make_sprite(tex)
	var mark: Sprite3D = FW.make_sprite(tex)
	SL.unlit(mark)
	s.modulate.a = 0.4
	root.add_child(s)
	root.add_child(mark)
	var crops = CC.new()
	root.add_child(crops)
	SL.apply(self, evening)
	check(s.is_in_group(SL.GROUP) and Color(s.modulate.r, s.modulate.g, s.modulate.b).is_equal_approx(evening)
		and is_equal_approx(s.modulate.a, 0.4), "sprite light: a sprite takes the share, its alpha kept (%s)" % s.modulate)
	check(mark.modulate.is_equal_approx(Color.WHITE), "sprite light: a mark stays as drawn")
	var later: Sprite3D = FW.make_sprite(tex)
	check(Color(later.modulate.r, later.modulate.g, later.modulate.b).is_equal_approx(evening), "sprite light: a sprite made later takes it too")
	var cm: Vector3 = crops.materials()[0].get_shader_parameter("sun")
	check(cm.is_equal_approx(Vector3(evening.r, evening.g, evening.b)), "sprite light: the crop pictures take it (%s)" % cm)
	SL.apply(self, Color.WHITE)
	check(s.modulate.is_equal_approx(Color(1, 1, 1, 0.4)), "sprite light: back to white at noon")
	SL.now = old
	for n in [s, mark, crops, later]:
		n.free()
	# The night lift: a window's light only on its lit side, more the nearer, none far off or by
	# day, capped; a lantern's all round; a festival light with its darkness; a building between.
	var lr: Dictionary = rules.get("lift", {})
	var reach := float(lr.get("range", 0.0))
	var cap := float(lr.get("max", 0.0))
	check(reach > 1.0 and reach < 4.0 and cap > 0.2 and cap <= 1.0, "sprite light: lift reach %.1f and cap %.2f" % [reach, cap])
	var win := {"pos": Vector3(5, 1, 5), "normal": Vector3(0, 0, 1), "size": Vector2(0.6, 0.6)}
	var world := {"windows": [win], "lamps": []}
	var spots: Array = SL.spots_of([world], [], 1.0, 0.0, rules)
	check(spots.size() == 1, "sprite light: one spot per lit window")
	check(SL.spots_of([world], [], 0.0, 0.0, rules).is_empty(), "sprite light: no lift by day")
	var near: float = SL.lift_at(Vector3(5, 0.6, 5.8), spots, rules)
	var further: float = SL.lift_at(Vector3(5, 0.6, 6.8), spots, rules)
	check(near > further and further > 0.0 and near > 0.15, "sprite light: in front of a window, more the nearer (%.2f > %.2f)" % [near, further])
	check(SL.lift_at(Vector3(5, 0.6, 4.2), spots, rules) == 0.0, "sprite light: none behind the window's wall")
	check(SL.lift_at(Vector3(5, 0.6, 5 + reach + 1.0), spots, rules) == 0.0, "sprite light: none in the dark far off")
	var many := {"windows": [win, win, win, win, win], "lamps": [{"pos": Vector3(5, 0.6, 6)}]}
	check(is_equal_approx(SL.lift_at(Vector3(5, 0.6, 5.6), SL.spots_of([many], [], 1.0, 0.0, rules), rules), cap),
		"sprite light: capped by many lights")
	var lamp: Array = SL.spots_of([{"windows": [], "lamps": [{"pos": Vector3(0, 0.6, 0)}]}], [], 1.0, 0.0, rules)
	check(SL.lift_at(Vector3(-1, 0.6, 0), lamp, rules) > 0.0 and SL.lift_at(Vector3(1, 0.6, 0), lamp, rules) > 0.0,
		"sprite light: a lantern lights all round")
	var fest := {"glows": [{"pos": Vector3(0, 1, 0), "size": 1.0}]}
	check(SL.spots_of([], [fest], 0.0, 0.8, rules).size() == 1 and SL.spots_of([], [fest], 0.0, 0.0, rules).is_empty(),
		"sprite light: festival lights while they stand out")
	var occ = OC.new()
	var wall := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.2, 2.0, 2.0)
	wall.mesh = box
	wall.position = Vector3(-0.5, 1.0, 0)
	occ.add([wall])
	check(SL.lift_at(Vector3(-1, 0.6, 0), lamp, rules, occ) == 0.0 and SL.lift_at(Vector3(1, 0.6, 0), lamp, rules, occ) > 0.0,
		"sprite light: a building between keeps a lantern's light off")
	# The field takes the same lift: a crop sprite, an item lying on the ground and the cluster
	# plants in front of a lit window, none by day, behind its wall, past a building or far off,
	# capped; the figures (and what they hold) are left to their own pass.
	var crop_s: Sprite3D = FW.make_sprite(load("res://scripts/art/placeholder_art.gd").tex("crop:turnip:3:ripe"))
	crop_s.position = Vector3(5.5, 0, 5.7)
	var item_s: Sprite3D = FW.make_sprite(tex)
	item_s.position = Vector3(4.5, 0, 6.4)
	var back_s: Sprite3D = FW.make_sprite(tex)
	back_s.position = Vector3(5, 0, 4.4)
	var far_s: Sprite3D = FW.make_sprite(tex)
	far_s.position = Vector3(5, 0, 5 + reach + 1.0)
	var fig: Sprite3D = FW.make_sprite(tex)
	fig.position = Vector3(5.2, 0, 5.8)
	NL.figure(fig)
	var held: Sprite3D = FW.make_sprite(tex)
	fig.add_child(held)
	var field_cc = CC.new()
	for n in [crop_s, item_s, back_s, far_s, fig, field_cc]:
		root.add_child(n)
	field_cc.plant({Vector2i(4, 5): "stalk:corn:3:growing", Vector2i(4, 3): "stalk:corn:3:growing",
		Vector2i(4, 12): "stalk:corn:3:growing"}, func(_c: Vector2i) -> float: return 0.0)
	var field_sprites: Array = [crop_s, item_s, back_s, far_s, fig, held]
	var lifts: Array = SL.field_lifts(field_sprites, [field_cc], spots, rules)
	var lifted := {}
	var plants_lit := {}
	for e in lifts:
		if e.has("sprite"):
			lifted[e.sprite] = e.k
		else:
			plants_lit[e.plant.cell] = int(plants_lit.get(e.plant.cell, 0)) + 1
			check(e.k > 0.0 and e.k <= cap + 0.0001, "sprite light: a lit plant within the cap (%.2f)" % e.k)
	check(lifted.has(crop_s) and lifted.has(item_s) and float(lifted.get(crop_s, 0.0)) > 0.15 and float(lifted.get(item_s, 0.0)) > 0.0,
		"sprite light: a crop and an item in front of a lit window take the lift (%s)" % [lifted.values()])
	check(float(lifted.get(crop_s, 0.0)) > float(lifted.get(item_s, 0.0)), "sprite light: the nearer field object takes more")
	check(not lifted.has(back_s) and not lifted.has(far_s), "sprite light: none for the field behind the window's wall or far off")
	check(not lifted.has(fig) and not lifted.has(held), "sprite light: figures and what they hold are not the field's")
	check(plants_lit.get(Vector2i(4, 5), 0) == 3 and not plants_lit.has(Vector2i(4, 3)) and not plants_lit.has(Vector2i(4, 12)),
		"sprite light: the corn in front of the window lit, behind it and far off not (%s)" % plants_lit)
	check(SL.field_lifts(field_sprites, [field_cc], SL.spots_of([world], [], 0.0, 0.0, rules), rules).is_empty(),
		"sprite light: no lift on the field by day")
	var crowd: Array = SL.spots_of([many], [], 1.0, 0.0, rules)
	var top := 0.0
	for e in SL.field_lifts(field_sprites, [field_cc], crowd, rules):
		top = maxf(top, e.k)
	check(top > 0.0 and top <= cap + 0.0001 and is_equal_approx(top, cap), "sprite light: the field capped by many lights (%.2f)" % top)
	var lamp_s: Sprite3D = FW.make_sprite(tex)
	lamp_s.position = Vector3(-1, 0, 0)
	var lamp_t: Sprite3D = FW.make_sprite(tex)
	lamp_t.position = Vector3(1, 0, 0)
	root.add_child(lamp_s)
	root.add_child(lamp_t)
	var by_lamp: Array = SL.field_lifts([lamp_s, lamp_t], [], lamp, rules, occ)
	check(by_lamp.size() == 1 and by_lamp[0].sprite == lamp_t, "sprite light: a building between keeps a lantern's light off the field")
	field_cc.plant({Vector2i(4, 5): "stalk:corn:3:growing"}, func(_c: Vector2i) -> float: return 0.5)
	field_cc.set_cover(0.8)
	check(SL.field_lifts([], [field_cc], spots, rules).is_empty(), "sprite light: a plant the snow may fold takes none")
	var pc: Array = NL.plant_corners(Vector3(2, 0, 3), tex, 1.0, Basis())
	check(((pc[2] + pc[3]) / 2.0).is_equal_approx(Vector3(2, 0, 3)) and is_equal_approx(pc[0].y - pc[3].y, tex.get_height() * FW.PX),
		"sprite light: a plant's quad stands on its root at its picture's size")
	_field_pass(SL, NL, CC, FW, field_cc, crop_s, item_s, spots, rules)
	for n in [crop_s, item_s, back_s, far_s, fig, field_cc, lamp_s, lamp_t]:
		n.free()
	_figure_pass(SL, NL, FW, spots, rules, lamp, occ)
	wall.free()
	# The figures' lift is drawn in pass 0 with the field's; no pass of its own after the figures.
	var nl = NL.new()
	root.add_child(nl)
	check(nl.find_child("Warmth", false, false) == null and not ("warmth" in nl)
		and nl.figures.get_index() == nl.get_child_count() - 1,
		"figure pass: no separate warmth pass, the figures drawn back last")
	var fl_code: String = (nl.figure_lift.material as ShaderMaterial).shader.code
	var field_bloom = (nl.field.material as ShaderMaterial).get_shader_parameter("bloom")   # null: the shader's default, 0
	check(nl.field.get_index() < nl.figure_lift.get_index() and nl.figure_lift.get_index() < nl.pools.get_index()
		and nl.field_copy.get_index() < nl.field.get_index() and fl_code == NL.FIELD_SHADER
		and nl.figure_lift.material != nl.field.material and not nl.figure_lift.visible
		and (field_bloom == null or is_zero_approx(float(field_bloom))) and "uniform float bloom = 0.0;" in fl_code,
		"figure pass: the figures' lift after the field's from the same copy, before the pools, its own material (the field's bloom 0), off while nothing is lit")
	nl.free()


## The figures' lift in pass 0 (NightLights.figure_lifts, then field_quads and FIELD_SHADER as the
## field's): the same lift as the old Warmth pass, one quad for the figure and each lit sprite it
## holds (the marks over it left out) carrying (1, 1, 1, lift), following its frame, facing flip
## and pixel size; the figure's own texel under the tint takes it, a building's, a fence's or
## another figure's colour standing in front does not.
func _figure_pass(SL: GDScript, NL: GDScript, FW: GDScript, spots: Array, rules: Dictionary, lamp: Array, occ) -> void:
	var PA: GDScript = load("res://scripts/art/placeholder_art.gd")
	var lr: Dictionary = rules.get("lift", {})
	var reach := float(lr.range)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(5, 9, 16)
	cam.look_at(Vector3(5, 0, 5))
	cam.make_current()
	var stand: Texture2D = PA.tex("player:front:idle:0")
	var step: Texture2D = PA.tex("player:back:walk:1")
	var fig: Sprite3D = FW.make_figure(stand)
	fig.position = Vector3(5.2, 0, 5.8)
	NL.figure(fig)
	var held: Sprite3D = FW.make_sprite(PA.tex("item:turnip"))
	held.position = Vector3(0, 1.0, 0)
	fig.add_child(held)
	var note: Sprite3D = FW.make_sprite(PA.tex("item:egg"))
	note.position = Vector3(0, 1.6, 0)
	SL.unlit(note)
	fig.add_child(note)
	var cow_tex: Texture2D = PA.tex("animal:cow:idle:0:dl")
	var cow: Sprite3D = FW.make_sprite(cow_tex)
	cow.pixel_size = FW.PX / float(load("res://scripts/art/animal_art.gd").SCALE)
	cow.position = Vector3(4.6, 0, 6.2)
	NL.figure(cow)
	var far: Sprite3D = FW.make_figure(stand)
	far.position = Vector3(5, 0, 5 + reach + 1.0)
	NL.figure(far)
	for n in [fig, cow, far]:
		root.add_child(n)
	# The same lift as before: lift_at at the figure's middle (its feet plus half its picture).
	var lifts: Array = NL.figure_lifts([fig, cow, far], spots, rules)
	var same := true
	for e in lifts:
		var sp: Sprite3D = e.sprite
		var old_mid: Vector3 = sp.global_position + Vector3.UP * (sp.texture.get_height() * sp.pixel_size / 2.0)
		same = same and (e.mid as Vector3).is_equal_approx(old_mid) and is_equal_approx(e.k, SL.lift_at(old_mid, spots, rules))
	var who: Array = lifts.map(func(e): return e.sprite)
	check(lifts.size() == 2 and fig in who and cow in who and same and lifts.all(func(e): return e.k > 0.01 and e.k <= float(lr.max) + 0.0001),
		"figure pass: the farmer and the cow by the window take the lift at their middle, the far one none (%s)" % [lifts.map(func(e): return snappedf(e.k, 0.001))])
	check(NL.figure_lifts([fig, cow], [], rules).is_empty(), "figure pass: none by day")
	var by_lamp: Array = NL.figure_lifts([fig], lamp, rules, occ)
	fig.position = Vector3(-1, 0, 0)
	var blocked: Array = NL.figure_lifts([fig], lamp, rules, occ)
	fig.position = Vector3(1, 0, 0)
	var open: Array = NL.figure_lifts([fig], lamp, rules, occ)
	check(by_lamp.is_empty() and blocked.is_empty() and open.size() == 1,
		"figure pass: a building between the lantern and the figure keeps it off")
	fig.position = Vector3(5.2, 0, 5.8)
	var mine: Array = lifts.filter(func(e): return e.sprite == fig)
	var quads: Array = NL.field_quads(mine, cam)
	var k: float = mine[0].k
	check(quads.size() == 2 and quads[0].tex == stand and quads[1].tex == held.texture
		and quads.all(func(q): return q.color.is_equal_approx(Color(1, 1, 1, k)) and q.tex != note.texture),
		"figure pass: one quad for the figure and its held item carrying (1, 1, 1, lift), the mark over it left out (%d)" % quads.size())
	var plain_uv: Vector2 = quads[0].uvs[0]
	fig.flip_h = true
	var flipped: Array = NL.field_quads(mine, cam)
	fig.flip_h = false
	fig.texture = step
	var stepped: Array = NL.field_quads(mine, cam)
	fig.texture = stand
	check(plain_uv == Vector2(0, 0) and flipped[0].uvs[0] == Vector2(1, 0) and stepped[0].tex == step,
		"figure pass: the quad follows the facing flip and the animation frame")
	var cow_q: Array = NL.field_quads(lifts.filter(func(e): return e.sprite == cow), cam)
	cow.pixel_size = FW.PX
	var big_q: Array = NL.field_quads(lifts.filter(func(e): return e.sprite == cow), cam)
	var wide := func(q: Dictionary) -> float: return (q.pts[1] as Vector2).distance_to(q.pts[0])
	check(cow_q.size() == 1 and big_q.size() == 1 and absf(wide.call(big_q[0]) / wide.call(cow_q[0]) - 2.0) < 0.05,
		"figure pass: an animal's quad at its own pixel size (%.1f px wide)" % (wide.call(cow_q[0]) if cow_q.size() == 1 else -1.0))
	# The pixel test on the farmer's own texels: each one as drawn under the night tint (and in the
	# sun's share, and with the 3D view's glow by a lit window on it, up to `bloom`) matches; a
	# darker pixel never does; a plaster wall, a dark board, a fence culm or the cow standing in
	# front takes only a small share of the lift (dark colours come close under the night tint).
	var match_at := float(lr.get("match", -1.0))
	var bloom := float(lr.get("bloom", -1.0))
	check(bloom >= 0.0 and bloom <= match_at * 2.0, "figure pass: the bloom allowance is a few 8-bit steps (%.3f)" % bloom)
	var glow := Color(0.041, 0.025, 0.025)   # the most a farmer by Tome's lit window measured brighter (2026-11-08)
	var glow_ok := 0
	var dark_ok := 0
	var tint := Color("46529a")
	var gold := Color(1.0, 0.85, 0.7)
	var img: Image = stand.get_image()
	var cow_img: Image = cow_tex.get_image()
	var cow_px: Array[Color] = []
	for y in cow_img.get_height():
		for x in cow_img.get_width():
			if cow_img.get_pixel(x, y).a >= 0.5:
				cow_px.append(cow_img.get_pixel(x, y))
	var texels := 0
	var own_ok := 0
	var total := 0.0   # the lift the figure's texels take (their brightest channel)
	var leaked := {"plaster": 0.0, "board": 0.0, "culm": 0.0, "cow": 0.0}   # of it, what would land on the one in front
	var walls := {"plaster": Color("e8e0cc"), "board": Color("3a2c24"), "culm": Color("a89c5c")}
	for y in img.get_height():
		for x in img.get_width():
			var own := img.get_pixel(x, y)
			if own.a < 0.5:
				continue
			texels += 1
			var gain := maxf(own.r, maxf(own.g, own.b))   # the lift a texel takes goes with its colour
			total += gain
			var seen := Color(own.r * tint.r, own.g * tint.g, own.b * tint.b)
			var warm_seen := Color(own.r * gold.r * tint.r, own.g * gold.g * tint.g, own.b * gold.b * tint.b)
			if NL.field_off(seen, own, 1.0, Color.WHITE, tint, bloom) < match_at and NL.field_off(warm_seen, own, 1.0, gold, tint, bloom) < match_at:
				own_ok += 1
			var glowing := Color(seen.r + glow.r, seen.g + glow.g, seen.b + glow.b)
			if NL.field_off(glowing, own, 1.0, Color.WHITE, tint, bloom) < match_at and NL.field_off(glowing, own, 1.0, Color.WHITE, tint) >= match_at:
				glow_ok += 1
			var darker := Color(maxf(seen.r - match_at * 1.2, -1.0), seen.g, seen.b)
			if NL.field_off(darker, own, 1.0, Color.WHITE, tint, bloom) >= match_at:
				dark_ok += 1
			for wname in walls:
				var c: Color = walls[wname]
				if NL.field_off(Color(c.r * tint.r, c.g * tint.g, c.b * tint.b), own, 1.0, Color.WHITE, tint, bloom) < match_at:
					leaked[wname] += gain
			var cc: Color = cow_px[(x * 7 + y * 13) % cow_px.size()]
			if NL.field_off(Color(cc.r * tint.r, cc.g * tint.g, cc.b * tint.b), own, 1.0, Color.WHITE, tint, bloom) < match_at:
				leaked.cow += gain
	check(texels > 50 and own_ok == texels and glow_ok == texels,
		"figure pass: the figure's own texels under the tint match, with a lit window's glow on them too (only with bloom) (%d, %d of %d)" % [own_ok, glow_ok, texels])
	check(dark_ok == texels, "figure pass: a pixel darker than the figure's texel never matches (%d of %d)" % [dark_ok, texels])
	var shares := {}
	for wname in leaked:
		shares[wname] = snappedf(leaked[wname] / maxf(total, 0.001), 0.001)
	check(shares.values().all(func(f): return f <= 0.2),
		"figure pass: a wall, a fence or another figure in front keeps its own pixels (share of the lift on it %s)" % [shares])
	for n in [fig, cow, far]:
		n.free()
	cam.free()


## The field's lift in its own pass (NightLights pass 0): the lift and its falloff and cap reach
## each plant's and sprite's quad unchanged, a plant's quad follows its sway and parting as the
## shader moves it (CropClusters.tip_shift on the `clock` uniform), and the pixel test that keeps
## the lift off whatever stands in front (NightLights.field_off, FIELD_SHADER's twin).
func _field_pass(SL: GDScript, NL: GDScript, CC: GDScript, FW: GDScript, cc: Node3D, crop_s: Sprite3D,
		item_s: Sprite3D, spots: Array, rules: Dictionary) -> void:
	var lr: Dictionary = rules.get("lift", {})
	var reach := float(lr.range)
	cc.set_cover(0.0)
	cc.plant({Vector2i(4, 5): "stalk:corn:3:growing"}, func(_c: Vector2i) -> float: return 0.0)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(5, 9, 16)
	cam.look_at(Vector3(5, 0, 5))
	cam.make_current()
	var lifts: Array = SL.field_lifts([crop_s, item_s], [cc], spots, rules)
	# Falloff and cap as before: a lone window's energy times (1 - d / range)², at most `max`.
	var spot: Vector3 = spots[0].pos
	var falloff_ok := true
	for e in lifts:
		var f := 1.0 - (e.mid as Vector3).distance_to(spot) / reach
		falloff_ok = falloff_ok and is_equal_approx(e.k, minf(float(lr.window) * f * f, float(lr.max)))
	check(lifts.size() == 5 and falloff_ok, "field pass: each lift is the window's energy x (1 - d / range)², capped (%d lifts)" % lifts.size())
	var quads: Array = NL.field_quads(lifts, cam)
	var plant_q: Array = quads.filter(func(q): return q.tex != crop_s.texture and q.tex != item_s.texture)
	var by_k := true
	for i in lifts.size():
		var e: Dictionary = lifts[i]
		var shade := 1.0 if e.has("sprite") else float(e.plant.shade)
		var q: Dictionary = quads[i]
		by_k = by_k and q.color.is_equal_approx(Color(shade, shade, shade, e.k))
	check(quads.size() == lifts.size() and plant_q.size() == 3 and by_k,
		"field pass: every lit sprite and plant gets one quad carrying its shade and its lift (%d quads)" % quads.size())
	# The shader's clock: set on every picture each frame; the sway no longer reads TIME.
	cc.set_clock(12.5)
	var clocks_ok: bool = cc.materials().all(func(m): return is_equal_approx(float(m.get_shader_parameter("clock")), 12.5))
	cc._process(0.5)
	check(clocks_ok and is_equal_approx(cc.clock, 13.0) and is_equal_approx(float(cc.materials()[1].get_shader_parameter("clock")), 13.0)
		and not ("TIME" in CC.SHADER) and "uniform float clock" in CC.SHADER,
		"field pass: the plants sway on the clock the view also knows (%.2f)" % cc.clock)
	# The quad follows the sway: its top corners move with the clock as the tip does, its root stays.
	var e0: Dictionary = lifts.filter(func(x): return x.has("crops"))[0]
	var basis := cam.global_basis
	var at_t := func(t: float) -> Array:
		cc.set_clock(t)
		return NL.field_corners(e0, basis)
	var a: Array = at_t.call(1.0)
	var b: Array = at_t.call(2.2)
	var still: Array = NL.plant_corners(e0.root, e0.tex, float(e0.plant.size), basis)
	var want: Vector3 = CC.tip_shift(e0.root, float(e0.plant.size), 1.0, 2.2, cc.wind, cc.pushers, cc.part, basis.x)
	check(a[2].is_equal_approx(still[2]) and b[3].is_equal_approx(still[3]) and not a[0].is_equal_approx(b[0])
		and b[0].is_equal_approx(still[0] + want) and b[1].is_equal_approx(still[1] + want),
		"field pass: a lit plant's quad sways with the plant, its root kept (%s)" % want)
	var amp: float = CC.SWAY * float(e0.plant.size)
	var calm := true
	for t in [0.0, 0.7, 3.1, 9.9]:
		var s: Vector3 = CC.tip_shift(e0.root, float(e0.plant.size), 1.0, t, 0.0, PackedVector2Array(), cc.part, basis.x)
		calm = calm and s.length() <= amp + 0.0001 and is_zero_approx(s.dot(basis.y)) and is_zero_approx(s.dot(basis.z))
	check(calm and CC.tip_shift(e0.root, 1.0, 0.0, 3.0, 0.5, PackedVector2Array([Vector2(e0.root.x, e0.root.z + 0.2)]), cc.part, basis.x).is_zero_approx(),
		"field pass: calm air sways the tip along the view's right, at most SWAY at its size; a stiff stake none")
	# Parting: the farmer's feet just behind the root push the tip away (+z) and down.
	var feet := PackedVector2Array([Vector2(e0.root.x, e0.root.z - 0.25)])
	var parted: Vector3 = CC.tip_shift(e0.root, 1.0, 1.0, 0.0, 0.0, feet, cc.part, basis.x)
	var plain: Vector3 = CC.tip_shift(e0.root, 1.0, 1.0, 0.0, 0.0, PackedVector2Array(), cc.part, basis.x)
	check((parted - plain).z > 0.05 and (parted - plain).y < 0.0,
		"field pass: the quad parts round the farmer's feet as the plant does (%s)" % (parted - plain))
	cc.set_pushers(feet)
	cc.set_clock(0.0)
	var pq: Array = NL.field_quads([e0], cam)
	var moved: PackedVector2Array = pq[0].pts
	var flat: PackedVector2Array = NL._project(NL.plant_corners(e0.root, e0.tex, float(e0.plant.size), basis), cam)
	check(moved[0].distance_to(flat[0]) > 0.5 and moved[3].is_equal_approx(flat[3]),
		"field pass: the drawn quad stands where the parted plant is (%.1f px)" % moved[0].distance_to(flat[0]))
	cc.set_pushers(PackedVector2Array())
	# The pixel test: a plant's or a sprite's own texel as drawn under the night tint takes the lift;
	# a different picture in front of it (another colour) does not.
	var match_at := float(lr.get("match", -1.0))
	check(match_at > 2.0 / 255.0 and match_at < 0.05, "field pass: the match is a few 8-bit steps (%.3f)" % match_at)
	var tint := Color("46529a")
	var leaf := Color("4e7e34")
	var drawn := Color(NL._to_srgb(NL._to_lin(leaf.r) * 0.95) * tint.r, NL._to_srgb(NL._to_lin(leaf.g) * 0.95) * tint.g,
		NL._to_srgb(NL._to_lin(leaf.b) * 0.95) * tint.b)
	check(NL.field_off(drawn, leaf, 0.95, Color.WHITE, tint) < match_at, "field pass: a plant's own pixel under the tint matches")
	check(NL.field_off(leaf * tint + Color(0.004, 0.004, 0.004, 0), leaf, 1.0, Color.WHITE, tint) < match_at,
		"field pass: a sprite's own pixel matches, a faint bloom on it too")
	var culm := Color("a89c5c")
	check(NL.field_off(culm * tint, leaf, 1.0, Color.WHITE, tint) > match_at and NL.field_off(Color("62983e") * tint, leaf, 1.0, Color.WHITE, tint) > match_at,
		"field pass: a fence or a paler leaf standing in front keeps its own pixel")
	var gold := Color(1.0, 0.85, 0.7)
	check(NL.field_off(leaf * gold * tint, leaf, 1.0, gold, tint) < match_at and NL.field_off(leaf * tint, leaf, 1.0, gold, tint) > match_at * 0.5,
		"field pass: the sun's share is counted in what the view drew")
	# The pass: its own copy of the tinted picture, then the field, then the pools and their copy.
	var nl = NL.new()
	root.add_child(nl)
	var code: String = (nl.field.material as ShaderMaterial).shader.code
	check(nl.field_copy.get_index() < nl.field.get_index() and nl.field.get_index() < nl.pools.get_index()
		and nl.pools.get_index() < nl.copy.get_index() and nl.field_copy.copy_mode == BackBufferCopy.COPY_MODE_VIEWPORT
		and "hint_screen_texture" in code and "blend_add" in code and not nl.field_copy.visible,
		"field pass: its own copy of the tinted picture before the pools, added, off while nothing is lit")
	nl.free()
	cam.free()


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
