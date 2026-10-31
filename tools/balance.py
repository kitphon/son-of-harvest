"""Income per season for a steady first-year player (the balance pass, milestone 8).

Reads the data files and plays a simple, steady year 1: a few bags of seeds that grow as the
tools do, the starting hens plus a few bought ones, a cow / sheep once the store sells them,
some fishing on rainy days and evenings, a mine trip now and then (most in winter). Prints
income per source and running costs per season, then the season goals (rucksacks, house
extensions, tool upgrades) and the money left after buying them in order.

Not a game rule: the plan below is our guess at how a calm player spends year 1. Run it before
and after changing prices to compare (WORKLOG has the tables).

    python -I tools/balance.py            (from the project folder)
"""
import json
import os
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
    "summer": {"tomato": 0.3, "onion": 0.4, "corn": 0.3},
    "fall": {"carrot": 0.4, "eggplant": 0.3, "pumpkin": 0.3},
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


def load(name):
    with open(os.path.join(ROOT, "data", name), encoding="utf-8") as f:
        return json.load(f)


crops = load("crops.json")
animals = load("animals.json")
fish = load("fish.json")
mine = load("mine.json")
shops = load("shops.json")
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
        w = {}
        for fid, f in fish["fish"].items():
            if f.get("once") or "town" not in f["places"]:
                continue
            if season not in f.get("seasons", SEASONS):
                continue
            h = f.get("hours")
            if h and not ((h[0] <= hour < h[1]) if h[0] < h[1] else (hour >= h[0] or hour < h[1])):
                continue
            w[fid] = f["places"]["town"]
        total += sum(fish["fish"][k]["sell"] * v for k, v in w.items()) / sum(w.values())
    return total / 2


def mine_floor_value(depth, season):
    band = [b for b in mine["floors"] if b["from"] <= depth][-1]
    factors = mine["seasons"].get(season, {})
    value = 0.0
    for source, count_key in (("rock", "rocks"), ("big_rock", "big_rocks"), ("soft", "soft")):
        finds = band["finds"][source]
        weights = {k: v * factors.get(k, 1.0) for k, v in finds.items()}
        each = sum(mine["items"][k]["sell"] * v for k, v in weights.items() if k != "none") / sum(weights.values())
        lo, hi = band[count_key]
        value += each * (lo + hi) / 2 * MINE_TAKEN
    return value


def main():
    hens = len([a for a in animals["start"] if a == "chicken"])
    cows = sheep = 0
    chicken_price = stock_price("animal:chicken")
    feed_price = stock_price("feed") or 0
    fodder_price = stock_price("fodder")
    sells_barn = stock_price("animal:cow") is not None and fodder_price is not None
    rows = {}
    for s in SEASONS:
        r = {"crops": 0, "eggs": 0, "milk": 0, "wool": 0, "fish": 0, "mine": 0,
             "seeds": 0, "feed": 0, "animals": 0, "medicine": 0, "food": 0}
        r["seeds"], r["crops"] = crop_season(s)
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
        r["mine"] = MINE_TRIPS[s] * sum(mine_floor_value(d, s) for d in range(1, MINE_FLOORS[s] + 1))
        r["medicine"] = MEDICINE_PER_SEASON * stock_price("medicine")
        r["food"] = FOOD_PER_DAY * (DAYS if s != "winter" else DAYS // 2)
        rows[s] = r

    print("Income and running costs per season (G), steady year-1 plan")
    head = ["season", "crops", "eggs", "milk", "wool", "fish", "mine", "income", "seeds", "feed", "animals", "other", "net"]
    print(" | ".join(f"{h:>7}" for h in head))
    money = 500
    goals = list(GOALS)
    for s in SEASONS:
        r = rows[s]
        income = sum(r[k] for k in ("crops", "eggs", "milk", "wool", "fish", "mine"))
        other = r["medicine"] + r["food"]
        net = income - r["seeds"] - r["feed"] - r["animals"] - other
        cells = [s, r["crops"], r["eggs"], r["milk"], r["wool"], r["fish"], r["mine"], income,
                 r["seeds"], r["feed"], r["animals"], other, net]
        print(" | ".join(f"{c:>7}" if isinstance(c, str) else f"{round(c):>7}" for c in cells))
        money += net
        bought = []
        while goals and SEASONS.index(goals[0][0]) <= SEASONS.index(s):
            cost = goal_cost(goals[0][1])
            if cost is None or cost > money:
                break
            money -= cost
            bought.append(f"{goals.pop(0)[1]} ({cost})")
        rows[s]["goals"] = (bought, money)
    print()
    for s in SEASONS:
        bought, left = rows[s]["goals"]
        print(f"{s:>7}: bought {', '.join(bought) or 'nothing'}; {round(left)} G left")
    if goals:
        print(f"   late: {', '.join(g[1] for g in goals)}")
    if not sells_barn:
        print("(the store sells no cows / sheep / fodder: no milk or wool)")


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
