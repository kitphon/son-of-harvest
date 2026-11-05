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

None right now.

## Order to fix
1. ~~Item 1 (Thai text): keeps the 15–20 players.~~ Fixed.
2. ~~Items 2 and 3 (week-one goal, where love leads).~~ Fixed.
3. ~~Items 4 and 5 (mine winter income, grilled fish price).~~ Fixed.
4. ~~Item 6 (night), then 7 and 8.~~ Fixed.

## Fixed
- Winter mining beat the whole farm (item 4): deep finds about halved again (data/mine.json
  `_prices`: hoshigane 110, jade 85, kogane 30 ...) and floors 13+ hide nothing half the time;
  the First Stone rivals scaled with them. Year bot, year 1 winter mine 73160 → 38378 G, the
  year's mine 88150 → 47558 G against 158118 G from the farm. Commit 31b6d7f (WORKLOG
  2026-11-04, Winter mine income halved again).
- Grilled fish was a shortcut (item 5): one 18 G fish made an 80 G dish. A dish now sells
  for about a third more than its cheapest ingredients (data/foods.json `_dish_prices`):
  grilled fish 25 G, ochazuke 80, fish and daikon 170, dobin mushi 135, and the same for
  plain eggs and milk (tamagoyaki 80, milk pudding 190); a dearer fish or a better grade is
  worth more raw. `python -I tools/balance.py` shows each recipe's gain (column cheap).
  Commit c336ef1.
- Item 1, everything in English: Esc → Settings → Language: English / ไทย. Thai tables in
  data/lang/th (menus, settings, HUD, key hints, rucksack, shops, kitchen, festival games, the
  record, the messages, names of items, places and people, and the first dialogue: opening,
  first morning, shop greetings, bin note, clinic, look-at lines, festival greetings, recipe
  lessons, the year record); anything missing stays English. Thai glyphs drawn for our pixel
  font. Plainer English: the onigiri reads "A rice ball with a quick pickle inside", and a
  recipe without its tool says which one ("needs Clay pot", "Clay pot (buy at store)").
  Commit c3dce89. (The daily talk, heart events and contest lines followed; see below.)
- Item 1 follow-up, the villagers' daily talk was English in Thai: every line of the twelve
  villagers' talk files (data/dialogue/talk_*.json, 498 lines) has Thai in
  data/lang/th/dialogue.json, each in the villager's own voice; test_lang checks that the talk
  is all Thai and that every Thai line fits the text box. Commit b46e58c (WORKLOG 2026-11-05, Thai daily talk).
- A slow start, no small goal in week one: Tome's first-week list (data/goals.json): plant 9
  plots, say hello to 3 people, pick 4 wild plants, catch a fish (all day 1–3), ship 5 crops
  and earn 1000 G (week one), each with a reward (money, rice balls, seed bags, a chick) and a
  villager's thank-you note; the HUD shows the goal now under the clock. Commit e3ad897.
- Love had no end point (item 3): courting now ends in marriage. Sayo or Fumi can be asked
  with a mizuhiki knot (1500 G at the store) at band 6, after their band 6 scene (Fumi got
  one) and with the second room built; anyone not ready says why and the knot stays in hand.
  The wedding is at the shrine three days later, then the spouse lives at the farmhouse and
  has married lines; Tome mentions the knot on Fridays. data/marriage.json. Commit be3a2bb.
- Night was too bright and no window lit up (item 6): the night is a deep blue (luminance
  0.31, was 0.46) that still shows the farmer and the paths, with a smooth dusk (warm 17:30,
  mauve 18:30, night by 20:30) and dawn (4:30 to 7:00); the farmhouse's and the village
  houses' windows and shoji doors glow warm from dusk to 0:30 and before dawn (3D view;
  the flat view only gets the darker night). data/light.json. Commit 3365ff1 (see
  WORKLOG 2026-11-04 "Night").
