class_name WorldPlan
extends RefCounted
## The plan of the valley (data/world.json): where each outdoor map lies, in cells, the village
## at [0, 0], and where the water that runs off the maps goes (2026-11-15). A stream of water on
## a map's edge with no map across it ("an off-plan run") goes on past the maps: upstream, to its
## source off the plan; downstream, out of the valley; or on across the gap to meet another run
## carried straight on (Sakurazaka's creek running south into the village's river flowing east).
## Pure data and geometry: test_maps `_world` checks it, tools/map_overview.gd `--world` draws it.

const EDGES := {"west": Vector2i.LEFT, "east": Vector2i.RIGHT, "north": Vector2i.UP, "south": Vector2i.DOWN}


static func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))


## Each map's top-left corner on the plan.
static func places(cfg := {}) -> Dictionary:
	if cfg.is_empty():
		cfg = config()
	var out := {}
	for id in cfg.maps:
		out[id] = Vector2i(int(cfg.maps[id][0]), int(cfg.maps[id][1]))
	return out


## The map lying on plan cell `c`, "" for none.
static func owner(c: Vector2i, at: Dictionary) -> String:
	for id in at:
		var m := MapManager.data(id)
		if Rect2i(at[id], Vector2i(m.w, m.h)).has_point(c):
			return id
	return ""


## Every off-plan run: {key: "<map>:<edge>", map, edge, dir: Vector2i, cells: Array[Vector2i]
## (plan cells of the water on that edge, in order)}. Water cells on an edge are grouped by edge;
## a map has one stream per edge (checked by the test).
static func off_plan_runs(at: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in at:
		var m := MapManager.data(id)
		for edge in EDGES:
			var d: Vector2i = EDGES[edge]
			var cells: Array[Vector2i] = []
			for y in m.h:
				for x in m.w:
					var c := Vector2i(x, y)
					if m.tile(c) != "water" or m.in_bounds(c + d):
						continue
					if owner(c + d + at[id], at) == "":
						cells.append(c + at[id])
			if not cells.is_empty():
				out.append({"key": "%s:%s" % [id, edge], "map": id, "edge": edge, "dir": d, "cells": cells})
	return out


## The run with `key` among `runs`, {} for none.
static func run_of(runs: Array[Dictionary], key: String) -> Dictionary:
	for r in runs:
		if r.key == key:
			return r
	return {}


## Where run `a` carried straight on meets run `b` carried straight on (their directions across
## each other, each heading toward the other's line): the plan cells of the meeting, a Rect2i;
## an empty Rect2i when they never meet.
static func meeting(a: Dictionary, b: Dictionary) -> Rect2i:
	var da: Vector2i = a.dir
	var db: Vector2i = b.dir
	if da.x * db.x + da.y * db.y != 0:
		return Rect2i()
	var ra := _span(a.cells)
	var rb := _span(b.cells)
	# a's width across its way, b's across its own: the meeting is a's columns (or rows) by b's.
	var r := Rect2i(ra.position.x, rb.position.y, ra.size.x, rb.size.y) if da.x == 0 else Rect2i(rb.position.x, ra.position.y, rb.size.x, ra.size.y)
	for run in [a, b]:
		var s := _span(run.cells)
		var d: Vector2i = run.dir
		var ahead := (r.position.x >= s.end.x) if d == Vector2i.RIGHT else (r.end.x <= s.position.x) if d == Vector2i.LEFT \
			else (r.position.y >= s.end.y) if d == Vector2i.DOWN else (r.end.y <= s.position.y)
		if not ahead:
			return Rect2i()
	return r


## The plan cells water fills carrying `run` straight on from its edge up to (not into) `stop`, or
## `steps` cells when `stop` is empty.
static func carried(run: Dictionary, stop := Rect2i(), steps := 0) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var d: Vector2i = run.dir
	for c: Vector2i in run.cells:
		var p := c + d
		var n := 0
		while (stop.has_area() and not stop.has_point(p) and n < 4096) or (not stop.has_area() and n < steps):
			out.append(p)
			p += d
			n += 1
	return out


static func _span(cells: Array) -> Rect2i:
	var r := Rect2i(cells[0], Vector2i.ONE)
	for c: Vector2i in cells:
		r = r.expand(c).merge(Rect2i(c, Vector2i.ONE))
	return r
