class_name SfxSynth
extends RefCounted
## Makes our sounds from the recipes in data/sfx.json: no sound files, nothing recorded or
## taken from anywhere. Synthesized in GDScript (not WAVs from a tools/ script) so the repo
## holds only small text recipes that are easy to tune and merge, and nothing needs to be
## re-run by hand after a change. A sound is made on its first play and kept.
##
## A recipe is a list of layers, mixed and then normalized to PEAK. Every layer has dur (s),
## at (start, s), gain, attack (s, linear rise), decay (s, exponential fall after the attack;
## 0 or missing = hold), release (s, linear fade at the end), trem [[rate Hz, depth 0..1], ...]
## and gate [period s, on s, offset s] (soft-edged pulses, for chirps). Kinds:
##   noise  - white (or "color": "brown") noise through lp / hp one-pole filters (Hz)
##   tone   - sine partials [[ratio, gain], ...] at freq, gliding to freq_end
##   pluck  - a plucked string (Karplus-Strong) at freq, damping 0..1 (higher = duller)
##   grains - count tiny noise clicks spread over dur, each fading in `grain` s, filtered

const RATE := 22050
const PEAK := 0.8
const EDGE := 0.004      # s of fade at both ends of a one-shot, so it never clicks
const LOOP_TAIL := 0.3   # s rendered past a loop's end and cross-faded into its start


## A mono sound for `recipe`; `seed` fixes the noise so a key always sounds the same.
static func render(recipe: Dictionary, seed := 0) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var loop_len := float(recipe.get("loop", 0.0))
	var total := loop_len + LOOP_TAIL if loop_len > 0.0 else 0.0
	for l in recipe.get("layers", []):
		if loop_len <= 0.0:
			total = maxf(total, float(l.get("at", 0.0)) + float(l.get("dur", 0.1)))
	var out := PackedFloat32Array()
	out.resize(maxi(int(total * RATE), 1))
	for l in recipe.get("layers", []):
		var layer: Dictionary = l.duplicate()
		if loop_len > 0.0:
			layer.dur = total   # loop layers run the whole length
		_mix(out, layer, rng)
	if loop_len > 0.0:
		out = _wrap(out, int(loop_len * RATE))
	else:
		_fade_edges(out)
	_normalize(out)
	return out


static func to_stream(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s


static func _mix(out: PackedFloat32Array, l: Dictionary, rng: RandomNumberGenerator) -> void:
	var start := int(float(l.get("at", 0.0)) * RATE)
	var n := mini(int(float(l.get("dur", 0.1)) * RATE), out.size() - start)
	if n <= 0:
		return
	var src: PackedFloat32Array
	match String(l.get("kind", "noise")):
		"tone":
			src = _tone(l, n)
		"pluck":
			src = _pluck(l, n, rng)
		"grains":
			src = _grains(l, n, rng)
		_:
			src = _noise(l, n, rng)
	var gain := float(l.get("gain", 1.0))
	var attack := float(l.get("attack", 0.0)) * RATE
	var decay := float(l.get("decay", 0.0)) * RATE
	var release := float(l.get("release", 0.0)) * RATE
	var trem: Array = l.get("trem", [])
	var gate: Array = l.get("gate", [])
	for i in n:
		var a := gain
		if i < attack:
			a *= i / attack
		elif decay > 0.0:
			a *= exp(-(i - attack) / decay)
		if release > 0.0 and i > n - release:
			a *= (n - i) / release
		var t := float(i) / RATE
		for m in trem:
			a *= 1.0 - float(m[1]) * 0.5 * (1.0 + sin(TAU * float(m[0]) * t))
		if not gate.is_empty():
			var p := fposmod(t + float(gate[2] if gate.size() > 2 else 0.0), float(gate[0]))
			a *= sin(PI * p / float(gate[1])) if p < float(gate[1]) else 0.0
		out[start + i] += src[i] * a


static func _noise(l: Dictionary, n: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(n)
	var brown := String(l.get("color", "white")) == "brown"
	var b := 0.0
	for i in n:
		var w := rng.randf_range(-1.0, 1.0)
		if brown:
			b = b * 0.985 + w * 0.15   # leaky sum: deep, soft rumble
			w = b
		s[i] = w
	return _filter(s, l)


## One-pole lowpass (twice, for a softer top) and highpass, from the lp / hp keys.
static func _filter(s: PackedFloat32Array, l: Dictionary) -> PackedFloat32Array:
	if l.has("lp"):
		var k := 1.0 - exp(-TAU * float(l.lp) / RATE)
		for _pass in 2:
			var y := 0.0
			for i in s.size():
				y += k * (s[i] - y)
				s[i] = y
	if l.has("hp"):
		var k := 1.0 - exp(-TAU * float(l.hp) / RATE)
		var y := 0.0
		for i in s.size():
			y += k * (s[i] - y)
			s[i] -= y
	return s


static func _tone(l: Dictionary, n: int) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(n)
	var f0 := float(l.get("freq", 440.0))
	var f1 := float(l.get("freq_end", f0))
	var partials: Array = l.get("partials", [[1, 1]])
	var phase := 0.0
	for i in n:
		phase += TAU * lerpf(f0, f1, float(i) / n) / RATE
		var v := 0.0
		for p in partials:
			v += sin(phase * float(p[0])) * float(p[1])
		s[i] = v
	return s


static func _pluck(l: Dictionary, n: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(n)
	var period := maxi(int(RATE / float(l.get("freq", 440.0))), 2)
	var damp := clampf(float(l.get("damping", 0.5)), 0.0, 1.0)
	var buf := PackedFloat32Array()
	buf.resize(period)
	for i in period:
		buf[i] = rng.randf_range(-1.0, 1.0)
	var keep := 0.996 - 0.02 * damp
	for i in n:
		var j := i % period
		var nxt := buf[(j + 1) % period]
		s[i] = buf[j]
		buf[j] = keep * lerpf(buf[j], nxt, 0.5 + 0.5 * damp)
	return s


static func _grains(l: Dictionary, n: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(n)
	var fade := maxf(float(l.get("grain", 0.003)) * RATE, 1.0)
	var len := int(fade * 6.0)
	for g in int(l.get("count", 10)):
		var at := rng.randi_range(0, maxi(n - 1, 0))
		var amp := rng.randf_range(0.4, 1.0) * (1.0 if rng.randf() < 0.5 else -1.0)
		for i in mini(len, n - at):
			s[at + i] += rng.randf_range(-1.0, 1.0) * amp * exp(-i / fade)
	return _filter(s, l)


## Folds the tail past `length` back over the start, so the loop has no seam.
static func _wrap(s: PackedFloat32Array, length: int) -> PackedFloat32Array:
	var tail := s.size() - length
	for i in tail:
		var k := float(i) / tail
		s[i] = s[i] * k + s[length + i] * (1.0 - k)
	s.resize(length)
	return s


static func _fade_edges(s: PackedFloat32Array) -> void:
	var e := mini(int(EDGE * RATE), s.size() / 2)
	for i in e:
		var k := float(i) / e
		s[i] *= k
		s[s.size() - 1 - i] *= k


static func _normalize(s: PackedFloat32Array) -> void:
	var peak := 0.0
	for v in s:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		var k := PEAK / peak
		for i in s.size():
			s[i] *= k


static func peak(s: PackedFloat32Array) -> float:
	var p := 0.0
	for v in s:
		p = maxf(p, absf(v))
	return p
