extends SceneTree
## Ready for other languages: LangCatalog finds the English (dialogue, data, scripts), no
## script glues a sentence from pieces, every table entry is still used, the English follows
## docs/STYLE_EN.md (American spelling, no "a %s", item names in sentence case, messages that
## end like sentences), Lang.join / list,
## and the pseudo language (every text a third wider) still fits: the screens' labels stay
## inside their boxes and clear of each other, the names fit the HUD, the dialogue lines fit
## the text box.

var failures := 0
var _frame := 0


func _init() -> void:
	_catalog()
	_english_style()
	_join_and_list()
	_pseudo()


# The screens read the Game autoload, which is in the tree from the first frame.
func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_screens()
		_dialogue_fits()
		_thai_dialogue_fits()
		Lang.set_language("en")
		Lang.release()
		print("test_lang: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
		quit(1 if failures else 0)
	return false


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


## The catalogue: text from each kind of place, nothing that isn't shown, no glued pieces,
## and Thai's entries all used.
func _catalog() -> void:
	var cat := LangCatalog.gather()
	var parts := LangCatalog.parts(cat)
	check(parts.dialogue.size() > 500 and parts.data.size() > 200 and parts.code.size() > 200,
		"text from dialogue, data and scripts (%d, %d, %d)" % [parts.dialogue.size(), parts.data.size(), parts.code.size()])
	for k in ["So this is the farm. The fence leans, and the grass is up to my knees...", "Turnip",
			"Bought %s for %d G.", "Found %s (rucksack full).", "%s wags its tail", "a kitchen knife",
			"Spring", "1st", "Watering can", "ready", "Saved food is broken"]:
		check(cat.has(k), "the catalogue has \"%s\"" % k)
	for k in ["tools is a dictionary", "SFX", "Held", "res://data/", "hoe", "Esc", "No dialogue %s"]:
		check(not cat.has(k), "the catalogue leaves out \"%s\"" % k)
	check(cat["Turnip"][0] == "data/crops.json" or "data/crops.json" in cat["Turnip"], "where a text is written (%s)" % [cat["Turnip"]])
	check(LangCatalog.fragments(cat).is_empty(), "no script glues text from pieces: %s" % [LangCatalog.fragments(cat)])
	check(LangCatalog.fragments({"Made %s": ["scripts/x.gd:1"], " x%d": ["scripts/x.gd:2"], " Hi": ["data/a.json"]}) == ["scripts/x.gd:2: \" x%d\""],
		"a script literal with a space at an end is a glued piece; data isn't checked")
	var lits := LangCatalog._literals("\tsay(\"Hi \\\"you\\\"\", 'two', &\"name\", ^\"path\")   # \"not this\"")
	check(lits == ["Hi \"you\"", "two"], "literals on a line: escapes, both quotes, no StringName / NodePath / comment (%s)" % [lits])
	var r := LangCatalog.report("th", cat)
	check(r.stale.is_empty(), "every Thai entry is used by some text: %s" % [r.stale])
	check(r.done.size() + r.missing.size() == cat.size() and r.done.size() > 500, "Thai covers %d of %d" % [r.done.size(), cat.size()])
	check(Lang.current == "en", "the report puts the language back")
	# Covered means wholly: a loose pattern alone doesn't count.
	Lang.set_language("th")
	check(Lang.covered("Bought Turnip seeds for 40 G.") and Lang.covered("Turnip"), "a pattern with its parts known is covered")
	check(Lang.has("Nobody says this, ever") and not Lang.covered("Nobody says this, ever"), "\"%s, %s\" matches but doesn't cover a line")
	Lang.set_language("en")


## docs/STYLE_EN.md's checked rules over every English text.
func _english_style() -> void:
	var cat := LangCatalog.gather()
	var british := RegEx.create_from_string("\\b(colour|favour|neighbour|honour|[Gg]rey\\b|travell|pencill|Mum\\b|realis|organis|any more\\b)")
	var article := RegEx.create_from_string("\\b[Aa]n? %s")
	var bad_spelling := []
	var articles := []
	for k in cat:
		if british.search(k) != null:
			bad_spelling.append(k)
		if article.search(k) != null:
			articles.append(k)
	check(bad_spelling.is_empty(), "American spelling: %s" % [bad_spelling])
	check(articles.is_empty(), "no \"a %%s\" (the article depends on the word): %s" % [articles])
	# Item names: sentence case.
	var titled := []
	for file in ["animals", "crops", "fish", "foods", "forage", "keepsakes", "mine", "recipes"]:
		_names(JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % file)), file, titled)
	check(titled.is_empty(), "item names in sentence case: %s" % [titled])
	# Messages end like sentences: the scripts' messages and notes, and the data's.
	var open_end := []
	var ctx := RegEx.create_from_string("message\\.emit\\(|\"note\":|_no\\(|_say\\(|said\\.append\\(|news\\.append\\(|note = |return \\{\"ok\": false")
	var ended := RegEx.create_from_string("([.!?]|\\.\\.\\.|-[A-Z][a-z]+\")$")   # a quoted note ends with its signature
	var not_sentences := ["Mine floor %d", "Mine floor %d, %s", "eggs, milk or wool", "ores and stones from the mine",
		"Can't read event %s", "Can't read dialogue %s", "ui:cursor"]
	for path in _scripts("res://scripts/"):
		var n := 0
		for line in FileAccess.get_file_as_string(path).split("\n"):
			n += 1
			if line.strip_edges().begins_with("#") or ctx.search(line) == null:
				continue
			for lit in LangCatalog._literals(line):
				if RegEx.create_from_string("[A-Za-z]{2}").search(lit) != null and LangCatalog._words(lit) \
					and ended.search(lit) == null and not lit in not_sentences:
					open_end.append("%s:%d \"%s\"" % [path.get_file(), n, lit])
	for file in ["animals", "body", "foods", "goals", "marriage", "mine", "shops", "tools", "fish"]:
		_messages(JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % file)), file, ended, open_end)
	check(open_end.is_empty(), "messages end with . ! ? or ...: %s" % [open_end])


