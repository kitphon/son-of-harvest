class_name DogActions
extends RefCounted
## The farmer and the farm dog: E facing it pets it (once a day counts), E again picks it up
## overhead; while it is held either button sets it down in front, and doors wait until it
## is down (the dog stays on the farm). Rules and numbers in Animals / data/animals.json.


## E on farm cell `c` with the hands free. True when the dog was there. Only one thing goes in
## the arms: with the baby, the crawler or an item overhead nothing happens (no pat, no pick-up).
static func interact(c: Vector2i) -> bool:
	var a := Game.animals
	if Game.holding():
		return false
	if not Game.maps.on_farm() or a.dog.held or a.dog.cell != c:
		return false
	Sfx.play("dog_bark")
	if a.dog_pet():
		Game.message.emit(Lang.join([mood() % a.dog.name, a.age_text(a.dog)]))
	else:
		a.dog_lift()
		Game.message.emit("You picked %s up." % a.dog.name)
		Game.changed.emit()
	return true


## A button while the dog is held: down on `c` in front when it is free ("enter" = walking
## into a door: not with the dog in the arms).
static func held_action(kind: String, c: Vector2i) -> void:
	var a := Game.animals
	if kind == "enter":
		Game.message.emit("Put %s down first." % a.dog.name)
	elif Game.farm.in_bounds(c) and not Game.farm.is_solid(c):
		a.dog_put(c)
		Sfx.play("hold_land")
		Game.changed.emit()
	else:
		Game.message.emit("No room to put %s down." % a.dog.name)


static func mood() -> String:
	var a := Game.animals
	var p := float(a.dog.affection) / maxi(int(a.dog_rule().get("max", 100)), 1)
	if p < 0.2:
		return "%s sniffs your hand."
	if p < 0.6:
		return "%s wags its tail."
	return "%s jumps up, wagging all over."
