class_name CoopActions
extends RefCounted
## The farmer's actions in the chicken coop: the feed box, the nests, the incubator, the
## hatch and the hens themselves. Glue between the keys and the Animals rules (like
## FarmActions for the field); the rules and numbers stay in Animals / data/animals.json.


## The coop's map id (data/animals.json homes.coop.map).
static func map_id() -> String:
	return String(Game.animals.home_rule("coop").get("map", "coop"))


static func in_coop() -> bool:
	return Game.maps.id == map_id()


## Interact on cell `c` of the coop. True when something there took it.
static func interact(c: Vector2i) -> bool:
	if not in_coop():
		return false
	var i := animal_at(c)
	if i >= 0:
		tend(i)
		return true
	match str(Game.maps.current().prop_at(c).get("use", "")):
		"feed_box":
			fill_feed_box()
		"feed_sack":
			Game.message.emit("Chicken feed: %d left in the sack" % Game.animals.feed_stock)
		"nest":
			collect_egg()
		"incubator":
			use_incubator()
		"hatch":
			use_hatch()
		_:
			return false
	return true


## Where animal `i` stands in the coop (homes.coop.spots), or (-1, -1) (also for barn animals).
static func spot(i: int) -> Vector2i:
	var a := Game.animals
	if i < 0 or i >= a.list.size() or a.home_of(a.list[i]) != "coop":
		return Vector2i(-1, -1)
	return a.spot(i)


## The animal standing on `c` inside the coop (none while they are out), else -1.
static func animal_at(c: Vector2i) -> int:
	return Game.animals.animal_at("coop", c)


static func fill_feed_box() -> void:
	var a := Game.animals
	var n := a.fill_feed_box()
	if n > 0:
		Sfx.play("feed_pour")
		Game.message.emit("Put %d feed in the box (%d left)" % [n, a.feed_stock])
	elif a.feed_box < a.in_home("coop").size():
		Game.message.emit("The feed sack is empty")
	else:
		Game.message.emit("The feed box is full")


static func collect_egg() -> void:
	if Game.animals.eggs.is_empty():
		Game.message.emit("No eggs in the nests")
	elif Game.holding():
		Game.message.emit("Your hands are full")
	else:
		var egg := Game.animals.take_egg()
		Game.held = egg
		Sfx.play("pick")
		Game.message.emit("Picked up a %s" % Game.item_name(egg))
		Game.changed.emit()


## With an egg overhead: into the incubator. Otherwise it tells how the egg is doing.
static func use_incubator() -> void:
	var a := Game.animals
	var days := int(a.rules.get("incubator", {}).get("hatch_days", 3))
	if a.incubator.size() > 0:
		Game.message.emit("An egg is warming (%d days to go)" % (days - int(a.incubator.days)))
	elif not a.is_egg(Game.held):
		Game.message.emit("Put an egg in to hatch a chick")
	elif a.room("coop") <= 0:
		Game.message.emit("The coop is full")
	elif a.incubate(Game.held):
		Game.inventory.take(Game.held, 1, ["hand"])
		Sfx.play("hold_land")
		Game.message.emit("The egg is in the incubator (%d days)" % days)
		Game.changed.emit()


static func use_hatch() -> void:
	var a := Game.animals
	var was_out := a.outside
	match a.toggle_out(Game.weather_today, Game.hour):
		"":
			Sfx.play("door_slide")
			Game.message.emit("The hens came back in" if was_out else "The hens went out to the yard")
		"weather":
			Game.message.emit("It's no weather for the hens to go out")
		"time":
			Game.message.emit("It's too late for the hens to go out")
		_:
			Game.message.emit("There are no hens to let out")


## A hen: medicine if she is sick and there is some, else a stroke (once a day counts).
static func tend(i: int) -> void:
	var a := Game.animals
	var hen: Dictionary = a.list[i]
	var medicine := String(a.rules.get("sickness", {}).get("medicine", "medicine"))
	Sfx.play("hen_cluck")
	if hen.sick:
		if Game.take_item(medicine):
			a.cure(i)
			Game.message.emit("You gave %s the medicine. She's well again" % hen.name)
		else:
			Game.message.emit("%s looks sick. Animal medicine would help" % hen.name)
		return
	a.pet(i)
	Game.message.emit("%s %s" % [a.label(hen), mood(hen, a.happy_max())])


static func mood(hen: Dictionary, most: int) -> String:
	var p := float(hen.happy) / most
	if p < 0.2:
		return "looks unhappy"
	if p < 0.6:
		return "clucks softly"
	return "looks very happy"
