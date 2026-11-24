class_name BathLook
extends RefCounted
## The public bath's inside in the flat view (data/maps/sento.json; BathProps in 3D), seen from
## above in whole pixels, lit from the upper left: the tiled tub with its water, ripples and a
## wisp of steam, the washing island's panel, mirrors, stools and buckets, the milk cooler's
## bottle caps, the basket cubbies, the bench's planks, the shoe lockers' key tags, the noren
## across the doorway, the bath's glass sliding door and the painted mountain along the back wall
## (MapView._draw_objects).

# Its own names and colours (BathProps in 3D takes them from here): the flat view is loaded by
# headless tests, which must not pull in the 3D scripts (they need the Game autoload).
const KINDS: Array[String] = ["yubune", "kran", "milk_fridge", "basket_shelf", "bench", "getabako", "bath_noren", "bath_mural", "glass_door", "rock_pool", "bath_hut", "bamboo_screen"]
const POOL_COLOR := Color("7fb8ae")   # Kajika-yu's water, paler and milkier than the sento's
const CEDAR := Color("6a4a34")
const BARK := Color("4e3a2c")
const CULM := Color("a8a464")
const GLASS := Color(0.78, 0.88, 0.9, 0.55)
const WATER_COLOR := Color("5fa6a2")
const STONE_CAP := Color("cfc9bc")
const BRASS := Color("b89448")
const MIRROR := Color("9fb8c4")
const ENAMEL := Color("eeeee8")
const CAP := Color("c8a060")
const STRAW := Color("d8c088")


## Prop `kind` over `r` (pixels) on `c`.
static func draw(c: CanvasItem, kind: String, r: Rect2) -> void:
	match kind:
		"yubune":
			_tub(c, r)
		"rock_pool":
			_rock_pool(c, r)
		"bath_hut":   # the roof from above: bark, its ridge, the noren's edge at the front
			c.draw_rect(r.grow(-1), BARK)
			c.draw_rect(Rect2(r.position.x + 1, r.position.y + 1, r.size.x - 2, 1), BARK.lightened(0.15))
			c.draw_rect(Rect2(r.position.x + 6, floorf(r.get_center().y), r.size.x - 12, 1), BARK.lightened(0.25))
			c.draw_rect(Rect2(floorf(r.get_center().x) - 4, r.end.y - 3, 8, 2), Color("2f4a7a"))
		"bamboo_screen":
			var x := floorf(r.get_center().x) - 1
			c.draw_rect(Rect2(x, r.position.y + 1, 3, r.size.y - 2), CULM)
			c.draw_rect(Rect2(x, r.position.y + 1, 1, r.size.y - 2), CULM.lightened(0.2))
			for y in [r.position.y + 6, r.end.y - 7]:
				c.draw_rect(Rect2(x - 1, y, 5, 1), Color("2a2420"))
		"kran":
			_kran(c, r)
		"milk_fridge":
			var box := r.grow(-2)
			c.draw_rect(box, ENAMEL)
			c.draw_rect(Rect2(box.position.x + 1, box.position.y + 3, box.size.x - 2, box.size.y - 5), Color("2c3a40"))
			for k in 4:
				c.draw_rect(Rect2(box.position.x + 2 + k * 2.5, box.position.y + 5, 1, 1), CAP)
				c.draw_rect(Rect2(box.position.x + 2 + k * 2.5, box.position.y + 8, 1, 1), CAP)
			c.draw_rect(Rect2(box.position.x, box.position.y, box.size.x, 2), Color("fff2c8"))
		"basket_shelf":
			var box := Rect2(r.position.x + 1, r.position.y + 1, r.size.x - 2, 9)
			c.draw_rect(box, Color("4a3424"))
			for k in int(r.size.x / 8):
				c.draw_rect(Rect2(box.position.x + 1 + k * 8, box.position.y + 2, 6, 6), STRAW if k % 3 != 0 else Color("c8a868"))
				if k % 4 == 0:
					c.draw_rect(Rect2(box.position.x + 2 + k * 8, box.position.y + 3, 4, 2), Color("f2f0ea"))
		"bench":
			var seat := r.grow(-3)
			seat.size.x = minf(seat.size.x, 8)
			c.draw_rect(seat, Color("a07a52"))
			c.draw_rect(Rect2(seat.position, Vector2(1, seat.size.y)), Color("b8946a"))
			for y in range(int(seat.position.y) + 5, int(seat.end.y), 6):
				c.draw_rect(Rect2(seat.position.x, y, seat.size.x, 1), Color("7a5a3a"))
		"getabako":
			var box := Rect2(r.position.x + 1, r.position.y + 2, r.size.x - 2, 10)
			c.draw_rect(box, Color("4a3424"))
			for k in int(box.size.x / 4):
				c.draw_rect(Rect2(box.position.x + 1 + k * 4, box.position.y + 1, 3, 8), Color("8a603c"))
				c.draw_rect(Rect2(box.position.x + 2 + k * 4, box.position.y + 4, 1, 2), Color("e0c898"))
		"bath_noren":
			var x := floorf(r.get_center().x) - 1
			c.draw_rect(Rect2(x, r.position.y + 1, 3, r.size.y - 2), Color("2f4a7a"))
			c.draw_rect(Rect2(x, floorf(r.get_center().y), 3, 1), Color("1e3258"))   # the slit between its two halves
		"glass_door":   # the bath's sliding door, a pale frame with frosted panes across the doorway
			c.draw_rect(r.grow(-2), Color("6a4a30"))
			c.draw_rect(r.grow(-3), GLASS)
			c.draw_rect(Rect2(r.position.x + 3, floorf(r.get_center().y), r.size.x - 6, 1), Color("6a4a30"))
		"bath_mural":
			c.draw_texture_rect(PlaceholderArt.tex("bath:mural"), Rect2(r.position.x + 1, r.position.y + 2, r.size.x - 2, r.size.y - 4), false)


