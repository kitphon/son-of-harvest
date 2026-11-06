class_name NightLamps
extends Node3D
## Real warm lights in the 3D view at dusk and night: a few OmniLight3Ds (no shadows) at the lit
## windows and shoji doors (`FarmWorld.windows`), the stone lanterns (`FarmWorld.lamps`) and the
## festival lights on show (`FestivalProps.glows`), so the lit meshes near them (walls, eaves,
## posts, trees, the stalls' counters) take warm light. NightLights still draws the panes, the
## glows and the pools on the ground; the ground, the water and the grass sit on GROUND_LAYER,
## which these lights leave out, so the ground is not lit twice (and costs no extra pass).
## Cheap on purpose: at most data/light.json "lamps" → max lights, the ones nearest the middle of
## the view, the farthest fading out before it is dropped. By day every light is off, so the
## daytime picture is untouched. The tint multiplies the whole picture afterwards, so each
## light's colour is divided by the tint: it lands as "lamps" → color over the night blue.

const GROUND_LAYER := 2   # VisualInstance3D.layers bit of the ground, water and grass
const LIT_MASK := 1       # the lights' cull mask: everything on the default layer

## The tint over the picture (main_3d sets it), for the colour's division.
var tint: ColorRect
var lights: Array[OmniLight3D] = []


func _ready() -> void:
	var rules: Dictionary = Game.light_data().get("lamps", {})
	for i in int(rules.get("max", 8)):
		var l := OmniLight3D.new()
		l.name = "Lamp%d" % i
		l.shadow_enabled = false
		l.light_cull_mask = LIT_MASK
		l.light_specular = 0.0
		l.omni_range = float(rules.get("range", 2.6))
		l.omni_attenuation = float(rules.get("attenuation", 1.2))
		l.visible = false
		add_child(l)
		lights.append(l)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var rules: Dictionary = Game.light_data().get("lamps", {})
	var picked: Array[Dictionary] = []
	if cam != null:
		picked = nearest(spots_now(rules), focus(cam), lights.size(), float(rules.get("fade", 1.5)))
	var through := color_through(Color(str(rules.get("color", "ffa050"))),
		tint.color if tint != null else Color.WHITE, float(rules.get("boost", 6.0)))
	for i in lights.size():
		var l := lights[i]
		l.visible = i < picked.size()
		if l.visible:
			l.position = picked[i].pos
			l.light_color = through.color
			l.light_energy = picked[i].energy * through.energy


## Every light that would burn now on the worlds on show: {pos, energy} (energy before the
## tint's boost), none by day.
func spots_now(rules: Dictionary) -> Array[Dictionary]:
	var worlds: Array = []
	for w in get_tree().get_nodes_in_group(NightLights.GROUP):
		if w is FarmWorld and w.is_inside_tree() and w.is_visible_in_tree() and not w.is_queued_for_deletion():
			worlds.append(w)
	var fests: Array = []
	for n in get_tree().get_nodes_in_group(FestivalProps.GROUP):
		if n.is_inside_tree() and n.is_visible_in_tree() and n.shown() and not n.is_queued_for_deletion():
			fests.append(n)
	return spots_of(worlds, fests, Game.window_light(), FestivalGlow.darkness(Game.light_color()), rules)


## The lights of `worlds` (FarmWorlds: their windows and lamps, lit `glow`) and `fests`
## (FestivalProps: their glows, standing out `dark`) by data/light.json "lamps": {pos, energy}.
static func spots_of(worlds: Array, fests: Array, glow: float, dark: float, rules: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if glow > 0.0:
		var out_w := float(rules.get("out", 0.45))
		var lamp_out := Vector3(1, 0, 1).normalized() * float(rules.get("lamp_out", 0.3))
		for w in worlds:
			for win in w.windows:
				out.append({"pos": win.pos + win.normal * out_w, "energy": float(rules.get("window", 0.6)) * glow})
			for l in w.lamps:
				out.append({"pos": l.pos + lamp_out, "energy": float(rules.get("lamp", 0.7)) * glow})
	if dark > 0.05:
		for f in fests:
			for g in f.glows:
				var k := float(rules.get("line", 0.6)) if str(g.get("pool", "round")) == "line" else 1.0
				out.append({"pos": g.pos, "energy": float(rules.get("festival", 0.7)) * dark * k})
	return out


## The point on the ground the camera looks at (the farmer, as it follows them).
static func focus(cam: Camera3D) -> Vector3:
	var o := cam.global_position
	var d := -cam.global_basis.z
	if absf(d.y) < 0.001:
		return Vector3(o.x, 0, o.z)
	return o + d * (-o.y / d.y)


## The `n` spots nearest `at` (on the ground plane), nearest first. The farthest kept fades out
## as it nears the first one left out (over `fade` cells), so no light pops on or off as the
## farmer walks.
static func nearest(spots: Array, at: Vector3, n: int, fade: float) -> Array[Dictionary]:
	var sorted: Array = spots.duplicate()
	var flat := func(p: Vector3) -> float: return Vector2(p.x - at.x, p.z - at.z).length()
	sorted.sort_custom(func(a, b): return flat.call(a.pos) < flat.call(b.pos))
	var out: Array[Dictionary] = []
	var cut := INF if sorted.size() <= n else float(flat.call(sorted[n].pos))
	for i in mini(n, sorted.size()):
		var s: Dictionary = sorted[i].duplicate()
		s.energy = float(s.energy) * clampf((cut - float(flat.call(s.pos))) / maxf(fade, 0.01), 0.0, 1.0)
		if s.energy > 0.0:
			out.append(s)
	return out


## The light's own colour and an energy factor so that, multiplied by `tint` afterwards, it lands
## as `warm`: warm / tint, scaled to a colour of at most 1 (its largest part 1) and the factor
## (at most `boost`, so a near-black tint does not blow it up).
static func color_through(warm: Color, tint: Color, boost: float) -> Dictionary:
	var c := Vector3(warm.r / maxf(tint.r, 0.05), warm.g / maxf(tint.g, 0.05), warm.b / maxf(tint.b, 0.05))
	var m := maxf(c.x, maxf(c.y, c.z))
	if m <= 0.0:
		return {"color": Color.BLACK, "energy": 0.0}
	return {"color": Color(c.x / m, c.y / m, c.z / m), "energy": minf(m, boost)}
