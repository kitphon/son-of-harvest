extends SceneTree
## Headless dialogue checks (DialogueRunner, TextBoxLayout, the dialogue data, the clock
## holding while a text box is open). Run:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_dialogue.gd

var failures := 0


func _init() -> void:
	var who := DialogueRunner.speakers()
	var look := {"chars_per_second": 10, "pause_seconds": {".": 0.2}}

	# Every dialogue in data/dialogue loads.
	for file in DirAccess.get_files_at(DialogueRunner.DIR):
		if file.ends_with(".json") and file != "speakers.json":
			var r := DialogueRunner.open(file.get_basename(), {})
			check(r.error == "" and not r.done(), "data/dialogue/%s loads (%s)" % [file, r.error])

	# The sample, first time: the branch is skipped, letters come at the data's speed.
	var flags := {}
	var r := DialogueRunner.open("bin_note", flags)
	check(r.line().speaker == "farmer" and r.line().face == "surprised", "first time: the farmer finds the note")
	check(r.shown == 0 and not r.revealed(), "a line starts empty")
	r.update(0.1)
	check(r.shown == 4, "40 letters a second: 4 after 0.1 s (got %d)" % r.shown)
	r.press()
	check(r.revealed() and r.index == 1, "a press shows the whole line and stays on it")
	r.press()
	check(r.index == 2 and r.shown == 0 and r.line().speaker == "tsuru", "a second press goes to the next line")
	r.press()
	r.press()
	check(r.line().id == "ask", "on to the question")
	check(r.choices().is_empty(), "no choices until the line is all shown")
	r.press()
	check(r.choices().size() == 2 and r.choice == 0, "two choices, cursor on the first")
	r.press()
	check(r.line().id == "ask", "a press doesn't skip the choices")
	r.move_choice(-1)
	check(r.choice == 1, "up from the first choice wraps to the last")
	r.move_choice(1)
	check(r.choice == 0, "down wraps back to the first")
	r.move_choice(1)
	check(r.pick() and r.line().id == "no", "picking the cursor's choice jumps to its line")
	check(flags.get("bin_note_read") == true and not flags.has("bin_named"), "the choice set its flag only")
	r.press()
	r.press()
	check(r.done() and r.line().is_empty() and r.choices().is_empty(), "\"end\" finishes the dialogue")
	r.press()
	r.update(1.0)
	check(r.done(), "a finished dialogue stays finished")

	# The second time the flag sends it to the short line, which ends after it.
	r = DialogueRunner.open("bin_note", flags)
	check(r.line().get("id") == "again", "flag set: the branch jumps to the short line")
	r.press()
	r.press()
	check(r.done(), "the last line in the list ends the dialogue")

	# The other choice, started at the question with `at` (the --dialogue=id@line flag).
	flags = {}
	r = DialogueRunner.open("bin_note", flags, "ask")
	check(r.line().id == "ask", "starts at the line asked for")
	r.press()
	check(r.pick(0) and r.line().id == "yes", "picking choice 0 by number")
	check(flags == {"bin_note_read": true, "bin_named": true}, "both flags set %s" % flags)
	check(not r.pick(5), "a choice that isn't there is refused")
	check(DialogueRunner.open("bin_note", {}, "nowhere").error != "", "starting at a missing line is refused")
	check(DialogueRunner.open("no_such_dialogue", {}).error != "", "a missing file is refused")
	check(DialogueRunner.open("../speakers", {}).error != "", "a path is not a dialogue id")

	# Punctuation waits a little longer; falling through, line flags, numbers as flags.
	flags = {"count": 2}
	r = DialogueRunner.new({"lines": [
		{"text": "Hi. Yo", "set": {"met": true, "times": 3.0}},
		{"if": "count", "then": "c"},
		{"text": "skipped"},
		{"id": "c", "text": "Done!"}]}, who, flags, look)
	check(r.error == "", "inline dialogue loads (%s)" % r.error)
	check(flags.met == true and typeof(flags.times) == TYPE_INT and flags.times == 3, "a line's flags are set when it shows")
	r.update(0.3)
	check(r.shown == 3, "3 letters after 0.3 s (got %d)" % r.shown)
	r.update(0.1)
	check(r.shown == 3, "a full stop waits 0.2 s longer (got %d)" % r.shown)
	r.update(0.2)
	check(r.shown == 4, "then the next letter (got %d)" % r.shown)
	r.update(5.0)
	check(r.revealed() and r.shown == 6, "never past the end of the line")
	r.press()
	check(r.text() == "Done!", "a whole number flag counts as set")
	r = DialogueRunner.new({"lines": [{"id": "a", "if": "x", "then": "a"}, {"text": "after"}]}, who, {"x": true}, look)
	check(r.done(), "a branch that loops on itself ends instead of hanging")
	r = DialogueRunner.new({"lines": [{"if": "x", "then": "b"}, {"text": "no x"}, {"id": "b", "text": "x"}]}, who, {"x": ""}, look)
	check(r.text() == "no x", "an empty word is not set")

	# Bad data is refused, with the runner finished.
	var line := {"speaker": "tsuru", "text": "Hello."}
	var bad := {
		"not a dictionary": [1, 2],
		"no lines": {},
		"empty lines": {"lines": []},
		"line not a dictionary": {"lines": ["Hello."]},
		"unknown key": {"lines": [{"text": "Hello.", "colour": "red"}]},
		"repeated id": {"lines": [{"id": "a", "text": "A."}, {"id": "a", "text": "B."}]},
		"id end": {"lines": [{"id": "end", "text": "A."}]},
		"no text": {"lines": [{"speaker": "tsuru"}]},
		"blank text": {"lines": [{"text": "   "}]},
		"text not a string": {"lines": [{"text": 12}]},
		"missing glyph": {"lines": [{"text": "Say \"hi\"; ok"}]},
		"too long": {"lines": [{"text": "The rice is green. ".repeat(20)}]},
		"unknown speaker": {"lines": [{"speaker": "stranger", "text": "Hello."}]},
		"bad face": {"lines": [line.merged({"face": "angry"})]},
		"face, no speaker": {"lines": [{"face": "smile", "text": "Hello."}]},
		"mood, no speaker": {"lines": [{"mood": "happy", "text": "Hello."}]},
		"mood not a word": {"lines": [line.merged({"mood": 3})]},
		"empty mood": {"lines": [line.merged({"mood": ""})]},
		"face and mood": {"lines": [line.merged({"face": "smile", "mood": "happy"})]},
		"next nowhere": {"lines": [line.merged({"next": "b"})]},
		"bad flags": {"lines": [line.merged({"set": {"x": [1]}})]},
		"fraction flag": {"lines": [line.merged({"set": {"x": 2.5}})]},
		"empty flag name": {"lines": [line.merged({"set": {"": true}})]},
		"choices and next": {"lines": [line.merged({"next": "end", "choices": [{"text": "Yes"}]})]},
		"no choices": {"lines": [line.merged({"choices": []})]},
		"five choices": {"lines": [line.merged({"choices": [{"text": "A"}, {"text": "B"}, {"text": "C"}, {"text": "D"}, {"text": "E"}]})]},
		"choice no text": {"lines": [line.merged({"choices": [{"next": "end"}]})]},
		"choice too wide": {"lines": [line.merged({"choices": [{"text": "Yes ".repeat(30)}]})]},
		"choice nowhere": {"lines": [line.merged({"choices": [{"text": "Yes", "next": "zz"}]})]},
		"choice bad flags": {"lines": [line.merged({"choices": [{"text": "Yes", "set": "x"}]})]},
		"choice unknown key": {"lines": [line.merged({"choices": [{"text": "Yes", "money": 5}]})]},
		"branch, no then": {"lines": [{"if": "x"}, line]},
		"branch to end": {"lines": [{"if": "x", "then": "end"}, line]},
		"branch with text": {"lines": [{"id": "a", "if": "x", "then": "a", "text": "Hi"}]},
		"then without if": {"lines": [line.merged({"then": "end"})]},
	}
	for what in bad:
		r = DialogueRunner.new(bad[what], who, {}, look)
		check(r.error != "" and r.done() and r.choices().is_empty(), "refused: %s" % what)

	# Flag values as they are kept (the save uses the same rule).
	check(DialogueRunner.flag_value(true) == true and DialogueRunner.flag_value("x") == "x", "bools and words kept")
	check(typeof(DialogueRunner.flag_value(4.0)) == TYPE_INT, "whole numbers become ints")
	check(DialogueRunner.flag_value(2.5) == null and DialogueRunner.flag_value([]) == null and DialogueRunner.flag_value(null) == null, "anything else refused")

	# Wrapping: rows fit, the letters stay where they are, a long word gets a row.
	var text := "Put your crops in this bin before six in the evening, and rest when the sun goes down."
	var rows := TextBoxLayout.wrap_rows(text, 120)
	var fits := rows.size() > 1
	for row in rows:
		fits = fits and PixelFont.width(row) <= 120
	check(fits, "wrapped rows fit the width %s" % rows)
	check(TextBoxLayout.wrapped(text, 120).length() == text.length(), "wrapping keeps the length")
	check(TextBoxLayout.wrapped(text, 120).replace("\n", " ") == text, "only spaces become line breaks")
	check(TextBoxLayout.wrap_rows("a Persimmon-orchard-roadside b", 30).size() == 3, "a word wider than a row gets its own row")
	check(TextBoxLayout.wrap_rows("One\nTwo", 400).size() == 2, "line breaks in the text are kept")
	check(TextBoxLayout.TEXT_POS.y + TextBoxLayout.ROWS * TextBoxLayout.row_h() <= TextBoxLayout.BOX.size.y - 4, "four rows fit in the box")

	# Portraits: one 40 x 40 face per speaker and expression, each expression different.
	for speaker in who:
		if speaker.begins_with("_"):
			continue
		var seen := {}
		for e in DialogueRunner.EXPRESSIONS:
			var img := PlaceholderArt.tex("face:%s:%s" % [speaker, e]).get_image()
			check(img.get_size() == Vector2i(40, 40), "face %s %s is 40 x 40" % [speaker, e])
			seen[img.get_data()] = true
		check(seen.size() == DialogueRunner.EXPRESSIONS.size(), "%s: every expression looks different" % speaker)
		check(who[speaker].get("name", "") != "" and PixelFont.missing(who[speaker].name) == "", "%s has a name the font can draw" % speaker)

	_portraits()
	_refined_portraits()

	# The Game side: talk() asks the view, and an open text box holds the clock.
	var game: Node = load("res://scripts/autoload/game.gd").new()
	var asked := []
	game.dialogue_requested.connect(func(id, at): asked.append([id, at]))
	game.talk("bin_note", "ask")
	check(asked == [["bin_note", "ask"]], "talk() asks for the dialogue %s" % [asked])
	check(game.dialogue_mood == "", "no mood unless one is given")
	game.talk("heart_events", "tome", "sad")
	check(asked.back() == ["heart_events", "tome"] and game.dialogue_mood == "sad", "a say step's mood waits for the text box")
	game.talk("bin_note")
	check(game.dialogue_mood == "", "and the next talk() without one clears it")
	game.hour = 8
	game.minute = 0
	game.dialogue_open = true
	game._process(10.0)
	check(game.minute == 0 and game._accum == 0.0, "the clock waits while a text box is open")
	game.dialogue_open = false
	game._process(1.0)
	check(game.minute == 2, "and runs again when it closes (got %d)" % game.minute)
	game.free()

	print("test_dialogue: %s (%d failed)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures else 0)


## Villager portraits: the moods, who gets a frame, the art and the layout with and without one.
func _portraits() -> void:
	var who := DialogueRunner.speakers()
	# Moods: the line's own, the older face key, the say step's default; unknown -> neutral.
	check(DialogueRunner.mood_of({"mood": "sad"}) == "sad", "a line's mood")
	check(DialogueRunner.mood_of({"face": "smile"}) == "happy" and DialogueRunner.mood_of({"face": "worried"}) == "sad"
		and DialogueRunner.mood_of({"face": "calm"}) == "neutral" and DialogueRunner.mood_of({"face": "surprised"}) == "surprised",
		"face names a mood")
	check(DialogueRunner.mood_of({}) == "neutral" and DialogueRunner.mood_of({}, "angry") == "angry", "no mood: the default, else neutral")
	check(DialogueRunner.mood_of({"mood": "happy"}, "sad") == "happy", "a line's mood beats the say step's")
	check(DialogueRunner.mood_of({"mood": "sleepy"}) == "neutral" and DialogueRunner.mood_of({}, "grumpy") == "neutral",
		"an unknown mood falls back to neutral")
	for face in DialogueRunner.FACE_MOODS:
		check(DialogueRunner.FACE_MOODS[face] in DialogueRunner.MOODS, "face %s is a mood" % face)
	# Who gets a frame: villagers only.
	check(DialogueRunner.portrait_key({"speaker": "tome", "text": "Hi."}) == "portrait:tome:neutral", "a villager's portrait")
	check(DialogueRunner.portrait_key({"speaker": "kota", "mood": "angry"}) == "portrait:kota:angry", "in their mood")
	check(DialogueRunner.portrait_key({"speaker": "sayo", "mood": "sleepy"}) == "portrait:sayo:neutral", "an unknown mood shows neutral")
	check(DialogueRunner.portrait_key({"text": "The wind."}) == "", "narration has no portrait")
	check(DialogueRunner.portrait_key({"speaker": "farmer"}) == "" and DialogueRunner.portrait_key({"speaker": "tsuru"}) == "",
		"the farmer and Tsuru (not villagers) have none")
	var r := DialogueRunner.new({"lines": [{"speaker": "hachiro", "text": "Hm."}, {"speaker": "hachiro", "mood": "happy", "text": "Good."},
		{"speaker": "farmer", "text": "Thanks."}, {"text": "The forge hisses."}]}, who, {})
	r.mood = "surprised"
	check(r.error == "" and r.portrait() == "portrait:hachiro:surprised", "the runner's mood fills a line without one")
	r.set_speed(0.0)
	r.press()
	check(r.portrait() == "portrait:hachiro:happy", "a line with a mood keeps it")
	r.press()
	check(r.portrait() == "", "the farmer's line: no frame")
	r.press()
	check(r.portrait() == "" and not r.done(), "narration: no frame")
	# Every mood written in the data is one the art draws (the fallback is for safety, not typos).
	var moods_seen := {}
	for file in DirAccess.get_files_at(DialogueRunner.DIR):
		if not file.ends_with(".json") or file == "speakers.json":
			continue
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(DialogueRunner.DIR + file))
		for l in d.lines:
			if l.has("mood"):
				moods_seen[l.mood] = true
				check(l.mood in DialogueRunner.MOODS, "%s: mood %s is one of MOODS" % [file, l.mood])
	for file in DirAccess.get_files_at("res://data/events/"):
		var e: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/events/" + file))
		if e is Dictionary and e.get("steps") is Array:
			for s in e.steps:
				if s is Dictionary and s.has("mood"):
					check(s.mood in DialogueRunner.MOODS, "%s: say mood %s is one of MOODS" % [file, s.mood])
	check(moods_seen.size() == DialogueRunner.MOODS.size(), "the data uses every mood %s" % [moods_seen.keys()])
	# The art: a 40 x 40 portrait per villager and mood, each mood different, each villager different.
	var neutral := {}
	for id in Villagers.all():
		var seen := {}
		for m in DialogueRunner.MOODS:
			var img := PlaceholderArt.tex("portrait:%s:%s" % [id, m]).get_image()
			check(img.get_size() == Vector2i(40, 40), "portrait %s %s is 40 x 40" % [id, m])
			seen[img.get_data()] = true
		check(seen.size() == DialogueRunner.MOODS.size(), "%s: every mood looks different" % id)
		var plain := PlaceholderArt.tex("portrait:%s:neutral" % id).get_image().get_data()
		neutral[plain] = true
		check(PlaceholderArt.tex("portrait:%s:sleepy" % id).get_image().get_data() == plain, "%s: an unknown mood draws neutral" % id)
		check(who.has(id), "%s has a name tag in speakers.json" % id)
	check(neutral.size() == Villagers.all().size() and neutral.size() >= 4, "every villager has a face of their own")
	# Portrait hair: a speaker's portrait_hair is one PlaceholderArt.PORTRAIT_HAIR knows, every
	# style draws its own hair, and the six women who can marry each have a style of their own.
	for id in who:
		if not who[id] is Dictionary:   # the file's _note
			continue
		var ph: Variant = who[id].get("face", {}).get("portrait_hair", null)
		check(ph == null or str(ph) in PlaceholderArt.PORTRAIT_HAIR, "%s's portrait_hair %s is a known style" % [id, ph])
	var drawn := {}
	for style in PlaceholderArt.PORTRAIT_HAIR:
		var hi := Image.create(40, 40, false, Image.FORMAT_RGBA8)
		var hl := {"hair_style": style, "hair": "2a1e1a", "accent": "c8342c"}
		PlaceholderArt._portrait_hair_behind(hi, hl, 20.0)
		PlaceholderArt._portrait_hair(hi, hl, 20.0)
		drawn[hi.get_data()] = true
	check(drawn.size() == PlaceholderArt.PORTRAIT_HAIR.size(), "every portrait hair style draws differently (%d of %d)" % [drawn.size(), PlaceholderArt.PORTRAIT_HAIR.size()])
	var styles := {}
	for id in ["sayo", "fumi", "haru", "mio", "kaede", "shino"]:
		styles[PlaceholderArt.portrait_hair_style(id)] = id
	check(styles.size() == 6, "the women who can marry each wear their own portrait hair %s" % [styles])
	check(PlaceholderArt.portrait_hair_style("shino") == "low_knot" and PlaceholderArt.portrait_hair_style("sayo") == "long", "Shino a low knot, Sayo her figure's long hair")
	# The layout, with and without a portrait: everything inside the box and the screen, the
	# text clear of the frame, the tag over the box's top edge above the text.
	var box := Rect2i(Vector2i.ZERO, TextBoxLayout.BOX.size)
	check(Rect2i(0, 0, 480, 270).encloses(TextBoxLayout.BOX), "the box is on screen")
	check(box.encloses(TextBoxLayout.PORTRAIT), "the portrait frame is in the box")
	check(TextBoxLayout.PORTRAIT.size - Vector2i(4, 4) == Vector2i(40, 40), "the frame holds a 40 x 40 portrait")
	for framed in [true, false]:
		var t := TextBoxLayout.text_rect(framed)
		var what := "with a portrait" if framed else "without"
		check(box.encloses(t), "%s: the text rows are in the box %s" % [what, t])
		check(t.end.x == TextBoxLayout.TEXT_POS.x + TextBoxLayout.TEXT_W, "%s: the text ends where it always does" % what)
		var tag := TextBoxLayout.BOX.position.x + TextBoxLayout.name_x(framed)
		check(tag >= 0 and tag < TextBoxLayout.BOX.position.x + t.position.x, "%s: the name tag starts on screen, over the text" % what)
		check(TextBoxLayout.BOX.position.y - TextBoxLayout.NAME_H + 4 >= 0, "%s: the tag is on screen" % what)
	check(not TextBoxLayout.text_rect(true).intersects(TextBoxLayout.PORTRAIT), "beside a portrait the text clears the frame")
	check(TextBoxLayout.text_rect(false).position.x < TextBoxLayout.PORTRAIT.end.x, "without one the text uses its room")
	check(TextBoxLayout.text_w(false) > TextBoxLayout.text_w(true), "so its rows are wider")
	# A line checked at the narrow width (DialogueRunner does) fits the wide one too.
	var text := "My teacher said a tool remembers who uses it well. I never believed him until I was old, and now I do."
	var narrow := TextBoxLayout.wrap_rows(text, TextBoxLayout.text_w(true)).size()
	check(narrow <= TextBoxLayout.ROWS and TextBoxLayout.wrap_rows(text, TextBoxLayout.text_w(false)).size() <= narrow,
		"a line that fits beside a portrait fits without one")


