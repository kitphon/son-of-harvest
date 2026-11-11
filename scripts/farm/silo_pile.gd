class_name SiloPile
extends RefCounted
## The cut grass piled beside the fodder silo, so its store shows on the farm: none while the
## pile is empty, then a handful, a heap and a big heap as the bundles reach the stages of
## data/animals.json silo.pile (Animals.silo_pile_stage), white-capped under lying snow. It sits
## at the silo's front right corner, between the hatch and the ladder (inside the silo's solid
## cells, so nothing walks through it). The picture is PlaceholderArt "silo:grass:<stage>:<snow>",
## the same in both views: SiloProps.pile stands it up as a sprite in 3D, FarmView draws it over
## the flat silo (`flat_rect`). Both follow Animals.changed (a weed cut with the sickle). No
## class here needs the autoloads (FarmView is drawn in tool runs too).

## Where the pile stands in 3D (1 unit = 1 cell): the silo's front right corner, far enough
## forward that the upright picture stays clear of the tower's round wall (SiloProps: radius
## 0.84, the footing 0.94) seen from the 45° camera.
const AT := Vector2(0.25, 0.2)   # in from the footprint's right edge and its front edge


static func _game() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("Game") if tree != null else null


## The pile's picture key now ("" for none: no silo, or no grass in it).
static func key() -> String:
	var game := _game()
	if game == null:
		return ""
	var stage: int = game.animals.silo_pile_stage()
	if stage <= 0:
		return ""
	var rule: Dictionary = game.animals.silo_rule().get("pile", {})
	var snow: bool = game.season_name() == "winter" and int(game.snow_cover) >= int(rule.get("snow_cover", 30))
	return "silo:grass:%d:%d" % [stage, int(snow)]


## The 3D spot of the pile's foot.
static func at() -> Vector3:
	var r := Rect2(FarmGrid.SILO)
	return Vector3(r.end.x - AT.x, 0.0, r.end.y - AT.y)


## Where the flat view draws a `size` picture of the pile over the silo's box `silo` (FarmView
## roof_rect, px): its bottom right corner, right of the hatch, standing on the box's bottom edge.
static func flat_rect(silo: Rect2, size: Vector2) -> Rect2:
	return Rect2(Vector2(silo.end.x - size.x, silo.end.y - size.y), size)