## The tub: tiled sides with a pale cap, the water inside with ripples and a little steam.
static func _tub(c: CanvasItem, r: Rect2) -> void:
	var box := r.grow(-1)
	c.draw_texture_rect(PlaceholderArt.tex("bath:tile"), box, true)
	c.draw_rect(box, STONE_CAP, false, 1.0)
	var water := box.grow(-3)
	c.draw_rect(water, WATER_COLOR)
	for k in 4:
		var y := water.position.y + 3 + (k % 2) * maxf(water.size.y - 7, 1.0)
		c.draw_rect(Rect2(water.position.x + 6 + k * water.size.x / 4.0, floorf(y), 8, 1), WATER_COLOR.lightened(0.3))
	c.draw_rect(Rect2(water.position.x + 4, water.position.y, 3, 2), BRASS)   # the spout
	for k in 3:   # steam
		c.draw_rect(Rect2(floorf(water.position.x + water.size.x * (k + 0.5) / 3.0) - 1, water.position.y + 2, 3, 2), Color(1, 1, 1, 0.4))


## The washing island: its tiled panel, a mirror and two taps at each place, a stool and a bucket
## on the near side.
static func _kran(c: CanvasItem, r: Rect2) -> void:
	var panel := Rect2(r.position.x + 1, r.position.y + 2, r.size.x - 2, 5)
	c.draw_texture_rect(PlaceholderArt.tex("bath:tile"), panel, true)
	c.draw_rect(Rect2(panel.position, Vector2(panel.size.x, 1)), STONE_CAP)
	for k in int(r.size.x / 16):
		var x := r.position.x + k * 16 + 8
		c.draw_rect(Rect2(x - 3, panel.position.y + 1, 6, 3), MIRROR)
		c.draw_rect(Rect2(x - 4, panel.end.y, 1, 1), Color("c04a3a"))
		c.draw_rect(Rect2(x + 3, panel.end.y, 1, 1), Color("3a6ac0"))
		c.draw_rect(Rect2(x - 3, r.position.y + 11, 4, 3), Color("8a5a34"))   # the stool
		c.draw_rect(Rect2(x + 2, r.position.y + 11, 3, 3), Color("b08a5a"))   # the bucket


## Kajika-yu's pool: rough grey stones round its edge (lit from the upper left), the pale water inside
## with ripples, and the bamboo pipe at the back left.
static func _rock_pool(c: CanvasItem, r: Rect2) -> void:
	c.draw_rect(r.grow(-1), Color("6a675f"))
	var water := r.grow(-4)
	c.draw_rect(water, POOL_COLOR)
	for k in 5:
		var y := water.position.y + 3 + (k % 2) * maxf(water.size.y - 7, 1.0)
		c.draw_rect(Rect2(water.position.x + 5 + k * water.size.x / 5.0, floorf(y), 7, 1), POOL_COLOR.lightened(0.3))
	for k in int(r.size.x / 5):   # the stones' lit tops along the near and far rims
		var x := r.position.x + 2 + k * 5
		c.draw_rect(Rect2(x, r.position.y + 1, 3, 2), Color("85817a"))
		c.draw_rect(Rect2(x + 1, r.end.y - 3, 3, 1), Color("85817a"))
		c.draw_rect(Rect2(x + 1, r.end.y - 2, 3, 1), Color("4e4c47"))
	c.draw_rect(Rect2(r.position.x + 14, r.position.y, 2, 5), CULM)   # the bamboo pipe
