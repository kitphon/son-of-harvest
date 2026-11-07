class_name MapFade
extends CanvasLayer
## The short fade to black when the farmer changes maps (doors, waking up, loading). The
## clock and the farmer wait until it starts back from black (a Game pause); at black the view
## swaps the map, and as the picture comes back the farmer may walk and Game.map_arrived()
## says the farmer is there.
##
## Building a map takes a long frame (and the first frames that draw it compile shaders), so
## the screen stays black for HOLD_FRAMES frames after the swap, and every step of the fade is
## at most MAX_STEP seconds: a slow frame never makes the fade jump (playtest 2026-11-07: the
## picture popped back half-faded right after the swap, and the first frames on the new map
## stuttered in view).

const OUT_SECONDS := 0.2     # to black
const IN_SECONDS := 0.25     # back from black
const HOLD_FRAMES := 3       # frames kept black after the swap (the build, the first draws)
const MAX_STEP := 1.0 / 30.0 # the most of the fade one frame may move

var _rect: ColorRect
var _swap: Callable
var _busy := false
var _phase := ""             # "out", "hold", "in" while busy
var _hold := 0
var _pausing := false        # holding a Game pause (out and black)


func _init() -> void:
	layer = 5                # over the picture and the HUD, under the text box and menus
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color(0, 0, 0, 0)
	add_child(_rect)
	set_process(false)


## Fades out, calls `swap` at black, fades back in. A change while one runs swaps again.
func run(swap: Callable) -> void:
	_swap = swap
	if _busy:
		_phase = "out"   # past black already: go (or stay) dark and swap again
		_pause(true)
		return
	_busy = true
	_phase = "out"
	_pause(true)
	set_process(true)


func busy() -> bool:
	return _busy


## Is the screen held black after the swap (ShaderWarm's quads may show)?
func holding() -> bool:
	return _phase == "hold"


## The fade's darkness now, 0 (clear) .. 1 (black).
func alpha() -> float:
	return _rect.color.a


func _process(delta: float) -> void:
	var step := minf(delta, MAX_STEP)
	match _phase:
		"out":
			_rect.color.a = minf(1.0, _rect.color.a + step / OUT_SECONDS)
			if _rect.color.a >= 1.0:
				_swap.call()
				_phase = "hold"
				_hold = HOLD_FRAMES
		"hold":
			_hold -= 1
			if _hold <= 0:
				_phase = "in"
				_pause(false)   # the farmer may walk as the picture comes back
				Game.map_arrived()
		"in":
			_rect.color.a = maxf(0.0, _rect.color.a - step / IN_SECONDS)
			if _rect.color.a <= 0.0:
				_done()


func _done() -> void:
	_busy = false
	_phase = ""
	set_process(false)


func _pause(on: bool) -> void:
	if on and not _pausing:
		Game.pause()
	elif not on and _pausing:
		Game.unpause()
	_pausing = on


## Leaving the scene mid-fade (back to the title) must not leave the clock paused.
func _exit_tree() -> void:
	_busy = false
	_pause(false)
