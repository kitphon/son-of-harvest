class_name TextBoxLayout
extends RefCounted
## Where the text box pieces sit and how its text wraps. Kept apart from TextBox (the view)
## so DialogueRunner can check that every line fits and headless tests can check the rest.

## In viewport pixels (480 x 270): the paper box across the bottom (over the tool bar),
## the portrait inside it on the left and the text to its right.
const BOX := Rect2i(4, 208, 472, 58)
const PORTRAIT := Rect2i(7, 7, 44, 44)     # in the box: a wooden frame round a 40 x 40 face
const TEXT_POS := Vector2i(60, 8)          # in the box
const TEXT_W := 402
const ROWS := 4                            # text rows per line of dialogue
const NAME_H := 15                         # the wooden name tag over the box's top edge
const CHOICE_TEXT_W := 160
const CHOICE_ROW := 12


## Pixels from one text row to the next.
static func row_h() -> int:
	return PixelFont.size() + int(PixelFont.data().line_gap)


## `text` broken into rows no wider than `width` (at spaces; a word longer than a row gets
## a row of its own). Joining the rows with "\n" gives a string as long as `text`, so the
## first n letters of either show the same words.
static func wrap_rows(text: String, width: int) -> PackedStringArray:
	var rows := PackedStringArray()
	for para in text.split("\n"):
		var row := ""
		var first := true
		for word in para.split(" "):
			if first:
				row = word
				first = false
			elif PixelFont.width(row + " " + word) <= width:
				row += " " + word
			else:
				rows.append(row)
				row = word
		rows.append(row)
	return rows


## The text as it is drawn: the wrap's line breaks put in place of spaces.
static func wrapped(text: String, width := TEXT_W) -> String:
	return "\n".join(wrap_rows(text, width))
