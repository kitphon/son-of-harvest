class_name StoryProps
extends RefCounted
## What the band 5 heart events leave in the world, in 3D: map props gated by a story flag
## (MapManager.with_flags). Hachiro's iron door bell hangs by the farmhouse door (farm map,
## hachiro_bell), the store's new sign stands on its roof over the front (town map, sayo_sign
## "old" / "new" as the prop's `style`) and Tome's jar of pickled plums sits in the farmhouse
## (house map, tome_grandma); the farmhouse's ribbon board hangs on its back wall once a
## contest ribbon is won (house map, ribbons: Keepsakes). The pictures are PlaceholderArt "story:" keys, the same ones the
## flat view draws (StoryView, which also keeps the list of kinds). Same units as MapWorld
## (1 unit = 1 cell).


## A story prop by its kind (MapWorld calls this; on the farm, FarmWorld.make_story_props).
static func prop(w: FarmWorld, p: Dictionary) -> void:
	var r := Rect2(Vector2(p.cell), Vector2(p.size))
	var iron := FarmWorld.flat_material(Color("3a3a40"))
	match str(p.kind):
		"door_bell":
			# Hangs from an iron arm out of the wall by the door post (the farmhouse's wall is at
			# z 3.6, its post at x 5.4), low enough to be seen under the eave from the camera.
			var at := Vector3(r.position.x + 0.3, 1.22, r.end.y - 0.15)
			w._box(Vector3(0.05, 0.05, 0.3), at + Vector3(0.08, 0.03, -0.12), iron)
			var s := _hung(PlaceholderArt.tex(StoryView.art_key(p)), 0.03)
			s.position = at
			w.add_child(s)
		"store_sign":
			# A board standing on the roof's front slope, on two short posts, over the
			# house's front (r.end.y - 0.15, as MapWorld._village_house builds it).
			var front := r.end.y - 0.15
			var cx := r.get_center().x
			var timber := FarmWorld.flat_material(Color("2e221a"))
			for x in [cx - 0.9, cx + 0.9]:
				w._box(Vector3(0.07, 0.5, 0.07), Vector3(x, 1.75, front + 0.05), timber)
			w._picture(StoryView.art_key(p), Vector2(2.4, 0.7), Vector3(cx, 1.98, front + 0.1))
		"ribbon_board":
			# Hung on the back wall over its cell, in front of the wall post that stands there
			# (MapWorld._wall: a post every other cell, 0.05 out from the wall face).
			w._picture(StoryView.art_key(p), Vector2(1.26, 0.78), Vector3(r.get_center().x, 1.15, r.position.y + 0.08))
		"ume_jar":
			var s := FarmWorld.make_sprite(PlaceholderArt.tex(StoryView.art_key(p)))
			s.pixel_size = 0.04
			s.position = Vector3(r.get_center().x, 0, r.get_center().y)
			w.add_child(s)


## A billboard sprite whose top is at its position (a thing hanging down).
static func _hung(tex: Texture2D, px: float) -> Sprite3D:
	var s := FarmWorld.make_sprite(tex)
	s.pixel_size = px
	s.offset = Vector2(0, -tex.get_height() / 2.0)
	return s
