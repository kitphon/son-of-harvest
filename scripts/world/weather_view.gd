class_name WeatherView
extends Node2D
## Rain / snow over the flat view, with splash rings in rain: the 2D side of WeatherFX. The
## look (amount, fall speed, wind) is the same Game.weather_style(); the particles live in
## the canvas (not in the camera), so the day / night tint falls on them and they don't slide
## when the camera follows the farmer. `follow` keeps the emitters over the screen.

const T := 16
const AMOUNT := 0.25        # of the 3D amount: the screen shows less ground than the 3D volume
const RAIN_SECONDS := 0.45  # how long a raindrop streaks across the ground before it lands
const SNOW_SECONDS := 4.0   # how long a flake drifts on screen

var screen := Vector2(480, 270)
var fall := ""              # "rain", "snow" or "" (what is falling now, for tests)
var _fall: CPUParticles2D
var _splash: CPUParticles2D
var _travel := Vector2.ZERO # how far a particle moves in its life (px)


func _init() -> void:
	z_index = 50   # over the sprites, under the mine light
	_fall = CPUParticles2D.new()
	_splash = CPUParticles2D.new()
	for p in [_fall, _splash]:
		p.local_coords = false
		p.emitting = false
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.gravity = Vector2.ZERO
		add_child(p)
	var fade := Gradient.new()   # fade in and out, so particles don't pop
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.1, Color.WHITE)
	fade.add_point(0.85, Color.WHITE)
	_fall.color_ramp = fade
	_splash.texture = PlaceholderArt.tex("fx:splash")
	_splash.lifetime = 0.3
	_splash.scale_amount_min = 0.6
	_splash.scale_amount_max = 0.9
	var out := Gradient.new()
	out.set_color(0, Color.WHITE)
	out.set_color(1, Color(1, 1, 1, 0))
	_splash.color_ramp = out


func _ready() -> void:
	screen = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))


## Start the particles for a weather style ({"fall": "rain" | "snow" | "", ...}).
func show_weather(style: Dictionary) -> void:
	fall = style.get("fall", "")
	_fall.emitting = fall != ""
	_splash.emitting = fall == "rain"
	if fall == "":
		return
	var rain := fall == "rain"
	var v := Vector2(float(style.get("wind", 0.0)), float(style.get("speed", 10.0))) * T
	_fall.amount = maxi(int(float(style.get("amount", 500)) * AMOUNT), 1)
	_fall.lifetime = RAIN_SECONDS if rain else SNOW_SECONDS
	_fall.preprocess = _fall.lifetime
	_fall.direction = v.normalized()
	_fall.spread = 2.0 if rain else 25.0
	_fall.initial_velocity_min = v.length() * (0.9 if rain else 0.6)
	_fall.initial_velocity_max = v.length() * (1.1 if rain else 1.2)
	_fall.particle_flag_align_y = rain
	_fall.texture = PlaceholderArt.tex("fx:rain" if rain else "fx:snow")
	_travel = v * _fall.lifetime
	_splash.amount = maxi(_fall.amount / 6, 1)
	_fall.restart()
	if rain:
		_splash.restart()


## Keep the emitters over the screen centred on `center` (canvas pixels): drops start up to a
## life's travel up-wind of it, so they cover the whole screen.
func follow(center: Vector2) -> void:
	_fall.position = center - _travel / 2.0
	_fall.emission_rect_extents = (screen + _travel.abs()) / 2.0 + Vector2(T, T)
	_splash.position = center
	_splash.emission_rect_extents = screen / 2.0
