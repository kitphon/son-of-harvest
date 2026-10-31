class_name MusicSynth
extends RefCounted
## Makes our music from the scores in data/music.json, like SfxSynth makes the sounds: every
## melody is written there as notes by us, and the voices are synthesized here. Nothing is
## recorded or taken from any game.
##
## A track has bpm, steps_per_beat, steps_per_bar, bars, root (MIDI note), scale (semitones
## of a five-note scale) and voices. A voice plays one instrument with `octave` (whole
## octaves up / down), `gain` and `bars`: one string per bar, steps_per_bar tokens apart by
## spaces. A token is a scale degree (0 = the root, 5 = the root an octave up, -1 = the
## degree below the root), several degrees joined by "+" sound at once, "_" holds the note
## before, "." is a rest. A voice with fewer bars than the track repeats them.
## Instrument kinds:
##   pluck - koto-like: sine partials [[ratio, gain], ...] that ring for `decay` s (higher
##           partials fade faster by `damp`), a small pick `click`, rings `ring` s at least
##   flute - shakuhachi-like: a breathy tone with a scoop up into the note, `vibrato`
##           [rate Hz, depth, delay s], `breath` noise, attack / release
##   pad   - two soft detuned tones, slow attack / release, for held chords

const RATE := SfxSynth.RATE
const TAIL := 8.5       # s rendered past a loop's end and added onto its start (notes ring on)
const NOTE_MAX := 8.0   # s a single note may last, so it fits in the tail


## The loop for `track` (mono, normalized to SfxSynth.PEAK), exactly loop_seconds() long.
## `bars` > 0 renders only that many bars (for quick checks); then nothing wraps round.
static func render(track: Dictionary, instruments: Dictionary, seed := 0, bars := 0) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var length := int(loop_seconds(track) * RATE)
	if bars > 0:
		length = int(bars * bar_seconds(track) * RATE)
	var out := PackedFloat32Array()
	out.resize(length + int(TAIL * RATE))
	var step := step_seconds(track)
	var cache := {}   # one buffer per instrument, pitch and length: tunes repeat their notes
	for v in track.voices:
		var inst: Dictionary = instruments[v.instrument]
		var gain := float(v.get("gain", 1.0)) * float(inst.get("gain", 1.0))
		for n in notes(track, v):
			var at := int(n.step * step * RATE)
			if at >= length:
				continue
			var key := "%s|%d|%d" % [v.instrument, n.midi, n.steps]
			if not cache.has(key):
				cache[key] = _note(inst, freq(n.midi), minf(n.steps * step, NOTE_MAX), rng)
			var buf: PackedFloat32Array = cache[key]
			for i in mini(buf.size(), out.size() - at):
				out[at + i] += buf[i] * gain
	if bars <= 0:
		for i in out.size() - length:   # what rings past the end sounds at the start of the next round
			out[i] += out[length + i]
	out.resize(length)
	SfxSynth._normalize(out)
	return out


## Every note a voice plays: {step, steps (held), midi}, chords as notes on the same step.
static func notes(track: Dictionary, voice: Dictionary) -> Array:
	var out := []
	var held: Array = []   # the notes sounding now, to lengthen on "_"
	var per_bar := int(track.get("steps_per_bar", 8))
	var vbars: Array = voice.bars
	for b in int(track.bars):
		var tokens: PackedStringArray = String(vbars[b % vbars.size()]).split(" ", false)
		for i in tokens.size():
			var t := tokens[i]
			if t == "_":
				for n in held:
					n.steps += 1
				continue
			held = []
			if t == ".":
				continue
			for d in t.split("+"):
				var n := {"step": b * per_bar + i, "steps": 1, "midi": midi(track, voice, d.to_int())}
				out.append(n)
				held.append(n)
	return out


static func midi(track: Dictionary, voice: Dictionary, degree: int) -> int:
	var scale: Array = track.scale
	var octave := floori(float(degree) / scale.size())
	return int(track.root) + 12 * (int(voice.get("octave", 0)) + octave) + int(scale[posmod(degree, scale.size())])


static func freq(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)


static func step_seconds(track: Dictionary) -> float:
	return 60.0 / float(track.bpm) / float(track.get("steps_per_beat", 2))


static func bar_seconds(track: Dictionary) -> float:
	return step_seconds(track) * int(track.get("steps_per_bar", 8))


static func loop_seconds(track: Dictionary) -> float:
	return bar_seconds(track) * int(track.bars)