const MESSAGE_KEYS := ["out_news", "full", "full_message", "special_message", "free_message", "message",
	"closed", "closed_message", "done", "late", "found", "not_candidate", "due", "level_up", "away", "away_late", "forge", "birthday", "festival_away"]


func _messages(v: Variant, file: String, ended: RegEx, out: Array) -> void:
	if v is Dictionary:
		for k in v:
			if k in MESSAGE_KEYS and v[k] is String and v[k] != "" and ended.search(v[k]) == null:
				out.append("%s %s \"%s\"" % [file, k, v[k]])
			elif not v[k] is String:
				_messages(v[k], file, ended, out)
	elif v is Array:
		for e in v:
			_messages(e, file, ended, out)


func _names(v: Variant, file: String, out: Array) -> void:
	if v is Dictionary:
		for k in v:
			if k in ["name", "young_name"] and v[k] is String:
				var words: PackedStringArray = v[k].split(" ")
				for i in range(1, words.size()):
					if words[i] != "" and words[i][0] == words[i][0].to_upper() and words[i][0] != words[i][0].to_lower():
						out.append("%s: %s" % [file, v[k]])
						break
			elif not v[k] is String:
				_names(v[k], file, out)
	elif v is Array:
		for e in v:
			_names(e, file, out)


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir + d + "/"))
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + f)
	return out


func _join_and_list() -> void:
	check(Lang.list([]) == "" and Lang.list(["a"]) == "a" and Lang.list(["a", "b"]) == "a and b"
		and Lang.list(["a", "b", "c"]) == "a, b and c", "lists in English (%s)" % Lang.list(["a", "b", "c"]))
	check(Lang.join(["Good morning!", "", "Game saved."]) == "Good morning! Game saved.", "join skips empty pieces")
	Lang.set_language("th")
	check(Lang.join(["Good morning!", "Game saved."]) == Lang.t("Good morning!") + " " + Lang.t("Game saved."), "join looks up each piece (%s)" % Lang.join(["Good morning!", "Game saved."]))
	check(Lang.t(Lang.list(["Kitchen knife", "Clay pot", "Teapot"])) == PixelFont.shape("มีดทำครัว, หม้อดิน และ กาน้ำชา"), "a list by the table's patterns (%s)" % Lang.t(Lang.list(["Kitchen knife", "Clay pot", "Teapot"])))
	check(Lang.t("You need %s for that." % Lang.list([Cooking.a_tool("knife"), Cooking.a_tool("pot")])) == Lang.t("You need %s for that.") % PixelFont.shape("มีดทำครัว และ หม้อดิน"),
		"the tools you lack, in Thai (%s)" % Lang.t("You need %s for that." % Lang.list([Cooking.a_tool("knife"), Cooking.a_tool("pot")])))
	Lang.set_language("en")


