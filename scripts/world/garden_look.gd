class_name GardenLook
extends RefCounted
## What the temple garden's pond-side pieces look like, shared by both views (GardenProps builds
## them in 3D, MapView._draw_garden draws them flat): the kinds, the rock shapes, the colours and
## when the shrubs flower. Pure (no world classes), so the flat view loads without the 3D ones.

const KINDS: Array[String] = ["garden_rock", "shrub"]
const SHAPES: Array[String] = ["tall", "flat", "low", "pair"]
const STONE: Array[Color] = [Color("4e4c47"), Color("6a675f"), Color("85817a")]
const MOSS := Color("5f7a3a")
const LEAF: Array[Color] = [Color("2f5626"), Color("3f6e2e"), Color("58893a")]
const LEAF_WINTER: Array[Color] = [Color("2a4626"), Color("35582c"), Color("466a36")]
const BLOOM := Color("e690b4")
const FALL_RED := Color("a8452c")


## Whether a shrub flowers on day `day` of `season` (the azalea: late spring into early summer).
static func blooms(season: String, day: int) -> bool:
	return (season == "spring" and day >= 16) or (season == "summer" and day <= 6)
