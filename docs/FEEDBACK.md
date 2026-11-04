# Harvest Son — playtest feedback

From a playtest on 2026-11-02, played as two kinds of player: 15–20 (came for the looks,
wants results fast, likes the people) and 21–30 (fans of the genre, short evening sessions,
like depth and good value). It was played from 19 screenshots (title, new game, farm, village,
house, rucksack, shop, talking to Tome, a festival, the mine, fishing, the kitchen, the barn,
the village record, the pause menu, a storm, night, snow, the mochi pounding), the opening
text, the balance numbers and the year bot's report. All 25 test scripts passed and the 19
scenes logged no errors.

When the user says "แก้ feedback" ("fix the feedback"), take the open items below one at a
time, in the order of "Order to fix": one item = one commit, then move it to "Fixed" with its
commit hash.

## Open

### 4. Winter mining beats the whole farm (21–30)
At the playtest the bot's year 1 winter had 51,214 G of 79,689 G from the mine. Since the bot
rides the lift (WORKLOG 2026-11-03) it is worse: 171,766 G of 199,601 G. Min-maxers will
only mine in winter. Tune the deep finds (or the lift's depth) in data/mine.json.
Note: at the time of writing another agent has uncommitted changes in data/mine.json and
data/festivals.json; look at what they did before tuning.

### 6. Night is too bright, no lit windows (21–30)
Night barely darkens the field, and house windows never light up.

### 7. Small things (21–30)
- The barn floor has yellow lumps that don't fit the scene.
- The title screen's text sits on the rice-field picture and is hard to read.

### 8. Not confirmed: "Saved food is broken" on the title
The title once said "The saved game can't be loaded: Saved food is broken" and greyed out
Continue. save1.json had just been rewritten (20:17) while another Godot was running; its
`food` was `milk`, a real food, so it was most likely read mid-write. Not reproduced. Try to
reproduce; if it is real, fix it, else make the load safe against a half-written file
(write to a temp file and rename).

## Order to fix
1. ~~Item 1 (Thai text): keeps the 15–20 players.~~ Fixed.
2. ~~Items 2 and 3 (week-one goal, where love leads).~~ Fixed.
3. Items 4 and 5 (mine winter income, grilled fish price).
4. Item 6 (night), then 7 and 8.

## Fixed
- Grilled fish was a shortcut (item 5): one 18 G fish made an 80 G dish. A dish now sells
  for about a third more than its cheapest ingredients (data/foods.json `_dish_prices`):
  grilled fish 25 G, ochazuke 80, fish and daikon 170, dobin mushi 135, and the same for
  plain eggs and milk (tamagoyaki 80, milk pudding 190); a dearer fish or a better grade is
  worth more raw. `python -I tools/balance.py` shows each recipe's gain (column cheap).
  Commit: this commit (the dish prices, see WORKLOG 2026-11-04).
- Item 1, everything in English: Esc → Settings → Language: English / ไทย. Thai tables in
  data/lang/th (menus, settings, HUD, key hints, rucksack, shops, kitchen, festival games, the
  record, the messages, names of items, places and people, and the first dialogue: opening,
  first morning, shop greetings, bin note, clinic, look-at lines, festival greetings, recipe
  lessons, the year record); anything missing stays English. Thai glyphs drawn for our pixel
  font. Plainer English: the onigiri reads "A rice ball with a quick pickle inside", and a
  recipe without its tool says which one ("needs Clay pot", "Clay pot (buy at store)").
  Still English: the villagers' daily talk, heart events and contest lines. Commit c3dce89.
- A slow start, no small goal in week one: Tome's first-week list (data/goals.json): plant 9
  plots, say hello to 3 people, pick 4 wild plants, catch a fish (all day 1–3), ship 5 crops
  and earn 1000 G (week one), each with a reward (money, rice balls, seed bags, a chick) and a
  villager's thank-you note; the HUD shows the goal now under the clock. Commit e3ad897.
- Love had no end point (item 3): courting now ends in marriage. Sayo or Fumi can be asked
  with a mizuhiki knot (1500 G at the store) at band 6, after their band 6 scene (Fumi got
  one) and with the second room built; anyone not ready says why and the knot stays in hand.
  The wedding is at the shrine three days later, then the spouse lives at the farmhouse and
  has married lines; Tome mentions the knot on Fridays. data/marriage.json. Commit be3a2bb.
- Roofs in front of the farmer hid the screen (village, festival square, snow): buildings,
  trees and the torii turn see-through when they stand between the camera and the farmer.
  Commit 67cbaed.
- The world's edge showed empty sky (e.g. the top left of the snowy village): land runs on past
  every outdoor map's edge, with pines behind the map. Commit 67cbaed.
- No on-screen key hints (keys were only in the README): the HUD says what E / Space do at
  the spot in front, with the player's own keys; Settings → Key hints turns it off.
  Commit 7ca5b91.

## What the players liked (keep it)
- 15–20: the pixel sprites on the 3D field look good and match everywhere; the Japanese
  countryside (cherry trees, the torii, tiled roofs) is worth a screenshot. The mochi pounding is
  clear from one line and fun. Faces in the text box and hearts on the name tag make people
  want to talk.
- 21–30: lots of depth (19 recipes, the mine and its lift, forage, festivals with contests,
  hidden fatigue, the starred village record at the year's end). A day is about 9 real
  minutes and saves from the Esc menu, good for short sessions. Full settings: key remapping,
  pad, UI size, text speed, lightning off.
