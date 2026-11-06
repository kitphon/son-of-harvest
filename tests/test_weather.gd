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


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
