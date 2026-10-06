extends SceneTree
const E=preload("res://scripts/expedition.gd")
const P=preload("res://scripts/reward_preview.gd")
var checks=0
var failures=0
func _initialize():
	var g=E.new();g.setup(5,"expedition",{},42)
	for id in g.C.WEAPONS:
		var d=g.C.WEAPONS[id]
		if not d.has("evolution") or d.evolution=="" or g.Evolutions.UNIONS.has(id):continue
		g.weapons={id:{"level":10,"evolved":false,"timer":100}};g.modifier_cache.clear()
		var rows=P.rows(g,{"type":"evolution","id":id})
		checks+=1
		if not rows.any(func(row):return row.before!=row.after):failures+=1;printerr("FAIL / no effective evolution improvement / ",id)
		print(id," / ",rows)
	print("EVOLUTION IMPROVEMENT / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
