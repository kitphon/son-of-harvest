extends SceneTree
## Draws the app icon (our own design: a sprout over tilled field rows under a morning sky,
## in the game's ground colours) and writes `icon.png` (the project icon) and `icon.ico`
## (the Windows exe icon). Run after changing the drawing:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/make_icon.gd

const PIXELS := [
	"..oooooooooooo..",
	".osssssssssssso.",
	"osssssssssssyyso",
	"osssssssssssyyso",
	"oSSllSSSSSSllSSo",
	"oSlLLlSSSSlLLlSo",
	"oSSlLLlSSlLLlSSo",
	"oSSSSllttllSSSSo",
	"oSSSSSSttSSSSSSo",
	"oggggggttggggggo",
	"orrrrrrttrrrrrro",
	"offffffffffffffo",
	"orrrrrrrrrrrrrro",
	"offffffffffffffo",
	".orrrrrrrrrrrro.",
	"..oooooooooooo..",
]

const COLORS := {
	"o": Color("2a1e1e"),   # outline, as the sprites'
	"s": Color("8fc0e8"),   # sky, higher
	"S": Color("b8d8ee"),   # sky near the ground
	"y": Color("f6e2a0"),   # morning sun
	"l": Color("4e8a34"),   # leaf edge
	"L": Color("86c25a"),   # leaf
	"t": Color("5e7a2a"),   # stem
	"g": Color("6fae4a"),   # grass (the ground tile's colour)
	"r": Color("a07446"),   # tilled ridge (dry soil)
	"f": Color("6b4a2a"),   # furrow
}

const ICO_SIZES := [16, 32, 48, 64, 128, 256]
const PNG_SIZE := 256


func _init() -> void:
	var base := draw()
	var png := _scaled(base, PNG_SIZE)
	var err := png.save_png("res://icon.png")
	var ico_err := _save_ico("res://icon.ico", base)
	print("make_icon: icon.png %s, icon.ico %s" % [error_string(err), error_string(ico_err)])
	quit(1 if err != OK or ico_err != OK else 0)


## The 16 x 16 design.
static func draw() -> Image:
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		var row: String = PIXELS[y]
		assert(row.length() == 16, "icon row %d" % y)
		for x in 16:
			var ch := row[x]
			img.set_pixel(x, y, COLORS[ch] if COLORS.has(ch) else Color(0, 0, 0, 0))
	return img


static func _scaled(base: Image, size: int) -> Image:
	var img := base.duplicate()
	img.resize(size, size, Image.INTERPOLATE_NEAREST)
	return img


## An .ico holding one PNG per size (read by Windows Vista and later).
static func _save_ico(path: String, base: Image) -> Error:
	var pngs: Array[PackedByteArray] = []
	for size in ICO_SIZES:
		pngs.append(_scaled(base, size).save_png_to_buffer())
	var out := StreamPeerBuffer.new()   # little endian
	out.put_u16(0)
	out.put_u16(1)                      # 1 = icon
	out.put_u16(ICO_SIZES.size())
	var offset := 6 + 16 * ICO_SIZES.size()
	for i in ICO_SIZES.size():
		var size: int = ICO_SIZES[i]
		out.put_u8(size % 256)          # 0 means 256
		out.put_u8(size % 256)
		out.put_u8(0)                   # no palette
		out.put_u8(0)
		out.put_u16(1)                  # colour planes
		out.put_u16(32)                 # bits per pixel
		out.put_u32(pngs[i].size())
		out.put_u32(offset)
		offset += pngs[i].size()
	for p in pngs:
		out.put_data(p)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_buffer(out.data_array)
	return OK
