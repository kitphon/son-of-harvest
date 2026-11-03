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

	print("test_weather: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
