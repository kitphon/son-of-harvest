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

### 1. Everything is in English (15–20)
The biggest wall for young Thai players. Some lines are hard even for good English readers:
the kitchen's "Pantry rice round a quick pickle", or "no tool" without saying which tool is
missing. Needs a Thai text set (and a language setting), plus plainer English where it's vague.
The key hints added in 7ca5b91 are English too.

### 2. A slow start, no small goal in week one (15–20)
The farm starts with 500 G, a chicken costs 1,400 G and a cow 6,000 G, so the first days are
only "water and wait". Wants a small goal that can be reached by day 2–3 (and a few more
through week one).

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
1. Item 1 (Thai text): keeps the 15–20 players.
2. Item 2 (week-one goal; item 3, where love leads, is fixed).
3. Items 4 and 5 (mine winter income, grilled fish price).
4. Item 6 (night), then 7 and 8.

## Fixed
- Love had no end point (item 3): courting now ends in marriage. Sayo or Fumi can be asked
  with a mizuhiki knot (1500 G at the store) at band 6, after their band 6 scene (Fumi got
  one) and with the second room built; anyone not ready says why and the knot stays in hand.
  The wedding is at the shrine three days later, then the spouse lives at the farmhouse and
  has married lines; Tome mentions the knot on Fridays. data/marriage.json. This commit.
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
