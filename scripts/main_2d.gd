extends Node2D
## The flat top-down view (scenes/main_2d.tscn). The main scene is the 3D one (main_3d.gd).

const T := 16

var view: FarmView
var player: Player
var tint: CanvasModulate


func _ready() -> void:
	view = FarmView.new()
	view.farm = Game.farm
	add_child(view)
	view.show_snow(Game.snow_rules)

	player = Player.new()
	player.farm = Game.farm
	player.position = FarmActions.HOME
	player.action.connect(FarmActions.on_action)
	add_child(player)

	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = FarmGrid.W * T
	cam.limit_bottom = FarmGrid.H * T
	player.add_child(cam)

	tint = CanvasModulate.new()
	add_child(tint)
	add_child(Hud.new())
	add_child(TextBox.new())
	add_child(PauseScreen.new())
	add_child(InventoryScreen.new())

	Game.minute_passed.connect(_update_tint)
	Game.day_started.connect(_on_day_started)
	_update_tint()
	view.set_snow(Game.snow_cover / 100.0)


func _unhandled_input(event: InputEvent) -> void:
	FarmActions.handle_input(event)


func _on_day_started() -> void:
	player.position = FarmActions.HOME
	player.facing = Vector2i.DOWN
	player.cancel_charge()
	_update_tint()
	view.set_snow(Game.snow_cover / 100.0)


func _update_tint() -> void:
	tint.color = Game.light_color()
