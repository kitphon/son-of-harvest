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

### 5. Grilled fish is still a shortcut (21–30)
One fish makes a dish that sells for 80 G (WORKLOG already warns about it). Check it against
the fish's own price in data/recipes.json.

### 6. Night is too bright, no lit windows (21–30)
Night barely darkens the field, and house windows never light up.

## Order to fix
1. ~~Item 1 (Thai text): keeps the 15–20 players.~~ Fixed.
2. ~~Items 2 and 3 (week-one goal, where love leads).~~ Fixed.
3. Items 4 and 5 (mine winter income, grilled fish price).
4. Item 6 (night), then ~~7 and 8~~ (fixed).

## Fixed
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

- Small things (item 7): the barn's yellow lumps were the hay bundles and the hay in the
  trough, drawn in one flat unlit yellow; they are now lit and textured with grass strands
  (`build:hay`), and the straw bedding on the floor is a duller, denser mat close to the
  earth's tone. The title's name sits on a see-through paper wash and the note under the menu
  on its own paper strip, so both read over the rice field. Commit 10b0184.
- "Saved food is broken" on the title (item 8): reproduced, and not a half-written file. The
  title checks the save by loading it into a scratch game that had only the crop table, so
  every save holding a food (`milk` in the playtest's save) failed and Continue went grey.
  The scratch game now gets all of Game's data tables (`Game.DATA_TABLES`). Saving is also
  made safe against being read mid-write: it writes `save1.json.tmp`, checks it, keeps the
  good save it replaces as `save1.json.bak`, then renames the temp over the slot; a slot that
  is cut off or missing loads the backup (the title says so), and with no backup says "The
  save file is cut off or broken" without touching the game. Commit: item 8's commit (see WORKLOG).

## What the players liked (keep it)
- 15–20: the pixel sprites on the 3D field look good and match everywhere; the Japanese
  countryside (cherry trees, the torii, tiled roofs) is worth a screenshot. The mochi pounding is
  clear from one line and fun. Faces in the text box and hearts on the name tag make people
  want to talk.
- 21–30: lots of depth (19 recipes, the mine and its lift, forage, festivals with contests,
  hidden fatigue, the starred village record at the year's end). A day is about 9 real
  minutes and saves from the Esc menu, good for short sessions. Full settings: key remapping,
  pad, UI size, text speed, lightning off.
