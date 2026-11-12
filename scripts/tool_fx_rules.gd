class_name ToolFxRules
extends RefCounted
## The short pixel effects of a tool's hit, as pure rules (tested headless; numbers in
## data/tool_fx.json). FarmActions asks `effect` what a swing throws (by the tool, what it met,
## the ground and the tool's level), adds the cells and the farmer's spot (`burst`), and hands it
## to Game.start_swing, which sends it out (Game.tool_fx) on the hit frame of the farmer's swing
## pose. `particles` lays a burst out as particles, `step` moves them (gravity, a bounce or a rest
## on the ground, landing drops turning to rings) and `specks` gives what to draw now; the 3D
## view's ToolFxLayer and the flat view's ToolFxView draw those specks and free a burst once all
## of its particles are gone.
##
## Targets: hoe "soil" (tilled), "soft" (a mine soft spot dug), "miss"; can "water"; sickle
## "weed", "miss"; axe "wood" (a stump or a branch hit), "miss"; hammer "rock", "ice" (a mine
## ice block), "miss"; "crop" a harvest pick-up (the leaf puff, no tool). Ground states: "dry",
## "wet", "snow", "mine".

const PATH := "res://data/tool_fx.json"
const TARGETS := {
	"hoe": ["soil", "soft", "miss"],
	"can": ["water"],
	"sickle": ["weed", "miss"],
	"axe": ["wood", "miss"],
	"hammer": ["rock", "ice", "miss"],
}

static var _cfg: Dictionary = {}


static func config() -> Dictionary:
	if _cfg.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		_cfg = JSON.parse_string(f.get_as_text()) if f != null else {}
		if _cfg == null:
			_cfg = {}
	return _cfg


static func _c(cfg: Dictionary) -> Dictionary:
	return config() if cfg.is_empty() else cfg


## The swing's timing: {windup, blow} seconds (the hit is at `windup`).
static func swing_times(cfg := {}) -> Dictionary:
	var s: Dictionary = _c(cfg).get("swing", {})
	return {"windup": float(s.get("windup", 0.12)), "blow": float(s.get("blow", 0.22))}


## The ground's state for the soil colours: "mine" down the mine, "snow" with snow lying (`snow`
## 0..1, outdoors), "wet" from `wet_from` wetness (WetRules) or on a watered cell, else "dry".
static func ground_state(snow: float, wet: float, mine := false, cfg := {}) -> String:
	if mine:
		return "mine"
	if snow > 0.0:
		return "snow"
	if wet >= float(_c(cfg).get("wet_from", 0.35)):
		return "wet"
	return "dry"


## The hoe's soil colours on ground `state`; wet ones are the dry ones in wet.json's `tilled`
## tone at wetness `wet` (at least `wet_from`, so a watered cell reads wet).
static func soil_colors(state: String, wet := 1.0, cfg := {}) -> Array[Color]:
	var g: Dictionary = _c(cfg).get("ground", {})
	var out: Array[Color] = []
	if state == "wet":
		var rule := WetRules.surface("tilled")
		for h in g.get("dry", []):
			out.append(WetRules.tone(Color(str(h)), rule, clampf(maxf(wet, float(_c(cfg).get("wet_from", 0.35))), 0.0, 1.0)))
		return out
	for h in g.get(state if g.has(state) else "dry", []):
		out.append(Color(str(h)))
	return out


static func _puff_colors(state: String, cfg: Dictionary) -> Array[Color]:
	var p: Dictionary = _c(cfg).get("puff", {})
	var key := "snow" if state == "snow" else ("wet" if state == "wet" else "dust")
	var out: Array[Color] = []
	for h in p.get(key, ["c2ab80"]):
		out.append(Color(str(h)))
	return out


static func _kind_colors(kind: String, cfg: Dictionary) -> Array[Color]:
	var out: Array[Color] = []
	for h in _c(cfg).get("kinds", {}).get(kind, {}).get("colors", []):
		out.append(Color(str(h)))
	return out


## Bits of `kind` per cell for a tool at `level`: the data's count, plus `per_level` of it for
## each level past 1.
static func count_of(kind: String, level: int, cfg := {}) -> int:
	var c := _c(cfg)
	var base := int(c.get("kinds", {}).get(kind, {}).get("count", 0))
	return roundi(base * (1.0 + float(c.get("per_level", 0.0)) * (clampi(level, 1, 5) - 1)))