## The pseudo language: no table, every line with letters a third wider, set and left like any.
func _pseudo() -> void:
	check(not Lang.languages().has(Lang.PSEUDO), "pseudo isn't offered in the settings")
	Lang.set_language(Lang.PSEUDO)
	check(Lang.current == Lang.PSEUDO and TranslationServer.translate("Settings") == Lang.t("Settings"), "pseudo is on, Labels too")
	var w := PixelFont.width("Settings")
	var sw := PixelFont.width(Lang.t("Settings"))
	check(sw >= w * (1.0 + Lang.PSEUDO_GROW) and sw < w * (1.0 + Lang.PSEUDO_GROW) + 2 * PixelFont.width(Lang.PSEUDO_PAD) + 2, "a third wider (%d > %d)" % [sw, w])
	check(Lang.t("12:30") == "12:30" and Lang.t("") == "", "no letters: as it is")
	check(Lang.t(Lang.t("Settings")) == Lang.t("Settings"), "padded once, not again when a Label draws it")
	check(Lang.t("Resume\nBack").split("\n").size() == 2 and Lang.t("Resume\nBack").split("\n")[1].begins_with("Back="), "each line padded")
	Lang.set_language("en")
	check(Lang.t("Settings") == "Settings", "back to English")


## Every Label on the open screens in the pseudo language: inside its box (a wrapping label:
## its rows within its width and row limit), clear of the labels and icons beside it.
func _screens() -> void:
	var g: Node = root.get_node("Game")
	g.new_game()
	g.hour = 10
	Lang.set_language(Lang.PSEUDO)
	var hud: CanvasLayer = load("res://scripts/ui/hud.gd").new()
	root.add_child(hud)
	_fits(hud, "the HUD")
	var pause: CanvasLayer = load("res://scripts/ui/pause_screen.gd").new()
	root.add_child(pause)
	for page in ["", "settings", "controls"]:
		pause.open(page)
		_fits(pause, "the pause menu %s" % page)
	pause.close()
	var inv: CanvasLayer = load("res://scripts/ui/inventory_screen.gd").new()
	root.add_child(inv)
	g.inventory.add("turnip", 3)
	g.inventory.add("food:onigiri", 2)
	for mode in ["rucksack", "storage"]:
		inv.open(mode)
		_fits(inv, "the %s" % mode)
		inv.close()
	var shop: CanvasLayer = load("res://scripts/ui/shop_screen.gd").new()
	root.add_child(shop)
	g.money = 99999
	for id in ["general", "smithy", "clinic", "teahouse"]:
		shop.open(id)
		for t in shop.menu.tabs.size():
			shop.menu.tab = t
			shop.menu.cursor = 0
			shop._refresh()
			_fits(shop, "the %s shop, %s tab" % [id, shop.menu.tab_id()])
		shop.close()
	var cook: CanvasLayer = load("res://scripts/ui/cooking_screen.gd").new()
	root.add_child(cook)
	g.house_built.append("kitchen")
	g.open_cooking()
	_fits(cook, "the kitchen")
	cook.close()
	g.house_built.erase("kitchen")
	for n in [hud, pause, inv, shop, cook]:
		n.free()
	g.new_game()


