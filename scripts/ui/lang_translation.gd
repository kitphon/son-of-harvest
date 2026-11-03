class_name LangTranslation
extends Translation
## Hands Godot's auto-translation (every Label's text) to Lang.t, so the language tables'
## patterns and the Thai mark shaping apply to all text on screen.


func _get_message(src_message: StringName, _context: StringName) -> StringName:
	if Lang.current != locale:
		return &""
	var src := String(src_message)
	var out := Lang.t(src)
	return StringName(out) if out != src else &""