- Night, follow-up to item 6: lit windows, shoji doors and the stone lanterns now cast a soft
  warm pool on the ground (rising and fading with the windows, data/light.json "pools"), the
  lanterns' fire boxes glow, and a window's glow no longer tints the farmer or a villager
  standing in front of it. Commit 27e97f6 (WORKLOG 2026-11-05 "Night: warm pools").
- Night, flat view: main_2d had only the darker night. It now has the lit windows (a warm strip on
  the farmhouse and the village houses' windows and doors), the stone lanterns' fire, and the
  dithered warm pools under them, from the same layout, pools and brightness as the 3D view and
  under the figures. Commit 36ecda8 (WORKLOG 2026-11-05 "Night in the flat view").
- Roofs in front of the farmer hid the screen (village, festival square, snow): buildings,
  trees and the torii turn see-through when they stand between the camera and the farmer.
  Commit 67cbaed.
- The world's edge showed empty sky (e.g. the top left of the snowy village): land runs on past
  every outdoor map's edge, with pines behind the map. Commit 67cbaed.
- No on-screen key hints (keys were only in the README): the HUD says what E / Space do at
  the spot in front, with the player's own keys; Settings → Key hints turns it off.
  Commit 7ca5b91.
- Follow-up: pad players saw keyboard keys in the key hints. The game now remembers the last
  device used (pad button or stick past the deadzone, or key / click) and the hints show the
  player's own pad buttons ("A", "B", "LB") while the pad was last used. Commit af1995b.

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
  save file is cut off or broken" without touching the game. Commit 34393ea.

- Follow-up to item 3: the village record had no word about the spouse. A married farmer's
  record (and the yearly page) now has one line under the title, "Married Sayo on Spring 14"
  (the wedding day is kept after the wedding); "Married to Sayo" when that day is not known;
  nothing when single. data/ending.json `spouse`. See WORKLOG 2026-11-05 "Village record: the
  spouse's line". Commit 6f08235.
- Follow-up to item 1: Thai for the heart events (bands 3, 5, 6), the contest lines, the marriage
  texts (proposal answers, the wedding), the village record's pages and Tome's list notes, plus
  the spouse line ("Married Sayo on Spring 14" reads "แต่งงานกับซาโยะ เมื่อวันที่ 14 ใบไม้ผลิ")
  and the knot / wedding-day messages. 267 dialogue lines in data/lang/th/dialogue.json, 9 in
  ui.json. Commit 60f0661 (WORKLOG 2026-11-05 "Thai: heart events, contests, marriage, record").
- Night, flat view follow-up (item 6): the farmhouse's warm pool began 6 px over the roof's lower
  edge. In the flat view the pools in front of its south wall are now cut at the roof's edge
  (NightView, the 3D view unchanged); a check in test_view2d `_night`. See WORKLOG 2026-11-05
  "Flat view: the farmhouse's pool starts at the roof's edge". Commit ff53903.
- Follow-up to item 1: the last Thai gaps closed, so lang_report shows th at 100% with 0 stale.
  The goal list and its HUD tag, the tool and rod level-ups, the shopkeepers' away notes and
  Hachiro's late-build notes, the rope lift, the pad button names, the chick and the mizuhiki
  knot, the long date and every saved-game / settings error the title can show (108 entries in
  data/lang/th/ui.json, 2 in items.json). Recipe `taught` notes, node names and a regex were
  never on screen and are now left out of the catalog. WORKLOG 2026-11-05 "Thai: the last gaps". Commit 96a67e1.

## What the players liked (keep it)
- 15–20: the pixel sprites on the 3D field look good and match everywhere; the Japanese
  countryside (cherry trees, the torii, tiled roofs) is worth a screenshot. The mochi pounding is
  clear from one line and fun. Faces in the text box and hearts on the name tag make people
  want to talk.
- 21–30: lots of depth (19 recipes, the mine and its lift, forage, festivals with contests,
  hidden fatigue, the starred village record at the year's end). A day is about 9 real
  minutes and saves from the Esc menu, good for short sessions. Full settings: key remapping,
  pad, UI size, text speed, lightning off.
