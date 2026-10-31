class_name Lightning
extends RefCounted
## When lightning flashes in a storm, and how bright it is at each moment (0..1). Pure timing,
## so tests can step it; the 3D view turns the brightness into a short wash of pale light.
## Style from data/weather_fx.json ("lightning" in a look):
##   gap [min, max] s between flashes, first [min, max] s before the first one, and pulses
##   [[start s, length s, level 0..1], ...]: each pulse jumps to its level and fades out.
## The gaps keep it far below three flashes a second (the usual photosensitivity limit), and
## Game.flashes_enabled turns it off altogether.

var rng: RandomNumberGenerator
var _style: Dictionary = {}
var _wait := INF      # seconds until the next flash starts
var _t := -1.0        # seconds into the current flash, -1 between flashes


func _init(generator: RandomNumberGenerator = null) -> void:
	rng = generator if generator else RandomNumberGenerator.new()


## A new style ({} = no lightning). The first flash comes after `first` seconds.
func reset(style: Dictionary) -> void:
	_style = style
	_t = -1.0
	_wait = _pick("first") if not style.is_empty() else INF


## Advance by `delta` seconds; returns the brightness now.
func step(delta: float) -> float:
	if _style.is_empty():
		return 0.0
	if _t >= 0.0:
		_t += delta
		if _t >= duration(_style):
			_t = -1.0
			_wait = _pick("gap")
	else:
		_wait -= delta
		if _wait <= 0.0:
			_t = -_wait
	return pulse_at(_t, _style) if _t >= 0.0 else 0.0


## How long one flash lasts: the end of its last pulse.
static func duration(style: Dictionary) -> float:
	var end := 0.0
	for p in style.get("pulses", []):
		end = maxf(end, float(p[0]) + float(p[1]))
	return end


## Brightness t seconds into a flash: the brightest pulse at that moment, fading linearly.
static func pulse_at(t: float, style: Dictionary) -> float:
	var b := 0.0
	for p in style.get("pulses", []):
		var into := t - float(p[0])
		if into >= 0.0 and into < float(p[1]):
			b = maxf(b, float(p[2]) * (1.0 - into / float(p[1])))
	return b


func _pick(key: String) -> float:
	var r: Array = _style.get(key, _style.get("gap", [10.0, 10.0]))
	return rng.randf_range(float(r[0]), float(r[1]))
