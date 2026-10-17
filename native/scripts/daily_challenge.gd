extends RefCounted
const RULESET="0.13.1"
const C=preload("res://scripts/catalog.gd")
const Maps=preload("res://scripts/expedition_maps.gd")
static func plan(seed_value):
	var rng=RandomNumberGenerator.new();rng.seed=seed_value
	var maps=Maps.DATA.keys();maps.sort()
	var roster=[0,1,2]
	return {"hero":roster[rng.randi_range(0,roster.size()-1)],"map":maps[rng.randi_range(0,maps.size()-1)],"seed":seed_value}
