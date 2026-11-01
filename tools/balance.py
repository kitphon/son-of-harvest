"""Income per season for a steady first-year player (the balance pass, milestone 8).

Reads the data files and plays a simple, steady year 1: a few bags of seeds that grow as the
tools do, the starting hens plus a few bought ones, a cow / sheep once the store sells them,
some fishing on rainy days and evenings, a mine trip now and then (most in winter), and from
summer (the kitchen) a few dishes cooked and shipped. Prints income per source and running
costs per season, then the season goals (rucksacks, house extensions, tool upgrades) and the
money left after buying them in order. A tool upgrade also needs the smithy's ores: they come
out of the mine finds (kept back instead of shipped, so the mine column is what reached the
bin), and an upgrade waits while the ores are short. Festival contests: the odds of each place
for the plan's best entry against the rivals' rolls (data/festivals.json), and the prize money
expected. Last, every recipe's gain over its ingredients shipped raw, per season, with the
kitchen tools it needs and how many cookings pay them back. The plan buys a kitchen tool (a
one-off cost, column "tools") in the first season it cooks a recipe that needs it.

Not a game rule: the plan below is our guess at how a calm player spends year 1. Run it before
and after changing prices to compare (WORKLOG has the tables).

    python -I tools/balance.py            (from the project folder)
"""
import functools
import json
import os
import random
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEASONS = ["spring", "summer", "fall", "winter"]
DAYS = 30

# --- the steady player's plan (ours, not data) ---------------------------------------------
# Seed bags (3 x 3 cells) kept planted, by season; the field grows as the can and hoe level up.
BAGS = {"spring": 5, "summer": 8, "fall": 10, "winter": 0}
# Crop mix per season: share of the bags given to each crop (regrowers stay all season).
MIX = {
    "spring": {"turnip": 0.4, "potato": 0.4, "cucumber": 0.2},
    "summer": {"tomato": 0.3, "onion": 0.3, "corn": 0.25, "rice": 0.15},
    "fall": {"carrot": 0.3, "eggplant": 0.25, "pumpkin": 0.25, "daikon": 0.2},
}
# Dishes cooked and shipped per season once the kitchen stands (bought in summer): recipe ->
# times cooked. The ingredients come out of the season's own harvest, eggs, milk and fish, so
# the "cook" column is what the dishes fetch over shipping those ingredients raw.
COOKED = {
    "summer": {"tamagoyaki": 10, "milk_pudding": 5},
    "fall": {"tamagoyaki": 10, "furofuki_daikon": 10, "takikomi_gohan": 5, "kinako_mochi": 5, "simmered_pumpkin": 5},
    "winter": {"tamagoyaki": 15, "milk_pudding": 10, "grilled_fish": 10},
}
# Hens bought from the store: (season, day, how many). The coop holds 6.
HENS_BOUGHT = [("spring", 20, 2), ("summer", 10, 2)]
# Cows / sheep bought (grown) once the store sells them: (season, day, kind).
BARN_BOUGHT = [("summer", 15, "cow"), ("fall", 10, "sheep"), ("fall", 25, "cow")]
GRADE_SHARE = [0.25, 0.55, 0.20]  # products by grade: low / middle / top happiness
GRAZE_SHARE = 0.4                 # days the animals graze outside (no feed eaten)
MEDICINE_PER_SEASON = 1
FISH_DAYS = {"spring": 8, "summer": 8, "fall": 8, "winter": 16}   # days with an hour or two at the pond
FISH_PER_DAY = 6
MINE_TRIPS = {"spring": 2, "summer": 3, "fall": 3, "winter": 12}
MINE_FLOORS = {"spring": 3, "summer": 5, "fall": 7, "winter": 10}  # a trip goes from floor 1 down to this
MINE_TAKEN = 0.4                  # share of rocks and soft spots broken on the way to the hole
FOOD_PER_DAY = 60                 # G of snacks on working days (stamina for the bigger field)
# Season goals bought as soon as the money is there, in this order.
GOALS = [
    ("spring", "rucksack 1"), ("spring", "chest"), ("spring", "upgrade can 2"), ("spring", "upgrade hoe 2"),
    ("summer", "kitchen"), ("summer", "upgrade sickle 2"), ("summer", "upgrade can 3"),
    ("fall", "rucksack 2"), ("fall", "room"),
    ("winter", "upgrade hoe 3"), ("winter", "upgrade can 4"), ("winter", "upgrade hammer 2"),
]


