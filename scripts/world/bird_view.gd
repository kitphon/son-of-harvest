class_name BirdView
extends Node2D
## Small birds on an outdoor map in the flat view (rules: BirdRules, data/birds.json; pictures:
## BirdArt; the 3D view's is BirdLayer): each bird's pixel picture at whole pixels, its feet (or a
## flier's belly) at the foot of the picture. Seen from above, a bird's height lifts it up the
## screen (data "flat".height_px). `player` is the farmer: sparrows and the heron fly off when he
## comes near. Made with the map's view; indoor maps and the mine get nothing.

const T := 16

var map: MapData
var farm: FarmGrid
var player: Node2D
var _t := 0.0
var _scene := {}
var _scene_key := ""
var _state := {}
var _shown: Array[Dictionary] = []


func setup(m: MapData, f: FarmGrid = null, p: Node2D = null) -> BirdView:
	map = m
	farm = f
	player = p
	name = "Birds"
	_t = 0.0 if not BirdRules.forced().is_empty() else float(m.w * 13 + m.h * 29) * 0.31   # `--birds`: from the start, so a frame is the same
	refresh()
	return self


func _process(delta: float) -> void:
	_t += delta
	refresh()


## Reads the clock and the weather, then places every bird of the kinds on show.
func refresh() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var amounts := BirdRules.amounts_now(game, map)
	_shown.clear()
	visible = not amounts.is_empty()
	if not visible:
		return
	var key := "%s|%d|%d" % [map.id, game.season, game.day]
	if key != _scene_key:
		_scene_key = key
		_state.clear()
		_scene = BirdRules.scene_of(map, farm, game.day + 28 * game.season)
	var farmer := BirdRules.NO_FARMER if player == null else player.position / float(T)
	for kind in BirdRules.KINDS:
		if amounts.has(kind):
			_shown.append_array(BirdRules.birds(kind, float(amounts[kind]), _t, _scene, farmer, _state))
	queue_redraw()


## Where a bird's feet are on the screen, in whole pixels.
func screen_of(pos: Vector3) -> Vector2:
	return (Vector2(pos.x, pos.z) * T - Vector2(0, pos.y * float(BirdRules.config().flat.height_px))).round()


## The birds now: [{at: pixel (feet), key: picture key, right: faces right}].
func sprites() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in _shown:
		out.append({"at": screen_of(b.pos), "key": BirdRules.key_of(b), "right": (b.dir as Vector2).x > 0.0})
	return out


func _draw() -> void:
	for s in sprites():
		var tex := PlaceholderArt.tex(str(s.key) + (":r" if s.right else ""))
		draw_texture(tex, (s.at as Vector2) - Vector2(floorf(tex.get_width() / 2.0), tex.get_height()))