static func _note(inst: Dictionary, f: float, held: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	match String(inst.kind):
		"flute":
			return _flute(inst, f, held, rng)
		"pad":
			return _pad(inst, f, held)
	return _pluck(inst, f, held, rng)


## Each partial is a sine turned by a fixed rotation per sample (no sin() in the loop) and
## fading by a fixed factor; it stops once it is too quiet to hear.
static func _pluck(inst: Dictionary, f: float, held: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	var n := int(minf(maxf(float(inst.get("ring", 2.0)), held), NOTE_MAX) * RATE)
	s.resize(n)
	var decay := float(inst.get("decay", 0.5))
	var damp := float(inst.get("damp", 0.5))
	for p in inst.get("partials", [[1, 1]]):
		var pf := f * float(p[0])
		if pf > RATE * 0.45:
			continue
		var c := cos(TAU * pf / RATE)
		var sn := sin(TAU * pf / RATE)
		var k := exp(-1.0 / (decay / (1.0 + damp * (float(p[0]) - 1.0)) * RATE))
		var x := 0.0
		var y := 1.0
		var a := float(p[1])
		for i in n:
			s[i] += x * a
			var x2 := x * c + y * sn
			y = y * c - x * sn
			x = x2
			a *= k
			if a < 0.0005:
				break
	var click := float(inst.get("click", 0.0))
	var lp := 0.0
	for i in mini(int(0.006 * RATE), n):
		lp += 0.5 * (rng.randf_range(-1.0, 1.0) - lp)
		s[i] += lp * click * (1.0 - i / (0.006 * RATE))
	_edges(s, 0.003, 0.05)
	return s


static func _flute(inst: Dictionary, f: float, held: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	var attack := float(inst.get("attack", 0.08))
	var release := float(inst.get("release", 0.15))
	held = minf(held, NOTE_MAX - release)
	var n := int((held + release) * RATE)
	s.resize(n)
	var vib: Array = inst.get("vibrato", [5.0, 0.01, 0.3])
	var breath := float(inst.get("breath", 0.1))
	var partials: Array = inst.get("partials", [[1, 1], [2, 0.2], [3, 0.06]])
	var scoop := float(inst.get("scoop", 0.03))   # starts this much flat and slides up
	var phase := 0.0
	var lo := 0.0
	var hi := 0.0
	var k_lo := 1.0 - exp(-TAU * 600.0 / RATE)
	var k_hi := 1.0 - exp(-TAU * 2800.0 / RATE)
	var held_n := held * RATE
	for i in n:
		var t := float(i) / RATE
		var bend := 1.0 - scoop * exp(-t / 0.05)
		var depth := float(vib[1]) * clampf((t - float(vib[2])) / 0.4, 0.0, 1.0)
		phase += TAU * f * bend * (1.0 + depth * sin(TAU * float(vib[0]) * t)) / RATE
		var v := 0.0
		for p in partials:
			v += sin(phase * float(p[0])) * float(p[1])
		var w := rng.randf_range(-1.0, 1.0)   # breath: noise between 600 and 2800 Hz
		lo += k_lo * (w - lo)
		hi += k_hi * (w - hi)
		var chiff := 1.0 + 3.0 * exp(-t / 0.04)
		var env := minf(t / attack, 1.0) * (1.0 - 0.15 * minf(i / maxf(held_n, 1.0), 1.0))
		if i > held_n:
			env *= maxf(1.0 - (i - held_n) / (release * RATE), 0.0)
		s[i] = (v + (hi - lo) * breath * chiff) * env
	_edges(s, 0.002, 0.01)
	return s


static func _pad(inst: Dictionary, f: float, held: float) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	var attack := float(inst.get("attack", 0.6))
	var release := float(inst.get("release", 0.8))
	held = minf(held, NOTE_MAX - release)
	var n := int((held + release) * RATE)
	s.resize(n)
	var detune := float(inst.get("detune", 0.002))
	var w1 := TAU * f * (1.0 - detune) / RATE
	var w2 := TAU * f * (1.0 + detune) / RATE
	var upper := float(inst.get("upper", 0.2))
	var held_n := held * RATE
	for i in n:
		var env := minf(float(i) / (attack * RATE), 1.0)
		if i > held_n:
			env *= maxf(1.0 - (i - held_n) / (release * RATE), 0.0)
		s[i] = (sin(w1 * i) + sin(w2 * i) + upper * sin(2.0 * w2 * i)) * 0.5 * env
	_edges(s, 0.002, 0.02)
	return s


## Short linear fades at both ends (s), so no note starts or stops with a click.
static func _edges(s: PackedFloat32Array, start: float, end: float) -> void:
	var a := mini(int(start * RATE), s.size())
	for i in a:
		s[i] *= float(i) / a
	var e := mini(int(end * RATE), s.size())
	for i in e:
		s[s.size() - 1 - i] *= float(i) / e
