class_name BarnActions
extends RefCounted
## The farmer's actions in the barn: the fodder box and the hay, the tools on the wall, the
## barn gate and the cows and sheep themselves. Glue between the keys and the Animals rules
## (like CoopActions for the coop); the numbers stay in data/animals.json.
##
## The brush, the milker and the shears hang in the barn, so E on an animal does the first
## thing that is due: milk / shear it when its product is ready (into the hands, overhead),
## else brush it, else talk to it; then it tells how the animal feels.


## The barn's map id (data/animals.json homes.barn.map).
static func map_id() -> String:
	return String(Game.animals.home_rule("barn").get("map", "barn"))


static func in_barn() -> bool:
	return Game.maps.id == map_id()


## Interact on cell `c` of the barn. True when something there took it.
static func interact(c: Vector2i) -> bool:
	if not in_barn():
		return false
	var i := Game.animals.animal_at("barn", c)
	if i >= 0:
		tend(i)
		return true
	match str(Game.maps.current().prop_at(c).get("use", "")):
		"fodder_box", "fodder":
			fill_fodder_box()
		"barn_tools":
			Game.message.emit("The brush, the milker and the shears. E on an animal uses them")
		"barn_gate":
			use_gate()
		_:
			return false
	return true


static func fill_fodder_box() -> void:
	var a := Game.animals
	var n := a.fill_feed_box("barn")
	var st: Dictionary = a.state.barn
	if n > 0:
		Sfx.play("feed_pour")
		Game.message.emit("Put %d fodder in the box (%d left)" % [n, st.stock])
	elif a.in_home("barn").is_empty():
		Game.message.emit("Fodder: %d left. The barn is empty" % st.stock)
	elif int(st.box) < a.in_home("barn").size():
		Game.message.emit("There is no fodder left")
	else:
		Game.message.emit("The fodder box is full (%d left)" % st.stock)


static func use_gate() -> void:
	var a := Game.animals
	var was_out := a.is_out("barn")
	match a.toggle_out(Game.weather_today, Game.hour, "barn"):
		"":
			Sfx.play("door_slide")
			Game.message.emit("The animals came back in" if was_out else "The animals went out to graze")
		"weather":
			Game.message.emit("It's no weather to go out")
		"time":
			Game.message.emit("It's too late to go out")
		_:
			Game.message.emit("There are no animals in the barn")


## A cow or a sheep: medicine when sick, else the product when ready, a brushing, a talk.
static func tend(i: int) -> void:
	var a := Game.animals
	var beast: Dictionary = a.list[i]
	var medicine := String(a.rules.get("sickness", {}).get("medicine", "medicine"))
	Sfx.play(String(a.kind_rule(beast.kind).get("voice", "hen_cluck")))
	if beast.sick:
		if Game.take_item(medicine):
			a.cure(i)
			Game.message.emit("You gave %s the medicine. %s is well again" % [beast.name, beast.name])
		else:
			Game.message.emit("%s looks sick. Animal medicine would help" % beast.name)
		return
	if a.product_ready(beast) and not Game.holding():
		var tool := String(a.gives(beast).get("tool", ""))
		var item := a.take_product(i)
		Game.held = item
		Sfx.play("shear_snip" if tool == "shears" else "milk_squirt")
		Game.message.emit("%s %s: %s" % ["Sheared" if tool == "shears" else "Milked", beast.name, Game.item_name(item)])
		Game.changed.emit()
	elif a.brush(i):
		Sfx.play("brush_stroke")
		Game.message.emit("You brushed %s. %s" % [a.label(beast), mood(beast, a.happy_max())])
	elif a.pet(i):
		Game.message.emit("%s %s" % [a.label(beast), mood(beast, a.happy_max())])
	elif a.product_ready(beast):
		Game.message.emit("Your hands are full")
	else:
		Game.message.emit("%s %s" % [a.label(beast), mood(beast, a.happy_max())])


static func mood(beast: Dictionary, most: int) -> String:
	var p := float(beast.happy) / most
	if p < 0.2:
		return "looks unhappy"
	if p < 0.6:
		return "seems content"
	return "looks very happy"
