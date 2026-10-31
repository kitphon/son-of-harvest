extends Node2D
## The flat top-down view (scenes/main_2d.tscn). The main scene is the 3D one (main_3d.gd).
## The farm is a FarmView, other maps a MapView; a change of map fades and swaps them.

const T := 16

var view: Node2D
var player: Player
var cam: Camera2D
var tint: CanvasModulate
var fade: MapFade


func _ready() -> void:
	player = Player.new()
	player.farm = Game.farm
	add_child(player)

	cam = Camera2D.new()
	player.add_child(cam)

	tint = CanvasModulate.new()
	add_child(tint)
	add_child(Hud.new())
	fade = MapFade.new()
	add_child(fade)
	add_child(TextBox.new())
	add_child(PauseScreen.new())
	add_child(EventPlayer.new(player))   # after the Player: moves it during events

	Game.minute_passed.connect(_update_tint)
	Game.day_started.connect(_on_day_started)
	Game.map_changed.connect(func(_id): fade.run(_enter_map))
	_enter_map()
	Game.map_arrived()


func _unhandled_input(event: InputEvent) -> void:
	FarmActions.handle_input(event)


## Swaps in the view for Game.maps and puts the farmer where it says.
func _enter_map() -> void:
	if view != null:
		view.queue_free()
	var m := Game.maps.current()
	if Game.maps.on_farm():
		var fv := FarmView.new()
		fv.farm = Game.farm
		fv.gaps = m.gate_cells()
		view = fv
		add_child(view)
		fv.show_snow(Game.snow_rules)
		fv.set_snow(Game.snow_cover / 100.0)
	else:
		var mv := MapView.new()
		mv.map = m
		view = mv
		add_child(view)
	move_child(view, 0)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = m.w * T
	cam.limit_bottom = m.h * T
	player.farm = Game.farm
	player.position = Game.maps.pos
	player.facing = Game.maps.facing
	player.cancel_charge()
	_update_tint()


## The farmer is put home by the map change (Game.go_home) that comes with the new day.
func _on_day_started() -> void:
	player.cancel_charge()
	_update_tint()
	if view is FarmView:
		view.set_snow(Game.snow_cover / 100.0)


func _update_tint() -> void:
	var m := Game.maps.current()
	tint.color = m.light if m.light != null else Game.light_color()