## The refined portraits (PortraitArt, data/portrait_art.json): every villager in every mood,
## the little one at each stage for each spouse who can marry, and the generic face:<speaker>
## keys. Each is 40 x 40 and opaque, has no black part line left, shows the skin's shade, base
## and lit tones with the lit side to the left of the shade side, draws its lines in the
## skin's deep tone, and the stubble still finds the skin. Every mood still looks different.
func _refined_portraits() -> void:
	var a := PortraitArt.art()
	check(a.has("tone") and a.has("deep") and a.has("rim") and int(a.get("band", 0)) >= 1, "data/portrait_art.json has the numbers")
	var line := PlaceholderArt.OUTLINE.to_html()
	var sets := []   # [key, skin colour, label]
	for id in Villagers.all():
		for m in DialogueRunner.MOODS:
			sets.append(["portrait:%s:%s" % [id, m], Color(Villagers.look(id).get("skin", "f2c79b")), id])
	for sp in ["sayo", "fumi", "haru", "mio", "kaede", "shino"]:
		var c := Child.look(Villagers.look(sp), "f2c79b")
		for st in Child.FIGURE_STAGES:
			var seen := {}
			for m in DialogueRunner.MOODS:
				var key := "portrait:%s:%s:%s:%s:%s:%s:%s" % [Child.ID, m, st, Child.small_style(str(c.hair_style), st), c.skin, c.hair, c.top]
				sets.append([key, Color(str(c.skin)), "child of %s %s" % [sp, st]])
				seen[PlaceholderArt.tex(key).get_image().get_data()] = true
			check(seen.size() == DialogueRunner.MOODS.size(), "child of %s, %s: every mood looks different" % [sp, st])
	var who := DialogueRunner.speakers()
	for sp in who:
		if who[sp] is Dictionary and who[sp].has("face"):
			for e in DialogueRunner.EXPRESSIONS:
				sets.append(["face:%s:%s" % [sp, e], Color(who[sp].face.get("skin", "f2c79b")), "face " + sp])
	var bad := []
	for s in sets:
		var img: Image = PlaceholderArt.tex(s[0]).get_image()
		img.convert(Image.FORMAT_RGBA8)
		var tn := PortraitArt.tones(s[1], true)
		var keys := []
		for t in tn:
			keys.append(_rgba8(t))
		var count := [0, 0, 0, 0]
		var xs := [0.0, 0.0, 0.0]
		var black := 0
		var clear := 0
		for y in 40:
			for x in 40:
				var p := img.get_pixel(x, y)
				if p.a < 1.0:
					clear += 1
				var k := p.to_html()
				if k == line:
					black += 1
				for i in 4:
					if k == keys[i]:
						count[i] += 1
						if i < 3:
							xs[i] += x
		var why := ""
		if img.get_size() != Vector2i(40, 40) or clear > 0:
			why = "not a full 40 x 40"
		elif black > 0:
			why = "%d black line pixels" % black
		elif count[0] == 0 or count[1] == 0 or count[2] == 0:
			why = "skin tones %s" % [count]
		elif xs[2] / count[2] >= xs[0] / count[0]:
			why = "lit not left of shade"
		elif count[3] == 0:
			why = "no line in the skin's deep tone"
		if why != "":
			bad.append("%s (%s)" % [s[0], why])
	check(bad.is_empty(), "every portrait (%d) is refined: %s" % [sets.size(), bad.slice(0, 6)])
	check(sets.size() >= Villagers.all().size() * DialogueRunner.MOODS.size() + 90, "the portraits checked include the child and the faces (%d)" % sets.size())
	# The stubble is still drawn over the toned skin.
	var stubbled := PlaceholderArt.tex("portrait:hachiro:neutral").get_image()
	stubbled.convert(Image.FORMAT_RGBA8)
	var stub := _rgba8(Color(Villagers.look("hachiro").get("skin", "d9a473")).darkened(0.16))
	var n := 0
	for y in 40:
		for x in 40:
			if stubbled.get_pixel(x, y).to_html() == stub:
				n += 1
	check(n >= 10, "Hachiro's stubble is drawn on the toned skin (%d)" % n)
	# The eyes are drawn in the data's eye colour, the mouth in the skin's deep tone.
	var tome := PlaceholderArt.tex("portrait:tome:neutral").get_image()
	tome.convert(Image.FORMAT_RGBA8)
	var eyes := 0
	for y in 40:
		for x in 40:
			if tome.get_pixel(x, y).to_html() == _rgba8(PortraitArt.eye()):
				eyes += 1
	check(eyes >= 8, "Tome's eyes are in the eye colour (%d)" % eyes)


func _rgba8(c: Color) -> String:
	var q := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	q.set_pixel(0, 0, c)
	return q.get_pixel(0, 0).to_html()


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
