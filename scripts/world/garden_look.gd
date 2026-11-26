class_name GardenLook
extends RefCounted
## What the temple garden's pond-side pieces look like, shared by both views (GardenProps builds
## them in 3D, MapView._draw_garden draws them flat): the kinds, the rock shapes, the colours and
## when the shrubs flower. Pure (no world classes), so the flat view loads without the 3D ones.

const KINDS: Array[String] = ["garden_rock", "shrub"]
const SHAPES: Array[String] = ["tall", "flat", "low", "pair", "boulder", "granite"]
const GRANITE: Array[Color] = [Color("8c877c"), Color("aaa498"), Color("c6c0b2")]   # pale granite (Kajika-yu's shore)
const STONE: Array[Color] = [Color("4e4c47"), Color("6a675f"), Color("85817a")]
const MOSS := Color("5f7a3a")
## The moss on the rocks through the year, eased between these [day of the year (0..119), colour]
## (2026-11-26, the user asked for it to change a little by season): fresh and light in spring,
## its most vivid green wet in the early summer rains, duller and olive in late summer's heat, its
## plain green in fall, dull and a little brown in winter's cold. MOSS is fall's.
const MOSS_YEAR := [[15, Color("6a8c40")], [38, Color("588c3a")], [55, Color("72803e")], [75, Color("5f7a3a")], [105, Color("68703f")]]
const LEAF: Array[Color] = [Color("2f5626"), Color("3f6e2e"), Color("58893a")]
const LEAF_WINTER: Array[Color] = [Color("2a4626"), Color("35582c"), Color("466a36")]
const BLOOM := Color("e690b4")
const FALL_RED := Color("a8452c")
## A wild bush's leaves at their most turned in fall [dark, mid, light]: rust and amber, reached a
## share of the way from LEAF by each bush's own turn (wild_fall_tones).
const FALL_WILD: Array[Color] = [Color("5c3a1c"), Color("8c5a28"), Color("b4823a")]


## The rocks' moss on `day` (1..30) of `season` (MOSS_YEAR, eased round the year).
static func moss_of(season: String, day: int) -> Color:
	var seasons := ["spring", "summer", "fall", "winter"]
	var at := float(maxi(seasons.find(season), 0) * 30 + clampi(day, 1, 30) - 1)
	var n := MOSS_YEAR.size()
	for i in n:
		var a: Array = MOSS_YEAR[i]
		var b: Array = MOSS_YEAR[(i + 1) % n]
		var from := float(a[0])
		var to := float(b[0]) + (120.0 if i == n - 1 else 0.0)
		var x := at + (120.0 if at < from else 0.0)
		if x >= from and x <= to:
			return (a[1] as Color).lerp(b[1], smoothstep(from, to, x))
	return MOSS


## The rocks' moss now (the Game autoload's season and day; MOSS when there is none, e.g. a tool).
static func moss_now() -> Color:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game") if Engine.get_main_loop() is SceneTree else null
	if game == null:
		return MOSS
	return moss_of(game.season_name(), int(game.day))


## Whether a shrub flowers on day `day` of `season` (the azalea: late spring into early summer).
static func blooms(season: String, day: int) -> bool:
	return (season == "spring" and day >= 16) or (season == "summer" and day <= 6)


## How far a wild bush with `seed` (the cell's, both views) has turned on `day` of fall, 0 green
## .. 1 FALL_WILD: each bush its own way (some keep green, some go olive, a few rust), further on
## as the season goes (2026-11-26, the user: the scattered red facets read as orange stains).
static func wild_turn(seed: int, day: int) -> float:
	var roll := float(posmod(seed * 2654435761 >> 7, 1000)) / 1000.0
	var turn := 0.15 if roll < 0.35 else (0.45 if roll < 0.75 else 0.8)
	turn += (float(posmod(seed * 40503, 97)) / 97.0 - 0.5) * 0.16
	return clampf(turn * lerpf(0.55, 1.0, clampf((day - 1) / 29.0, 0.0, 1.0)), 0.0, 1.0)


## A wild bush's leaf tones on `day` of fall: LEAF eased toward FALL_WILD by wild_turn.
static func wild_fall_tones(seed: int, day: int) -> Array[Color]:
	var t := wild_turn(seed, day)
	var out: Array[Color] = []
	for i in LEAF.size():
		out.append(LEAF[i].lerp(FALL_WILD[i], t))
	return out