func _fits(screen: Node, where: String) -> void:
	var bad: Array[String] = []
	var spans := []   # [label, parent, Rect2 of its text]
	for l in screen.find_children("*", "Label", true, false):
		if not l.is_visible_in_tree() or l.text == "" or l.is_queued_for_deletion():
			continue
		var shown: String = l.text if l.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED else Lang.t(l.text)
		var w := 0
		var rows := shown.split("\n")
		if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
			rows = PackedStringArray(TextBoxLayout.wrap_rows(shown, int(l.size.x)))
			if l.max_lines_visible > 0 and rows.size() > l.max_lines_visible:
				bad.append("\"%s\" needs %d rows of %d" % [shown.left(40), rows.size(), l.max_lines_visible])
		for line in rows:
			w = maxi(w, PixelFont.width(line))
		var at: Vector2 = l.global_position
		if l.size.x > w and l.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
			at.x += l.size.x - w
		elif l.size.x > w and l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
			at.x += (l.size.x - w) / 2.0
		var text := Rect2(at, Vector2(w, maxf(l.size.y, PixelFont.size())))
		var box := _box_of(l)
		if box != null and text.end.x > box.get_global_rect().end.x + 1:
			bad.append("\"%s\" runs %d px out of its box" % [shown.left(40), int(text.end.x - box.get_global_rect().end.x)])
		spans.append([l, l.get_parent(), text])
	var icons := []   # [icon, parent, Rect2]
	for t in screen.find_children("*", "TextureRect", true, false):
		if t.is_visible_in_tree() and t.texture != null and not t.is_queued_for_deletion():
			var r: Rect2 = t.get_global_rect()
			icons.append([t, t.get_parent(), r if r.size.x >= 1 else Rect2(r.position, t.texture.get_size())])
	for s in spans:
		for ic in icons:
			if s[1] == ic[1] and _overlap(s[2], ic[2]) and RegEx.create_from_string("[A-Za-z]").search(s[0].text) != null:   # a count sits on its slot
				bad.append("\"%s\" runs over an icon" % s[0].text.left(30))
	for i in spans.size():
		for j in range(i + 1, spans.size()):
			if spans[i][1] == spans[j][1] and _overlap(spans[i][2], spans[j][2]):
				bad.append("\"%s\" runs into \"%s\"" % [spans[i][0].text.left(30), spans[j][0].text.left(30)])
	check(bad.is_empty(), "%s fits a longer language: %s" % [where, bad])


## Two rects share more than an edge.
func _overlap(a: Rect2, b: Rect2) -> bool:
	return a.size.x > 1 and a.size.y > 1 and b.size.x > 1 and b.size.y > 1 and a.grow(-0.5).intersects(b.grow(-0.5))


## The nearest Control above `l` with a size: the box the text has to stay in.
func _box_of(l: Control) -> Control:
	var p := l.get_parent()
	while p != null:
		if p is Control and p.size.x > 0:
			return p
		p = p.get_parent()
	return null


## Every dialogue line padded a third still fits the box's rows (the box has no second page).
func _dialogue_fits() -> void:
	var long := []
	var lines := 0
	for file in DirAccess.get_files_at("res://data/dialogue/"):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/" + file))
		if not d is Dictionary or not d.get("lines") is Array:
			continue
		for l in d.lines:
			if l is Dictionary and l.has("text"):
				lines += 1
				if TextBoxLayout.wrap_rows(Lang.t(l.text), TextBoxLayout.text_w(true)).size() > TextBoxLayout.ROWS:
					long.append("%s: %s" % [file, String(l.text).left(50)])
	check(long.is_empty(), "%d of %d dialogue lines a third longer overflow the text box: %s" % [long.size(), lines, long.slice(0, 10)])


## The Thai dialogue: every line with a Thai entry fits the box's rows (at the narrow width,
## beside a portrait), each phrase between spaces fits a row, and the villagers' daily talk
## (data/dialogue/talk_*.json) is Thai all through.
func _thai_dialogue_fits() -> void:
	Lang.set_language("th")
	var long := []
	var untranslated := []
	var thai := 0
	for file in DirAccess.get_files_at("res://data/dialogue/"):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/" + file))
		if not d is Dictionary or not d.get("lines") is Array:
			continue
		for l in d.lines:
			if not (l is Dictionary and l.has("text")):
				continue
			if not Lang.covered(l.text):
				if file.begins_with("talk_"):
					untranslated.append("%s: %s" % [file, String(l.text).left(40)])
				continue
			thai += 1
			var rows := TextBoxLayout.wrap_rows(Lang.t(l.text), TextBoxLayout.text_w(true))
			var wide := false
			for row in rows:
				wide = wide or PixelFont.width(row) > TextBoxLayout.text_w(true)
			if rows.size() > TextBoxLayout.ROWS or wide:
				long.append("%s: %s" % [file, String(l.text).left(40)])
	check(thai > 500 and long.is_empty(), "%d Thai dialogue lines, those overflowing the text box: %s" % [thai, long.slice(0, 10)])
	check(untranslated.is_empty(), "the daily talk is all in Thai, still English: %s" % [untranslated.slice(0, 10)])
	Lang.set_language("en")
