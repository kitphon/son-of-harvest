class_name LookMenu
extends MenuList
## The new game's look step (the title screen draws it): a row per part of the farmer's look
## (FarmerLooks.PARTS) and Start. Up / down pick a row, left / right turn through the row's
## choices, wrapping round. Looks only: nothing chosen here changes a rule.

const ITEMS: Array[String] = ["style", "hair", "skin", "clothes", "start"]
const LABELS := {"style": "Hair", "hair": "Hair color", "skin": "Skin", "clothes": "Clothes", "start": "Begin"}

var choice: Dictionary = FarmerLooks.default_choice()


func _init(from := {}) -> void:
	super(ITEMS)
	choice = FarmerLooks.normalize(from)


## Turns the row under the cursor by `step` (-1 left, +1 right); false on Start.
func turn(step: int) -> bool:
	if not current() in FarmerLooks.PARTS:
		return false
	choice = FarmerLooks.stepped(choice, current(), step)
	return true


## The name of the choice a part's row shows (data/farmer_looks.json).
func value_name(part: String) -> String:
	return str(FarmerLooks.option(choice, part).name)


## The FigureArt look of what is chosen now.
func look() -> Dictionary:
	return FarmerLooks.figure_look(choice)
