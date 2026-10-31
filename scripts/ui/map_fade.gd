class_name MapFade
extends CanvasLayer
## The short fade to black when the farmer changes maps (doors, waking up, loading). The
## clock and the farmer wait while it runs (a Game pause); at black the view swaps the map,
## and when the picture is back Game.map_arrived() says the farmer is there.

const SECONDS := 0.25        # each way

var _rect: ColorRect
var _swap: Callable
var _busy := false


func _init() -> void:
	layer = 5                # over the picture and the HUD, under the text box and menus
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color(0, 0, 0, 0)
	add_child(_rect)


## Fades out, calls `swap` at black, fades back in. A change while one runs swaps again.
func run(swap: Callable) -> void:
	_swap = swap
	if _busy:
		return
	_busy = true
	Game.pause()
	var t := create_tween()
	t.tween_property(_rect, "color:a", 1.0, SECONDS)
	t.tween_callback(func(): _swap.call())
	t.tween_property(_rect, "color:a", 0.0, SECONDS)
	t.tween_callback(_done)


func busy() -> bool:
	return _busy


func _done() -> void:
	_busy = false
	Game.unpause()
	Game.map_arrived()


## Leaving the scene mid-fade (back to the title) must not leave the clock paused.
func _exit_tree() -> void:
	if _busy:
		_busy = false
		Game.unpause()
