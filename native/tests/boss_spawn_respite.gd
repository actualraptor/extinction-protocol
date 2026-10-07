extends SceneTree
const G=preload("res://scripts/expedition.gd")
func _initialize():
	for hero in range(6):
		var g=G.new();g.setup(hero,"safari",{},7321)
		g.spawn_boss(1)
		g.kill(g.boss)
		assert(g.spawn_respite==24.0)
		g.choosing=false;g.rite_pending=false;g.weapons.clear()
		g.enemies.clear();g.boss_corpses.clear();g.hp=100000;g.max_hp=100000
		g.breakable_clock=1000
		var uid=g.next_uid
		for i in range(239):g.tick(.1,Vector2.ZERO)
		assert(g.next_uid==uid,"Spawns occurred during boss respite")
		assert(g.linger==0,"Portal pressure advanced during respite")
		assert(g.director.respite_shift>23.9)
		for i in range(15):g.tick(.1,Vector2.ZERO)
		assert(g.next_uid>uid,"Spawns failed to resume")
		g.spawn_respite=12;g.enter_portal()
		assert(g.spawn_respite==0,"Respite leaked into the next map")
	print("BOSS RESPITE: six heroes, 24 seconds without spawns, delayed pressure, spawn recovery and portal reset passed")
	quit()
