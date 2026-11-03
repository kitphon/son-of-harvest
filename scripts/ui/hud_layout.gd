class_name HudLayout
extends RefCounted
## Where the HUD boxes sit and what the tools are called. Kept apart from Hud (which reads
## the Game autoload) so headless tests can check it.

## Boxes in viewport pixels (480 x 270). The message box keeps its corner and grows with
## its text.
const BOXES := {
	"clock": Rect2i(384, 4, 92, 42),
	"festival": Rect2i(384, 48, 92, 17),   # today's festival, or a villager's birthday; hidden on other days
	"item": Rect2i(4, 214, 168, 21),
	"tools": Rect2i(4, 238, 168, 28),
	"hand": Rect2i(176, 238, 28, 28),    # the item in the other hand, only while there is one
	"status": Rect2i(384, 226, 92, 40),
	"message": Rect2i(4, 4, 0, 19),
	"hint": Rect2i(4, 196, 168, 16),   # what E / Space do now (ActionHints); grows with its text, hidden when empty
}
## Boxes that grow together with the UI size setting (UiScale), one group per corner, so the
## boxes in a corner keep their gaps.
const GROUPS := {"clock": "top_right", "festival": "top_right", "item": "bottom_left",
	"tools": "bottom_left", "hand": "bottom_left", "hint": "bottom_left", "status": "bottom_right", "message": "top_left"}
const SCREEN := Vector2(480, 270)
const SLOT := 18
const SLOT_GAP := 2
const TOOL_NAMES := {"hoe": "Hoe", "can": "Watering can", "sickle": "Sickle",
	"hammer": "Hammer", "axe": "Axe", "seeds": "Seeds", "food": "Food", "rod": "Fishing rod"}
const WEATHER_ICONS: Array[String] = ["sunny", "rain", "storm", "snow", "blizzard"]


## Icon kind for a weather look (Game.weather_look), sunny for anything without an icon.
static func weather_icon(look: String) -> String:
	return look if look in WEATHER_ICONS else "sunny"


## The tag under the clock for a day with birthdays `ids` (Game.birthdays_today):
## "Tome's birthday", "" for none.
static func day_tag(ids: Array[String]) -> String:
	if ids.is_empty():
		return ""
	return "%s's birthday" % Villagers.all()[ids[0]].name


## A corner group's boxes as one rect (UiScale grows it about its pivot).
static func group_rect(group: String) -> Rect2:
	var out := Rect2()
	var first := true
	for key in GROUPS:
		if GROUPS[key] == group:
			out = Rect2(BOXES[key]) if first else out.merge(Rect2(BOXES[key]))
			first = false
	return out


## Where box `key` sits (its rect, in viewport pixels) at UI size `wanted`: its group grown
## as far as the group still fits on the screen.
static func scaled_box(key: String, wanted: float) -> Rect2:
	var g := group_rect(GROUPS[key])
	var s := group_scale(key, wanted)
	var r := Rect2(BOXES[key])
	return Rect2(UiScale.offset(g, s, SCREEN) + r.position * s, r.size * s)


## The scale box `key`'s group gets at UI size `wanted`.
static func group_scale(key: String, wanted: float) -> float:
	return UiScale.fit(wanted, group_rect(GROUPS[key]).size, SCREEN)
