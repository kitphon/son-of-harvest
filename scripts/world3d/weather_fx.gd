class_name WeatherFX
extends Node3D
## Rain / snow around the camera target, with splash rings on the ground in rain.
## The look per weather (amount, fall speed, wind) comes from data/weather_fx.json via
## Game.weather_style(). Particles live in world space, so they don't slide when the
## emitter follows the player.
##
## The node is turned 45° so its local +z faces the camera and local +x is screen right:
## streaks aligned to their velocity then face the eye, and wind blows across the screen.

const HEIGHT := 8.0        # particles start anywhere from the ground up to this height
const ACROSS := 7.0        # half width of the volume, screen left / right
const DEPTH := 16.0        # half depth along the view; high particles show farther away

var _fall: CPUParticles3D
var _splash: CPUParticles3D


func _init() -> void:
	rotation.y = PI / 4
	_fall = CPUParticles3D.new()
	_splash = CPUParticles3D.new()
	for p in [_fall, _splash]:
		p.local_coords = false
		p.emitting = false
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.gravity = Vector3.ZERO
		add_child(p)
	# Fade in and out, so particles born mid-air or reaching the end of life don't pop.
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.1, Color.WHITE)
	fade.add_point(0.85, Color.WHITE)
	_fall.color_ramp = fade

	_splash.mesh = _quad(Vector2(0.3, 0.3), "fx:splash", false, true)
	_splash.lifetime = 0.3
	_splash.emission_box_extents = Vector3(ACROSS, 0, 7.5)
	_splash.position.y = 0.03
	_splash.scale_amount_min = 0.6
	var out := Gradient.new()
	out.set_color(0, Color.WHITE)
	out.set_color(1, Color(1, 1, 1, 0))
	_splash.color_ramp = out


## Start the particles for a weather style ({"fall": "rain" | "snow" | "", ...}).
func show_weather(style: Dictionary) -> void:
	var fall: String = style.get("fall", "")
	_fall.emitting = fall != ""
	_splash.emitting = fall == "rain"
	if fall == "":
		return
	var speed: float = style.get("speed", 10.0)
	var wind: float = style.get("wind", 0.0)
	var rain := fall == "rain"
	_fall.amount = int(style.get("amount", 500))
	_fall.lifetime = (HEIGHT + 2.0) / speed if rain else HEIGHT / speed * 0.8
	_fall.preprocess = _fall.lifetime
	_fall.direction = Vector3(wind, -speed, 0).normalized()
	_fall.spread = 2.0 if rain else 25.0
	_fall.initial_velocity_min = Vector3(wind, speed, 0).length() * (0.9 if rain else 0.6)
	_fall.initial_velocity_max = Vector3(wind, speed, 0).length() * (1.1 if rain else 1.2)
	_fall.particle_flag_align_y = rain
	# Rain: 1 x 8 streak ~2 px wide on screen (the quad stays turned 45° from the eye, so
	# thinner ones break up); snow: a 4 x 4 flake ~3 px.
	_fall.mesh = _quad(Vector2(0.05, 0.35), "fx:rain", false, false) if rain \
		else _quad(Vector2(0.07, 0.07), "fx:snow", true, false)
	_fall.emission_box_extents = Vector3(ACROSS, HEIGHT / 2, DEPTH)
	_fall.position = Vector3(0, HEIGHT / 2, DEPTH - 7.0)
	_splash.amount = maxi(_fall.amount / 6, 1)
	_fall.restart()
	if rain:
		_splash.restart()


## Keep the volume over the spot the camera looks at.
func follow(target: Vector3) -> void:
	position = target


static func _quad(size: Vector2, key: String, billboard: bool, flat: bool) -> Mesh:
	var m := FarmWorld.flat_material(Color.WHITE)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = PlaceholderArt.tex(key)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var mesh: PrimitiveMesh
	if flat:
		var plane := PlaneMesh.new()
		plane.size = size
		mesh = plane
	else:
		var quad := QuadMesh.new()
		quad.size = size
		mesh = quad
	mesh.material = m
	return mesh
