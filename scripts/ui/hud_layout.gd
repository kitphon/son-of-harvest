class_name HudLayout
extends RefCounted
## Where the HUD boxes sit and what the tools are called. Kept apart from Hud (which reads
## the Game autoload) so headless tests can check it.

## Boxes in viewport pixels (480 x 270). The message box keeps its corner and grows with
## its text.
const BOXES := {
	"clock": Rect2i(384, 4, 92, 42),
	"festival": Rect2i(384, 48, 92, 17),   # today's festival, only on a festival day
	"item": Rect2i(4, 214, 168, 21),
	"tools": Rect2i(4, 238, 168, 28),
	"hand": Rect2i(176, 238, 28, 28),    # the item in the other hand, only while there is one
	"status": Rect2i(384, 226, 92, 40),
	"message": Rect2i(4, 4, 0, 19),
}
const SLOT := 18
const SLOT_GAP := 2
const TOOL_NAMES := {"hoe": "Hoe", "can": "Watering can", "sickle": "Sickle",
	"hammer": "Hammer", "axe": "Axe", "seeds": "Seeds", "food": "Food", "rod": "Fishing rod"}
const WEATHER_ICONS: Array[String] = ["sunny", "rain", "storm", "snow", "blizzard"]


## Icon kind for a weather look (Game.weather_look), sunny for anything without an icon.
static func weather_icon(look: String) -> String:
	return look if look in WEATHER_ICONS else "sunny"