## What a swing of `tool` at `level` throws on meeting `target` on ground `ground`:
## {tool, target, ground, groups: [{kind, count (per cell), colors}]}; {} for nothing (a tool
## without effects, an unknown target). `opts`: hard (a charged blow or a rock left standing: a
## spark), glint (an ore's or a gem's colour: a glint), toward (the sickle with the silo: the
## bits fly to the farmer), wet (the wetness for the wet soil's tone).
static func effect(tool: String, target: String, ground: String, level := 1, opts := {}, cfg := {}) -> Dictionary:
	var groups: Array[Dictionary] = []
	var g := func(kind: String, colors: Array[Color], extra := {}) -> void:
		var d := {"kind": kind, "count": count_of(kind, level, cfg), "colors": colors}
		d.merge(extra, true)
		groups.append(d)
	if target == "miss":
		if not TARGETS.has(tool):
			return {}
		g.call("puff", _puff_colors(ground, cfg))
	elif target == "crop":
		g.call("leaf_puff", _kind_colors("leaf_puff", cfg))
	elif not TARGETS.get(tool, []).has(target):
		return {}
	else:
		match target:
			"soil", "soft":
				var soil := soil_colors("mine" if target == "soft" else ground, float(opts.get("wet", 1.0)), cfg)
				g.call("clods", soil)
				if ground == "dry" or ground == "mine":   # dry soil dusts; wet clods and snow don't
					var dust := {"kind": "puff", "count": int(_c(cfg).kinds.clods.get("dust", 0)), "colors": _puff_colors(ground, cfg)}
					groups.append(dust)
			"water":
				g.call("spray", _kind_colors("spray", cfg))
			"weed":
				g.call("blades", _kind_colors("blades", cfg), {"toward": bool(opts.get("toward", false))})
			"wood":
				g.call("chips", _kind_colors("chips", cfg))
			"rock", "ice":
				g.call("ice" if target == "ice" else "stone", _kind_colors("ice" if target == "ice" else "stone", cfg))
				if opts.get("hard", false):
					g.call("spark", _kind_colors("spark", cfg))
		if opts.get("glint") is Color:
			var gl: Array[Color] = [opts.glint]
			g.call("glint", gl)
	return {"tool": tool, "target": target, "ground": ground, "groups": groups}


## An effect at map cells `cells` (the nearest first) for a farmer whose feet are at `farmer`
## (map cells, fractional) facing `facing`: what Game.start_swing takes and the views draw.
static func burst(fx: Dictionary, cells: Array, farmer: Vector2, facing: Vector2i) -> Dictionary:
	if fx.is_empty() or cells.is_empty():
		return {}
	var out := fx.duplicate()
	var list: Array[Vector2i] = []
	for c in cells:
		list.append(Vector2i(c))
	out.cells = list
	out.farmer = farmer
	out.facing = facing
	return out


## How many particles a burst makes: every group's count on every cell, at most `max_particles`
## (the counts scaled down to fit, at least one a group).
static func planned(b: Dictionary, cfg := {}) -> Dictionary:
	var n := 0
	for gr in b.get("groups", []):
		n += int(gr.count) * (b.cells.size() if gr.kind != "glint" else 1)
	var most := int(_c(cfg).get("max_particles", 90))
	var scale := 1.0 if n <= most else float(most) / float(n)
	return {"total": n, "scale": scale}


static func _rr(rng: RandomNumberGenerator, r: Array) -> float:
	return rng.randf_range(float(r[0]), float(r[1])) if r.size() >= 2 else 0.0


## The burst's particles: [{kind: bit / puff / drop / ring / spark / glint, pos: Vector3 (cells,
## y up), vel, age, life, delay, color, size (sprite px), gravity, bounce, rest}].
static func particles(b: Dictionary, seed: int, cfg := {}) -> Array[Dictionary]:
	var c := _c(cfg)
	var out: Array[Dictionary] = []
	if b.is_empty():
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var scale: float = planned(b, cfg).scale
	var farmer: Vector2 = b.get("farmer", Vector2.ZERO)
	var facing := Vector2(b.get("facing", Vector2i.DOWN))
	var kinds: Dictionary = c.get("kinds", {})
	for gr in b.groups:
		var k: Dictionary = kinds.get(gr.kind, {})
		var cols: Array = gr.colors
		if cols.is_empty():
			continue
		var per := maxi(1, floori(int(gr.count) * scale)) if int(gr.count) > 0 else 0
		var cells: Array = b.cells if gr.kind != "glint" else [b.cells[0]]
		for ci in cells.size():
			var cell: Vector2i = cells[ci]
			var mid := Vector3(cell.x + 0.5, 0.0, cell.y + 0.5)
			for i in per:
				var p := {"kind": "bit", "age": 0.0, "delay": 0.0, "rest": false,
					"color": cols[rng.randi_range(0, cols.size() - 1)], "size": _rr(rng, k.get("size", [1, 1])),
					"life": _rr(rng, k.get("life", [0.4, 0.6])), "gravity": float(k.get("gravity", 9.0)),
					"bounce": float(k.get("bounce", 0.0))}
				var ang := rng.randf() * TAU
				var sp := _rr(rng, k.get("speed", [0.5, 1.0]))
				var side := Vector3(cos(ang), 0.0, sin(ang)) * sp
				match gr.kind:
					"puff":
						p.kind = "puff"
						p.pos = mid + Vector3(rng.randf_range(-0.2, 0.2), 0.05, rng.randf_range(-0.2, 0.2))
						p.vel = side + Vector3(0, float(k.get("rise", 0.25)), 0)
						p.gravity = 0.0
						p.grow = float(k.get("grow", 2.0))
						p.alpha = float(k.get("alpha", 0.55))
					"spray":   # from the spout to a spot on the cell, landing as a ring
						p.kind = "drop"
						var spout := Vector3(farmer.x + facing.x * 0.45, _rr(rng, k.get("spout", [0.45, 0.45])), farmer.y + facing.y * 0.45)
						var land := mid + Vector3(rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.3, 0.3))
						var t := _rr(rng, k.get("flight", [0.25, 0.25]))
						p.gravity = 9.0
						p.pos = spout
						p.vel = (land - spout) / t + Vector3(0, 0.5 * p.gravity * t, 0)
						p.life = t + 0.05
						p.delay = ci * 0.03 + rng.randf_range(0.0, 0.06)
						var ring: Dictionary = k.get("ring", {})
						p.ring = {"life": float(ring.get("life", 0.4)), "radius": float(ring.get("radius", 0.2)),
							"color": Color(str(ring.get("color", "dff0f8")))}
					"glint":
						p.kind = "glint"
						p.pos = mid + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.1, 0.3), rng.randf_range(-0.1, 0.1))
						p.vel = Vector3(0, float(k.get("rise", 0.25)), 0)
						p.gravity = 0.0
						p.delay = i * 0.08
					_:
						if gr.kind == "spark":
							p.kind = "spark"
						p.pos = mid + Vector3(rng.randf_range(-0.15, 0.15), 0.05, rng.randf_range(-0.15, 0.15))
						if gr.get("toward", false):   # the cut grass flies to the farmer (for the silo's pile)
							var to := Vector3(farmer.x, 0.0, farmer.y) - mid
							to.y = 0.0
							side = to.normalized() * float(k.get("toward", 1.5)) * rng.randf_range(0.8, 1.2) + side * 0.3
						p.vel = side + Vector3(0, _rr(rng, k.get("up", [1.5, 2.0])), 0)
				out.append(p)
	return out


