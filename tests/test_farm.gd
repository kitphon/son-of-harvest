extends SceneTree
## Headless rule checks for FarmGrid. Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_farm.gd

var failures := 0


func _init() -> void:
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1

	# Turnip: stages 1 + 2 watered days -> ripe on day 3, gone after picking.
	var f := FarmGrid.new(crops)
	var c := Vector2i(10, 10)
	check(f.till(c), "till")
	check(not f.till(c), "till twice refused")
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			f.till(c + Vector2i(dx, dy))
	check(f.sow(c, "turnip", "spring") == 9, "seed bag sows 3x3")
	var days := 0
	while not f.is_ripe(c) and days < 20:
		f.water_cell(c)
		f.day_end("spring", "sunny", rng)
		days += 1
	check(days == 3, "turnip ripe after 3 watered days (got %d)" % days)
	check(f.harvest(c) == "turnip", "harvest turnip")
	check(f.cell(c).crop == "", "turnip gone after picking")

	# Unwatered crops don't grow; rain waters them.
	var u := Vector2i(10, 11)
	f.day_end("spring", "sunny", rng)
	check(f.cell(u).stage == 0, "dry crop did not grow")
	f.day_end("spring", "rain", rng)
	check(f.cell(u).wet, "rain waters tilled cells")

	# Cucumber regrows to stage 2 after picking.
	var g := FarmGrid.new(crops)
	var k := Vector2i(5, 10)
	g.till(k)
	g.sow(k, "cucumber", "spring")
	for i in 8:
		g.water_cell(k)
		g.day_end("spring", "sunny", rng)
	check(g.harvest(k) == "cucumber", "cucumber ripe after 8 days")
	check(g.cell(k).stage == 2, "cucumber back to stage 2")

	# Out of season crops wither; wrong season refuses seeds.
	g.day_end("summer", "sunny", rng)
	check(g.cell(k).crop == "", "spring crop withers in summer")
	check(g.sow(k, "turnip", "summer") == 0, "turnip not sown in summer")

	# Obstacles: the right tool, the right number of hits.
	var h := FarmGrid.new(crops)
	var s := Vector2i(3, 12)
	h.cell(s).obj = FarmGrid.Obj.STUMP
	check(h.is_solid(s), "stump blocks")
	check(h.hit(s, "hammer") == 0, "hammer does nothing to a stump")
	check(h.hit(s, "axe") == 1 and h.hit(s, "axe") == 1 and h.hit(s, "axe") == 1, "3 axe hits")
	check(h.hit(s, "axe") == 2 and not h.is_solid(s), "4th hit clears the stump")

	# Farmer animation: idle stands still, walking cycles 4 frames at WALK_FPS, starting on a step.
	var a := FarmerAnim.new()
	a.step(1.0, false, false)
	check(a.key(Vector2i.DOWN) == "player:front:idle:0", "idle frame")
	a.step(0.0, true, false)
	check(a.key(Vector2i.UP) == "player:back:walk:1", "walk starts on a step frame")
	a.step(2.0 / FarmerAnim.WALK_FPS, true, false)
	check(a.frame() == 3, "walk advances at WALK_FPS (got %d)" % a.frame())
	a.step(1.0 / FarmerAnim.WALK_FPS, true, false)
	check(a.frame() == 0, "walk cycle wraps")
	a.step(0.0, true, true)
	check(a.pose == "run" and a.frame() == 1, "run restarts the cycle")
	a.step(0.0, false, false)
	check(a.key(Vector2i.RIGHT) == "player:front:idle:0" and FarmerAnim.is_mirrored(Vector2i.RIGHT), "right = mirrored front")
	check(FarmerAnim.is_back(Vector2i.LEFT) and not FarmerAnim.is_mirrored(Vector2i.LEFT), "left = back, not mirrored")
	for pose in ["idle", "walk", "run"]:
		for i in PlaceholderArt.farmer_frames(pose):
			var img := PlaceholderArt.tex("player:front:%s:%d" % [pose, i]).get_image()
			check(img.get_size() == Vector2i(16, 24) and (img.get_pixel(5, 22).a > 0 or img.get_pixel(10, 22).a > 0),
				"%s %d: 16 x 24 with a foot on the ground" % [pose, i])

	# Field sprites: every crop has a look in the data and a sprite per growth look; the key
	# follows the crop's stage.
	var keys := {}
	for id in crops:
		check(crops[id].has("look"), "%s has a look" % id)
		for growth in 4:
			for ripe in ["growing", "ripe"] if growth == 3 else ["growing"]:
				var key := "crop:%s:%d:%s" % [id, growth, ripe]
				var img := PlaceholderArt.tex(key).get_image()
				check(img.get_width() == 16 and img.get_used_rect().end.y == img.get_height(),
					"%s: 16 wide, stands on its bottom row" % key)
				if ripe == "ripe":
					keys[img.get_data()] = key
	check(keys.size() == crops.size(), "ripe crops all look different (%d distinct)" % keys.size())
	var q := FarmGrid.new(crops)
	var qc := Vector2i(6, 6)
	q.till(qc)
	q.sow(qc, "pumpkin", "fall")
	check(PlaceholderArt.cell_key(q, q.cell(qc)) == "crop:pumpkin:0:growing", "sown = seed look")
	q.cell(qc).stage = 3
	check(PlaceholderArt.cell_key(q, q.cell(qc)) == "crop:pumpkin:3:ripe", "ripe pumpkin key")
	q.cell(qc).obj = FarmGrid.Obj.ROCK
	check(PlaceholderArt.cell_key(q, q.cell(qc)) == "rock", "obstacle key wins")

	# Ground tiles: soil state picks the tile, wet soil is clearly darker than dry, the pond
	# gets banks only on its land sides.
	var gk := PlaceholderArt.ground_key(q, qc)
	check(gk.begins_with("ground:tilled:"), "tilled cell -> tilled tile (%s)" % gk)
	q.water_cell(qc)
	check(PlaceholderArt.ground_key(q, qc).begins_with("ground:wet:"), "watered cell -> wet tile")
	check(PlaceholderArt.ground_key(q, Vector2i(20, 15)).begins_with("ground:grass:"), "untouched cell -> grass")
	var dry_l := _mean_luma(PlaceholderArt.tex("ground:tilled:0").get_image())
	var wet_l := _mean_luma(PlaceholderArt.tex("ground:wet:0").get_image())
	check(dry_l - wet_l > 0.12, "wet soil darker than dry (%.2f vs %.2f)" % [wet_l, dry_l])
	var pond := FarmGrid.new(crops)
	for y in range(2, 5):
		for x in range(25, 29):
			pond.fixed[Vector2i(x, y)] = "pond"
	check(PlaceholderArt.ground_key(pond, Vector2i(25, 2)) == "ground:water:%d" % (PlaceholderArt.WATER_N | PlaceholderArt.WATER_W), "pond corner has two banks")
	check(PlaceholderArt.ground_key(pond, Vector2i(26, 3)) == "ground:water:0", "pond middle has no bank")
	for key in ["ground:grass:1", "ground:path:2", "ground:water:15", "ground:wet:3"]:
		var img := PlaceholderArt.tex(key).get_image()
		check(img.get_size() == Vector2i(16, 16) and img.get_used_rect().size == Vector2i(16, 16) \
			and not img.detect_alpha(), "%s: full opaque 16 x 16" % key)

	# Building surfaces: repeating ones are one world unit (16 x 16), all opaque, none missing.
	for kind in ["plaster", "board", "kawara", "planks", "planks_dark", "sugi", "bamboo",
			"noren", "shoji_door", "shoji"]:
		var img := PlaceholderArt.tex("build:" + kind).get_image()
		var tiled: bool = not (kind.begins_with("shoji") or kind == "noren")
		check(not img.detect_alpha() and img.get_pixel(0, 0) != Color("ff00ff")
			and (img.get_size() == Vector2i(16, 16) or not tiled), "build:%s drawn" % kind)

	# Weather looks: every weather that can be rolled has one, a winter storm is a blizzard,
	# the tint multiplies the day light, and the particle sprites are drawn.
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weather_fx.json"))
	var odds: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weather.json"))
	var game_script: GDScript = load("res://scripts/autoload/game.gd")
	for season_id in odds:
		for kind in odds[season_id].keys() + ["sunny"]:
			var look: String = game_script.weather_look(kind, season_id)
			check(fx.has(look) and fx[look].get("fall", "") in ["", "rain", "snow"], "%s in %s has a look" % [kind, season_id])
	check(game_script.weather_look("storm", "winter") == "blizzard", "winter storm = blizzard")
	check(game_script.weather_look("storm", "summer") == "storm", "summer storm = rain storm")
	var gm: Node = game_script.new()
	gm.weather_fx = fx
	gm.hour = 12
	var sunny_l: float = gm.light_color().get_luminance()
	gm.weather_today = "rain"
	check(gm.light_color().is_equal_approx(Color(fx.rain.tint)), "rainy noon = rain tint")
	gm.weather_today = "storm"
	check(gm.light_color().get_luminance() < Color(fx.rain.tint).get_luminance() and sunny_l == 1.0, "storm darker than rain, sun untinted")
	gm.free()
	for key in ["fx:rain", "fx:snow", "fx:splash"]:
		var img := PlaceholderArt.tex(key).get_image()
		check(img.get_pixel(0, 0) != Color("ff00ff") and img.get_used_rect().has_area(), "%s drawn" % key)

	# HUD: the pixel font draws every character the HUD and the game's messages use, the
	# FontFile measures text like PixelFont.width, UI pieces are drawn, boxes fit the screen.
	var font := PixelFont.font()
	var hud_text := "0123456789:/x>G Bin "
	for season_id in game_script.SEASONS:
		hud_text += "%s 30, Year 99" % season_id.capitalize()
	for name in HudLayout.TOOL_NAMES.values():
		hud_text += name
	for id in crops:
		hud_text += crops[id].name + " seeds"
	check(PixelFont.missing(hud_text) == "", "font has the HUD's glyphs (missing '%s')" % PixelFont.missing(hud_text))
	var quote := RegEx.create_from_string("message\\.emit\\(\"([^\"]*)\"")
	for path in ["res://scripts/autoload/game.gd", "res://scripts/farm_actions.gd"]:
		for m in quote.search_all(FileAccess.get_file_as_string(path)):
			var msg := m.get_string(1).replace("%d", "0").replace("%s", "")
			check(PixelFont.missing(msg) == "", "font has the glyphs of '%s'" % msg)
	for txt in ["Spring 1, Year 1", "10:00", "Watering can", "x12"]:
		var fw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.size()).x
		check(int(fw) == PixelFont.width(txt) + int(PixelFont.data().spacing), "font width of '%s' (%d vs %d)" % [txt, fw, PixelFont.width(txt)])
	check(font.get_height(PixelFont.size()) == PixelFont.size(), "font line height")
	var glyph_a := PixelFont.atlas()
	check(glyph_a.get_height() == PixelFont.size() and glyph_a.get_used_rect().has_area(), "font atlas drawn")
	for ch in PixelFont.data().glyphs:
		var rows: Array = PixelFont.data().glyphs[ch]
		var ok := rows.size() <= PixelFont.size()
		for row in rows:
			ok = ok and String(row).length() == String(rows[0]).length()
		check(ok, "glyph '%s' rows even and fit the line" % ch)
	var frame := PlaceholderArt.tex("ui:frame:paper").get_image()
	check(frame.get_pixel(1, 8) == PlaceholderArt.UI_WOOD and frame.get_pixel(8, 8) == PlaceholderArt.UI_PAPER, "paper box: wood edge, paper inside")
	var ui_keys := ["ui:frame:wood", "ui:slot:on", "ui:slot:off", "ui:coin", "ui:stamina"]
	for t in game_script.TOOLS:
		ui_keys.append("ui:seeds:turnip" if t == "seeds" else "ui:tool:" + t)
	for w in HudLayout.WEATHER_ICONS:
		ui_keys.append("ui:weather:" + w)
	for key in ui_keys:
		var img := PlaceholderArt.tex(key).get_image()
		check(img.get_pixel(img.get_width() / 2, img.get_height() / 2) != Color("ff00ff") and img.get_used_rect().has_area(), "%s drawn" % key)
	var screen := Rect2i(0, 0, 480, 270)
	var boxes: Array = HudLayout.BOXES.values()
	for i in boxes.size():
		check(screen.encloses(boxes[i]), "HUD box %s on screen" % boxes[i])
		for j in range(i + 1, boxes.size()):
			check(not boxes[i].intersects(boxes[j]), "HUD boxes %s and %s apart" % [boxes[i], boxes[j]])
	var bar_w: int = 10 + game_script.TOOLS.size() * (HudLayout.SLOT + HudLayout.SLOT_GAP) - HudLayout.SLOT_GAP
	check(bar_w <= HudLayout.BOXES.tools.size.x, "tool bar holds every tool")
	var clock_w := 6 + PixelFont.width("Winter 30, Year 99") + 4
	check(clock_w <= HudLayout.BOXES.clock.size.x, "longest date fits the clock box")

	print("test_farm: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


func _mean_luma(img: Image) -> float:
	var sum := 0.0
	for y in img.get_height():
		for x in img.get_width():
			sum += img.get_pixel(x, y).get_luminance()
	return sum / (img.get_width() * img.get_height())


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
