# Harvest Son — English style

The English text is the source of every translation (README → Settings → Language), so it is
written once, plainly and the same way everywhere. test_lang checks the rules marked (checked).

## Spelling
- American English: favorite, neighbor, honored, traveler, gray, color, Mom, anymore. The
  seasons are Spring, Summer, Fall, Winter; "autumn" is fine as a poetic word in a line
  ("Eighty-one autumns") and in a name (Autumn salmon). (checked)

## Names
- Things are in sentence case: only the first word starts with a capital (Kitchen knife,
  Golden yolk egg, Animal medicine, Chicken coop, Genzo's house). (checked for items)
- Proper names keep their capitals: people, festivals and their contests and stalls, shops
  (Yorozu Store, Kurogane Smithy, Hanami Teahouse, Hinata Clinic), landmarks (Bamboo Hill),
  the record's ranks (Heart of the Village).
- A name put into a sentence stays as it is written (some older code lowers it; leave that).

## Messages
- A message over the field, a shop's note or a screen's note is a sentence and ends with
  `.`, `!`, `?` or `...` ("Your hands are full.", "Caught: %s!"). (checked)
- Not sentences, so no full stop: labels, menu rows, key hints, names, headings, arrival
  notices ("Mine floor %d") and pieces that go into another key ("eggs, milk or wool").
- Two sentences said together are two keys joined with `Lang.join` (README), each with its
  own full stop.

## Grammar that translates
- One key per sentence, no text glued from pieces (README → Settings → Language).
- No "a %s" / "an %s": English picks the article by the word, other languages don't have one.
  Use "the %s", a colon ("Caught: %s!", "Shipped: %s (%d G)."), or a data field with the
  whole phrase (a kitchen tool's `a_name`). (checked)
- Singular and plural are two keys ("%s %d day." / "%s %d days.").

## Voice
- Villagers keep their own voices: Kota's "gonna", Tome's "child" and "dear", Kiku's "dear",
  Ichiro's short sentences. These are deliberate, not slips.
- The farmer's lines are plain and short. Notices say what happened, not how to feel.

## Known gaps
- Some messages name a key by its default ("I = rucksack", "Q = next seed", "E on an
  animal"); remapped keys don't change them yet.
