class_name BarnActions
extends RefCounted
## The farmer's actions in the barn: the fodder box and the hay, the tools on the wall, the
## barn gate and the cows and sheep themselves. Glue between the keys and the Animals rules
## (like CoopActions for the coop); the numbers stay in data/animals.json.
##
## The brush, the milker and the shears hang in the barn, so E on an animal does the first
## thing that is due: milk / shear it when its product is ready (into the hands, overhead),
## else brush it, else talk to it; then it tells how the animal feels (and when a carrying
## one is due). With the musubi cord held up, E ties it on her stall instead (Animals.breed).


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
			Game.message.emit("The brush, the milker and the shears. E on an animal uses them.")
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
		Game.message.emit("Put %d fodder in the box (%d left)." % [n, st.stock])
	elif a.in_home("barn").is_empty():
		Game.message.emit("Fodder: %d left. The barn is empty." % st.stock)
	elif int(st.box) < a.in_home("barn").size():
		Game.message.emit("There is no fodder left.")
	else:
		Game.message.emit("The fodder box is full (%d left)." % st.stock)


static func use_gate() -> void:
	var a := Game.animals
	var was_out := a.is_out("barn")
	match a.toggle_out(Game.weather_today, Game.hour, "barn"):
		"":
			Sfx.play("door_slide")
			Game.message.emit("The animals came back in." if was_out else "The animals went out to graze.")
		"weather":
			Game.message.emit("It's no weather to go out.")
		"time":
			Game.message.emit("It's too late to go out.")
		_:
			Game.message.emit("There are no animals in the barn.")


## A cow or a sheep: medicine when sick, else the product when ready, a brushing, a talk.
static func tend(i: int) -> void:
	var a := Game.animals
	var beast: Dictionary = a.list[i]
	var medicine := String(a.rules.get("sickness", {}).get("medicine", "medicine"))
	Sfx.play(String(a.kind_rule(beast.kind).get("voice", "hen_cluck")))
	if Game.held != "" and Game.held == a.breed_item():
		tie_cord(i)
		return
	if beast.sick:
		if Game.take_item(medicine):
			a.cure(i)
			Game.message.emit("You gave %s the medicine. %s is well again." % [beast.name, beast.name])
		else:
			Game.message.emit("%s looks sick. Animal medicine would help." % beast.name)
		return
	if a.product_ready(beast) and not Game.holding():
		var tool := String(a.gives(beast).get("tool", ""))
		var item := a.take_product(i)
		Game.held = item
		Sfx.play("shear_snip" if tool == "shears" else "milk_squirt")
		Game.message.emit(("Sheared %s: %s." if tool == "shears" else "Milked %s: %s.") % [beast.name, Game.item_name(item)])
		Game.changed.emit()
	elif a.brush(i):
		Sfx.play("brush_stroke")
		Game.message.emit(Lang.join(["You brushed %s." % a.label(beast), mood(beast, a.happy_max()) % a.label(beast), due_note(beast)]))
	elif a.pet(i):
		Game.message.emit(Lang.join([mood(beast, a.happy_max()) % a.label(beast), due_note(beast)]))
	elif a.product_ready(beast):
		Game.message.emit("Your hands are full.")
	else:
		Game.message.emit(Lang.join([mood(beast, a.happy_max()) % a.label(beast), due_note(beast)]))


## The musubi cord held up, tied on animal `i`'s stall: she carries from tonight and the cord
## is used up; else why she can't, and the cord stays in the hands.
static func tie_cord(i: int) -> void:
	var a := Game.animals
	var beast: Dictionary = a.list[i]
	match a.breed(i):
		"":
			Game.held = ""
			Game.changed.emit()
			Sfx.play("pick")
			Game.message.emit(Lang.join(["You tied the musubi cord on %s's stall." % beast.name, due_note(beast)]))
		"young":
			Game.message.emit("%s is too young to carry." % beast.name)
		"sick":
			Game.message.emit("%s should get well first." % beast.name)
		"carrying":
			Game.message.emit(due_note(beast))
		"unhappy":
			Game.message.emit("%s isn't happy enough to carry yet." % beast.name)
		_:
			Game.message.emit("The cord is for a cow or a ewe.")


## When a carrying animal is due ("" when she isn't carrying).
static func due_note(beast: Dictionary) -> String:
	match Game.animals.due_in(beast):
		-1:
			return ""
		0:
			return "%s is due and waits for room in the barn." % beast.name
		1:
			return "%s is due tomorrow." % beast.name
		var n:
			return "%s is due in %d nights." % [beast.name, n]


static func mood(beast: Dictionary, most: int) -> String:
	var p := float(beast.happy) / most
	if p < 0.2:
		return "%s looks unhappy"
	if p < 0.6:
		return "%s seems content"
	return "%s looks very happy"