CONTEST_ROLLS = 2000              # Monte Carlo rolls per contest (fixed seed, same every run)


def load(name):
    with open(os.path.join(ROOT, "data", name), encoding="utf-8") as f:
        return json.load(f)


crops = load("crops.json")
animals = load("animals.json")
fish = load("fish.json")
mine = load("mine.json")
shops = load("shops.json")
foods = load("foods.json")
recipes = load("recipes.json")
forage = load("forage.json")
festivals = load("festivals.json")["festivals"]
store = shops["shops"]["general"]
smithy = shops["shops"]["smithy"]


def stock_price(item):
    """Price of a store entry by item id, None when the store doesn't sell it."""
    for entries in store["stock"].values():
        for e in entries:
            if e["item"] == item:
                if "price" in e:
                    return e["price"]
                if item.startswith("seeds:"):
                    return crops[item[6:]]["seed_price"]
    return None


def grow_days(crop):
    return sum(crop["stage_days"])


def regrow_days(crop):
    r = crop.get("regrow_stage", -1)
    return sum(crop["stage_days"][r:]) if r >= 0 else None


def crop_season(season):
    """Seeds bought and crops shipped by BAGS[season] plots of MIX: a plot is replanted the
    day it is harvested (regrowers keep going), only while the crop can still ripen."""
    seeds = ship = 0
    for cid, share in MIX.get(season, {}).items():
        c = crops[cid]
        plots = BAGS[season] * share
        day = 1
        while day + grow_days(c) <= DAYS:
            seeds += plots * c["seed_price"]
            day += grow_days(c)
            ship += plots * 9 * c["sell"]
            again = regrow_days(c)
            if again:
                while day + again <= DAYS:
                    day += again
                    ship += plots * 9 * c["sell"]
                break
    return seeds, ship


def product_value(product):
    grades = animals["products"][product]["grades"]
    return sum(GRADE_SHARE[i] * animals["items"][g["item"]]["sell"] for i, g in enumerate(grades))


def fish_value(season):
    """Average G per catch at the village pond in the morning and evening of a sunny day."""
    total = 0.0
    for hour in (7, 17):
        w = fish_weights(season, hour)
        total += sum(fish["fish"][k]["sell"] * v for k, v in w.items()) / sum(w.values())
    return total / 2


def fish_weights(season, hour):
    """{fish id: weight} at the village pond at `hour` on a sunny day (once-only fish left out)."""
    w = {}
    for fid, f in fish["fish"].items():
        if f.get("once") or "town" not in f["places"] or season not in f.get("seasons", SEASONS):
            continue
        h = f.get("hours")
        if h and not ((h[0] <= hour < h[1]) if h[0] < h[1] else (hour >= h[0] or hour < h[1])):
            continue
        w[fid] = f["places"]["town"]
    return w


def mine_floor_finds(depth, season):
    """Expected finds {item: count} of one floor at `depth`, breaking MINE_TAKEN of its rocks
    and soft spots, with the season's factors."""
    band = [b for b in mine["floors"] if b["from"] <= depth][-1]
    factors = mine["seasons"].get(season, {})
    counts = {}
    for source, count_key in (("rock", "rocks"), ("big_rock", "big_rocks"), ("soft", "soft")):
        weights = {k: v * factors.get(k, 1.0) for k, v in band["finds"][source].items()}
        lo, hi = band[count_key]
        broken = (lo + hi) / 2 * MINE_TAKEN
        for k, v in weights.items():
            if k != "none":
                counts[k] = counts.get(k, 0.0) + broken * v / sum(weights.values())
    return counts


def mine_season_finds(season):
    """Expected finds of the season's mine trips, floor 1 down to MINE_FLOORS[season]."""
    total = {}
    for d in range(1, MINE_FLOORS[season] + 1):
        for k, n in mine_floor_finds(d, season).items():
            total[k] = total.get(k, 0.0) + n * MINE_TRIPS[season]
    return total


def mine_floor_value(depth, season):
    return sum(mine["items"][k]["sell"] * n for k, n in mine_floor_finds(depth, season).items())


