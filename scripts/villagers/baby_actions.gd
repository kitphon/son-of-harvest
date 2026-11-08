class_name BabyActions
extends RefCounted
## The farmer and the baby in the bamboo cradle of the second room (Child, the cradle prop in
## data/maps/house.json; docs/DESIGN.md, ลูก). With the hands free, E on the cradle looks in
## (a line by the clock, Child.cradle_line) and the tool button lifts the baby out into the
## hold pose. While the baby is held either button facing the cradle lays them back; the baby
## is never thrown or set down anywhere else, and a door waits until the baby is back (the
## baby stays in the farmhouse). Map changes and the night put the baby back as well (Game).


## E on cell `c` with the hands free: the cradle's line. True when the cradle was there.
static func look_in(c: Vector2i) -> bool:
	if not Game.is_cradle(c):
		return false
	Game.message.emit(Child.cradle_line(Game.flags, int(Game.day_minutes())))
	return true


## The tool button on cell `c` with the hands free: lifts the baby. True when the cradle was there.
static func lift(c: Vector2i) -> bool:
	if not Game.is_cradle(c) or Game.holding():
		return false
	if Game.lift_baby():
		Sfx.play("pick")
		Game.message.emit("You lift %s from the cradle." % Child.child_name(Game.flags))
	return true


## A button while the baby is held, facing cell `c` ("enter" = walking into a door).
static func held_action(kind: String, c: Vector2i) -> void:
	var name := Child.child_name(Game.flags)
	if kind == "enter":
		Game.message.emit("Lay %s back in the cradle first." % name)
	elif Game.is_cradle(c):
		Game.lay_baby()
		Sfx.play("hold_land")
		Game.message.emit("You lay %s back in the cradle." % name)
	else:
		Game.message.emit("Your hands are full.")
