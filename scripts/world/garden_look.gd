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
const LEAF: Array[Color] = [Color("2f5626"), Color("3f6e2e"), Color("58893a")]
const LEAF_WINTER: Array[Color] = [Color("2a4626"), Color("35582c"), Color("466a36")]
const BLOOM := Color("e690b4")
const FALL_RED := Color("a8452c")
## A wild bush's leaves at their most turned in fall [dark, mid, light]: rust and amber, reached a
## share of the way from LEAF by each bush's own turn (wild_fall_tones).
const FALL_WILD: Array[Color] = [Color("5c3a1c"), Color("8c5a28"), Color("b4823a")]


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