def need_value(need, season):
    """Shipping value of one need of a recipe: a group uses its cheapest item (eggs and milk at
    their average grade, fish at the season's average catch)."""
    if "group" in need:
        g = recipes["groups"][need["group"]]
        if g.get("prefix") == "fish:":
            each = fish_value(season)
        elif need["group"] in ("egg", "milk"):
            each = product_value(need["group"])
        else:
            each = min(item_value(i) for i in g["items"])
    elif need["item"].startswith("food:"):
        each = foods["foods"][need["item"][5:]]["price"]
    else:
        each = item_value(need["item"])
    return each * need["n"]


def item_value(item):
    """Shipping value of one crop, animal product or wild thing (wild:<id>, data/forage.json)."""
    if item.startswith("wild:"):
        return forage["items"][item[5:]]["sell"]
    if item in crops:
        return crops[item]["sell"]
    return animals["items"][item]["sell"]


def kitchen_tools_bought():
    """{season: G} the plan spends on kitchen tools: each one the first season COOKED needs it."""
    owned, out = set(), {}
    for s in SEASONS:
        new = {t for rid in COOKED.get(s, {}) for t in recipes["recipes"][rid].get("tools", [])} - owned
        out[s] = sum(recipes["tools"][t]["price"] for t in new)
        owned |= new
    return out


def cook_season(season):
    """G the season's dishes fetch over their ingredients shipped raw."""
    gain = 0.0
    for rid, times in COOKED.get(season, {}).items():
        r = recipes["recipes"][rid]
        dish = foods["foods"][rid]["sell"] * r.get("makes", 1)
        gain += times * (dish - sum(need_value(n, season) for n in r["needs"]))
    return gain


def pick(rng, weights):
    """One key of {key: weight} drawn at random."""
    x = rng.random() * sum(weights.values())
    for k, w in weights.items():
        x -= w
        if x < 0:
            return k
    return k


def contest_entry(fid, rng):
    """The score of the plan's best entry for festival `fid`'s contest, one roll."""
    f = festivals[fid]
    c = f["contest"]
    season, day = f["season"], f["day"]
    if c["takes"] == "crop":
        # The best crop of the season's mix ripe by the festival day (in season).
        ripe = [cid for cid in MIX.get(season, {}) if 1 + grow_days(crops[cid]) <= day]
        return max(int(crops[cid]["sell"] * c.get("in_season", 1.0)) for cid in ripe) if ripe else 0
    if c["takes"] == "fish":
        # The best of the season's catches so far, mornings and evenings.
        catches = round(FISH_DAYS[season] * FISH_PER_DAY * day / DAYS)
        return max(fish["fish"][pick(rng, fish_weights(season, (7, 17)[n % 2]))]["sell"] for n in range(catches))
    if c["takes"] == "animal":
        # The best product of the festival morning: an egg a hen and milk a cow, a grade roll each.
        when = (SEASONS.index(season), day)
        hens = len([a for a in animals["start"] if a == "chicken"])
        hens += sum(n for (bs, bd, n) in HENS_BOUGHT if (SEASONS.index(bs), bd) <= when)
        hens = min(hens, animals["homes"]["coop"]["capacity"])
        cows = len([1 for (bs, bd, k) in BARN_BOUGHT if k == "cow" and (SEASONS.index(bs), bd) < when])
        best = 0
        for product, n in (("egg", hens), ("milk", cows)):
            grades = animals["products"][product]["grades"]
            for _ in range(n):
                g = pick(rng, dict(enumerate(GRADE_SHARE)))
                best = max(best, animals["items"][grades[g]["item"]]["sell"])
        return best
    if c["takes"] == "mine":
        # The best find of the season's trips, every rock and soft spot broken drawn from its table.
        best = 0
        factors = mine["seasons"].get(season, {})
        for _ in range(MINE_TRIPS[season]):
            for d in range(1, MINE_FLOORS[season] + 1):
                band = [b for b in mine["floors"] if b["from"] <= d][-1]
                for source, key in (("rock", "rocks"), ("big_rock", "big_rocks"), ("soft", "soft")):
                    weights = {k: v * factors.get(k, 1.0) for k, v in band["finds"][source].items()}
                    for _ in range(round(rng.randint(*band[key]) * MINE_TAKEN)):
                        k = pick(rng, weights)
                        if k != "none":
                            best = max(best, mine["items"][k]["sell"])
        return best
    return 0