## Moves the particles on by `delta` seconds; returns the ones still alive. A falling bit bounces
## (`bounce` of its fall speed) or comes to rest on the ground; a drop landing turns into a ring.
static func step(parts: Array[Dictionary], delta: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in parts:
		if p.delay > 0.0:
			p.delay -= delta
			out.append(p)
			continue
		p.age += delta
		if p.kind == "ring":
			if p.age < p.life:
				out.append(p)
			continue
		if not p.rest:
			p.vel.y -= p.gravity * delta
			p.pos += p.vel * delta
			if p.pos.y <= 0.0 and p.vel.y < 0.0:
				p.pos.y = 0.0
				if p.kind == "drop":   # a splash ring where it landed
					p.kind = "ring"
					p.age = 0.0
					p.life = p.ring.life
					p.color = p.ring.color
					out.append(p)
					continue
				if p.bounce > 0.0 and absf(p.vel.y) > 0.6:
					p.vel = Vector3(p.vel.x * 0.5, -p.vel.y * p.bounce, p.vel.z * 0.5)
				else:
					p.rest = true
					p.vel = Vector3.ZERO
		if p.age < p.life:
			out.append(p)
	return out


## The share of a particle's alpha now: full, then fading over the last `fade` of its life; a
## puff fades all its life; a glint twinkles.
static func alpha_of(p: Dictionary, cfg := {}) -> float:
	var u := clampf(p.age / maxf(p.life, 0.001), 0.0, 1.0)
	match p.kind:
		"puff":
			return float(p.get("alpha", 0.55)) * (1.0 - u)
		"ring":
			return 0.8 * (1.0 - u)
		"glint":
			return sin(u * PI)
	var f := float(_c(cfg).get("fade", 0.35))
	return 1.0 if u < 1.0 - f else (1.0 - u) / maxf(f, 0.001)


## What to draw now: [{pos: Vector3, size: sprite px, color (alpha in it)}]; a ring is eight
## specks round where its drop landed, a puff one growing soft speck. Delayed particles are not shown.
static func specks(parts: Array[Dictionary], cfg := {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in parts:
		if p.delay > 0.0:
			continue
		var a := alpha_of(p, cfg)
		if a <= 0.01:
			continue
		var col: Color = p.color
		col.a *= a
		var u := clampf(p.age / maxf(p.life, 0.001), 0.0, 1.0)
		match p.kind:
			"ring":
				var r: float = p.ring.radius * (0.3 + 0.7 * u)
				for i in 8:
					var an := i * TAU / 8.0
					out.append({"pos": p.pos + Vector3(cos(an) * r, 0.01, sin(an) * r * 0.8), "size": 1.0, "color": col})
			"puff":
				out.append({"pos": p.pos, "size": p.size * lerpf(1.0, p.grow, u), "color": col})
			_:
				out.append({"pos": p.pos, "size": p.size, "color": col})
	return out


## A spot in the world (cells, y up) on the flat view's screen, in map pixels: a cell of height
## lifts it `flat.height_px` up, on whole pixels.
static func flat_of(pos: Vector3, cfg := {}) -> Vector2:
	var h := float(_c(cfg).get("flat", {}).get("height_px", 16))
	return (Vector2(pos.x, pos.z) * 16.0 - Vector2(0, pos.y * h)).round()
