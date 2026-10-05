extends RefCounted
const RULESET="0.11.5"
const C=preload("res://scripts/catalog.gd")
const Maps=preload("res://scripts/expedition_maps.gd")
static func plan(seed_value):
	var rng=RandomNumberGenerator.new();rng.seed=seed_value
	var maps=Maps.DATA.keys();maps.sort()
	return {"hero":rng.randi_range(0,C.HEROES.size()-1),"map":maps[rng.randi_range(0,maps.size()-1)],"seed":seed_value}