@functools.cache
def contest_odds(fid):
    """{place: share of rolls} for the plan's entry at festival `fid` (the farmer wins ties)."""
    rng = random.Random(fid)
    places = {}
    for _ in range(CONTEST_ROLLS):
        score = contest_entry(fid, rng)
        place = 1 + sum(1 for r in festivals[fid]["contest"]["rivals"] if rng.randint(*r["score"]) > score)
        places[place] = places.get(place, 0) + 1
    return {p: n / CONTEST_ROLLS for p, n in sorted(places.items())}


def contest_prize(fid):
    """Prize money expected at festival `fid` (prize items, festival food, are left out)."""
    prizes = festivals[fid]["contest"]["prizes"]
    return sum(share * prizes[p - 1]["money"] for p, share in contest_odds(fid).items() if p <= len(prizes))


def main():
    hens = len([a for a in animals["start"] if a == "chicken"])
    cows = sheep = 0
    chicken_price = stock_price("animal:chicken")
    feed_price = stock_price("feed") or 0
    fodder_price = stock_price("fodder")
    sells_barn = stock_price("animal:cow") is not None and fodder_price is not None
    rows = {}
    kitchen = kitchen_tools_bought()
    for s in SEASONS:
        r = {"crops": 0, "cook": 0, "eggs": 0, "milk": 0, "wool": 0, "fish": 0, "mine": 0, "prize": 0,
             "seeds": 0, "feed": 0, "animals": 0, "medicine": 0, "food": 0, "tools": 0}
        r["seeds"], r["crops"] = crop_season(s)
        r["cook"] = cook_season(s)
        r["tools"] = kitchen[s]
        for day in range(1, DAYS + 1):
            for (bs, bd, n) in HENS_BOUGHT:
                if (bs, bd) == (s, day) and chicken_price:
                    hens = min(hens + n, animals["homes"]["coop"]["capacity"])
                    r["animals"] += n * chicken_price
            for (bs, bd, kind) in BARN_BOUGHT:
                if (bs, bd) == (s, day) and sells_barn:
                    cows += kind == "cow"
                    sheep += kind == "sheep"
                    r["animals"] += stock_price("animal:" + kind)
            graze = GRAZE_SHARE if s != "winter" else 0.0
            r["eggs"] += hens * product_value("egg")
            r["milk"] += cows * product_value("milk")
            r["wool"] += sheep * product_value("wool") / animals["kinds"]["sheep"]["gives"]["every"]
            r["feed"] += hens * (1 - graze) * feed_price + (cows + sheep) * (1 - graze) * (fodder_price or 0)
        r["fish"] = FISH_DAYS[s] * FISH_PER_DAY * fish_value(s)
        r["finds"] = mine_season_finds(s)
        r["mine"] = MINE_TRIPS[s] * sum(mine_floor_value(d, s) for d in range(1, MINE_FLOORS[s] + 1))
        r["prize"] = sum(contest_prize(fid) for fid, f in festivals.items() if f["season"] == s and "contest" in f)
        r["medicine"] = MEDICINE_PER_SEASON * stock_price("medicine")
        r["food"] = FOOD_PER_DAY * (DAYS if s != "winter" else DAYS // 2)
        rows[s] = r

    # Goals are bought in order as soon as the money (and an upgrade's ores) are there. The ores
    # an upgrade takes are kept back from the mine finds, so they never reach the bin.
    money = 500
    ores = {}
    goals = list(GOALS)
    for s in SEASONS:
        r = rows[s]
        for k, n in r["finds"].items():
            ores[k] = ores.get(k, 0.0) + n
        money += season_net(r)
        kept = 0.0
        bought = []
        short = ""
        while goals and SEASONS.index(goals[0][0]) <= SEASONS.index(s):
            cost = goal_cost(goals[0][1])
            items = goal_items(goals[0][1])
            if cost is None or cost > money:
                break
            lack = [k for k, n in items.items() if ores.get(k, 0.0) < n]
            if lack:
                short = f"{goals[0][1]} waits for {', '.join(lack)}"
                break
            for k, n in items.items():
                ores[k] -= n
                kept += n * mine["items"][k]["sell"]
            money -= cost
            bought.append(f"{goals.pop(0)[1]} ({cost})")
        r["mine"] -= kept
        r["kept"] = kept
        money -= kept
        r["goals"] = (bought, money, short)

    print("Income and running costs per season (G), steady year-1 plan")
    head = ["season", "crops", "cook", "eggs", "milk", "wool", "fish", "mine", "prize", "income", "seeds", "feed", "animals", "tools", "other", "net"]
    print(" | ".join(f"{h:>7}" for h in head))
    year = 0
    for s in SEASONS:
        r = rows[s]
        year += season_net(r)
        cells = [s, r["crops"], r["cook"], r["eggs"], r["milk"], r["wool"], r["fish"], r["mine"], r["prize"],
                 sum(r[k] for k in INCOME), r["seeds"], r["feed"], r["animals"], r["tools"], r["medicine"] + r["food"], season_net(r)]
        print(" | ".join(f"{c:>7}" if isinstance(c, str) else f"{round(c):>7}" for c in cells))
    print(f"year net {round(year)} G (mine: finds shipped, less the ores kept for the smithy;"
          " tools: kitchen tools, once)")
    print()
    for s in SEASONS:
        bought, left, short = rows[s]["goals"]
        note = f"; ores kept {round(rows[s]['kept'])} G" if rows[s]["kept"] else ""
        note += f"; {short}" if short else ""
        print(f"{s:>7}: bought {', '.join(bought) or 'nothing'}; {round(left)} G left{note}")
    if goals:
        print(f"   late: {', '.join(g[1] for g in goals)}")
    print("   ores left: " + ", ".join(f"{k} {n:.1f}" for k, n in ores.items() if mine["items"][k]["kind"] == "ore"))
    if not sells_barn:
        print("(the store sells no cows / sheep / fodder: no milk or wool)")

    print()
    print("Festival contests: the plan's entry, odds of 1st / 2nd / 3rd / no place, prize money expected")
    wins = 0.0
    for fid, f in festivals.items():
        if "contest" not in f:
            continue
        odds = contest_odds(fid)
        wins += odds.get(1, 0.0)
        cells = " / ".join(f"{round(100 * odds.get(p, 0.0)):>3}%" for p in (1, 2, 3, 4))
        print(f"{fid:>14} ({f['contest']['takes']:>6}): {cells}; {round(contest_prize(fid))} G")
    print(f"   wins expected a year: {wins:.1f}")

    print()
    print("Recipes: G one cooking fetches over its ingredients shipped raw (dish sell x makes - ingredients);")
    print("   tools: G of the kitchen tools it needs (shared tools counted in full); pays: cookings at its")
    print("   best season's gain to earn them back")
    print(f"{'recipe':>17} | " + " | ".join(f"{s:>6}" for s in SEASONS) + f" | {'tools':>6} | {'pays':>5}")
    for rid, rec in recipes["recipes"].items():
        dish = foods["foods"][rid]["sell"] * rec.get("makes", 1)
        cells = [round(dish - sum(need_value(n, s) for n in rec["needs"])) for s in SEASONS]
        tools = sum(recipes["tools"][t]["price"] for t in rec.get("tools", []))
        best = max(cells)
        pays = "-" if tools == 0 else (f"{-(-tools // best):>5}" if best > 0 else "never")
        print(f"{rid:>17} | " + " | ".join(f"{c:>6}" for c in cells) + f" | {tools:>6} | {pays:>5}")


INCOME = ("crops", "cook", "eggs", "milk", "wool", "fish", "mine", "prize")


def season_net(r):
    return sum(r[k] for k in INCOME) - r["seeds"] - r["feed"] - r["animals"] - r["tools"] - r["medicine"] - r["food"]


def goal_items(goal):
    """{mine item id: count} a goal takes from the smithy (only upgrades take any)."""
    kind, *rest = goal.split()
    if kind != "upgrade":
        return {}
    tool, level = rest
    levels = smithy["upgrades"]["tool_levels"].get(tool, smithy["upgrades"]["levels"])
    return {k.removeprefix("mine:"): n for k, n in levels[level].get("items", {}).items()}


def goal_cost(goal):
    kind, *rest = goal.split()
    if kind == "rucksack":
        return store["rucksack"]["levels"][int(rest[0]) - 1]["price"]
    if kind == "upgrade":
        tool, level = rest
        levels = smithy["upgrades"]["tool_levels"].get(tool, smithy["upgrades"]["levels"])
        return levels[level]["price"]
    return store["builds"]["jobs"][kind]["price"]


if __name__ == "__main__":
    sys.exit(main())
