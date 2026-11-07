class_name FootprintView
extends Node2D
## Footprints in lying snow in the flat view (rules: Footprints; the 3D view's is FootprintLayer):
## each print a small cool blue-grey sole (a toe block and a heel block) turned along the walk,
## fading with age, drawn over the snow under the figures. Made fresh with the map's view.

const T := 16

var trail := Footprints.from_game()


## The walkers' places now ({id: Vector2 cell position}); makes prints while snow lies enough.
func feed(walkers: Dictionary) -> void:
	if not trail.active(Game.snow_cover, Game.sheltered()):
		if not trail.prints.is_empty():
			clear()
		return
	if trail.feed(walkers, Footprints.ground_hold) > 0:
		queue_redraw()


func age(minutes: float) -> void:
	trail.age(minutes, str(Game.weather_style().get("fall", "")) == "snow" and not Game.sheltered())
	queue_redraw()


func clear() -> void:
	trail.clear()
	queue_redraw()


func _draw() -> void:
	var size: Array = trail.rules.size
	var w := float(size[0]) * T
	var l := float(size[1]) * T
	var tone := Color(str(trail.rules.color))
	for p in trail.prints:
		var c := tone
		c.a = float(trail.rules.alpha) * trail.strength(p)
		draw_set_transform(p.pos * T, p.dir.angle() + PI / 2.0)   # the toe, up in the local frame, ahead
		draw_rect(Rect2(-w / 2.0, -l / 2.0, w, l * 0.55), c)
		draw_rect(Rect2(-w * 0.34, l * 0.18, w * 0.68, l * 0.32), c)
	draw_set_transform(Vector2.ZERO, 0.0)
