extends Node
# Isolated local interaction lab. Simulation stays paused; no rewards or save writes.
const R=preload("res://scripts/remnant_system.gd")
var game
var variant=0
var keys={}
var caption
var first_kill_test=false
func _ready():
	first_kill_test="--first-kill-test" in OS.get_cmdline_user_args()
	game.selected=5;game.chosen_mode="safari";game.start_run();game.paused=true
	game.sim.choice_requested.disconnect(game.present_upgrade)
	game.clear_menu()
	caption=game.label(game.menu_root,"",16,"edddb6");caption.position=Vector2(360,190);caption.size=Vector2(1050,80)
	configure()
func configure():
	var g=game.sim
	if game.page=="rite-story":return
	game.world.effects.clear()
	g.sound.emit("rite_stop")
	g.enemies.clear();g.boss=null;g.boss_corpses.clear();g.portal=null;g.shots.clear();g.hazards.clear();g.zones.clear()
	g.weapons.clear()
	g.companions.units.clear();g.companions.reform.clear();g.companions.pending.clear()
	g.map_id=["cradle","frostbreak","observatory"][variant/2];g.depth=0;g.time=0;g.boss_stage=0;g.active=true;g.choosing=false;g.transition_time=0
	g.stage=preload("res://scripts/stage_definition.gd").stage(g.map_id)
	g.terrain.arena=Vector2.INF;g.terrain.cached.clear();g.terrain.clearance.clear();g.terrain.flow.clear()
	g.terrain.configure(g.stage,0)
	g.pos=g.terrain.open_position(g.stage.spawn+Vector2(500,300))
	game.world.camera_run=null
	g.spawn_boss(variant%2+1)
	var b=g.boss;b.p=g.terrain.open_position(g.pos+Vector2(0,-150))
	if first_kill_test:
		game.save_data.settings[preload("res://scripts/first_rite.gd").SEEN_FLAG]=false
		g.rite_pending=false;b.hp=1;b.max_hp=1
		g.weapons["u00"]={"level":1,"evolved":false,"timer":1000.0,"casts":0}
		g.companions.summon(g,"u00")
		var warrior=g.companions.units.back();warrior.p=b.p+Vector2(-35,25);warrior.attack=3.0
		g.build_grid()
		caption.text="FIRST BOSS KILL TEST / %s\nYour warrior defeats the boss in a few seconds / F6: next boss, fresh first kill / F5: replay / Hold Esc: skip story"%g.map_id
		return
	g.kill(b)
	g.enemies.clear();g.choosing=false;g.options.clear()
	g.hp=g.max_hp
	if "--ritual-test" in OS.get_cmdline_user_args():g.pos=g.boss_corpses[0].marker
	for i in range(8):
		var e=g.spawn_enemy(false,b.p+Vector2.from_angle(i*TAU/8)*240);e.hp=1000000;e.max_hp=e.hp
	g.build_grid()
	caption.text="LOCAL RITUAL TEST / %s\nF4: narrated story / F5: replay ritual / F6: next boss / F7: reset / WASD: move / F9: kill ally"%preload("res://scripts/boss_identity.gd").short_name(R.IDENTITIES[variant])
func pressed(key):
	var down=Input.is_physical_key_pressed(key);var edge=down and not keys.get(key,false);keys[key]=down;return edge
func _process(dt):
	if game.sim==null:return
	if game.page=="rite-story":
		if first_kill_test and pressed(KEY_F6):
			for child in game.layer.get_children():
				if child.get_script()==preload("res://scripts/first_rite_player.gd"):
					child.finish();variant=(variant+1)%6;configure();break
		return
	var g=game.sim
	g.transition_time=maxf(0,g.transition_time-dt)
	if pressed(KEY_F6):variant=(variant+1)%6;configure()
	if pressed(KEY_F4):game.play_first_rite(R.IDENTITIES[variant],true);return
	if pressed(KEY_F5):
		configure()
		if not first_kill_test:g.pos=g.boss_corpses[0].marker
	if pressed(KEY_F7):configure()
	if pressed(KEY_F8) and g.portal!=null:
		g.pos=g.portal;g.choosing=false;g.enter_portal()
	if pressed(KEY_F9):
		for u in g.companions.units:u.hp=0
	var move=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()
	g.velocity=move*220;g.pos=g.terrain.move(g.pos,g.velocity*dt);g.time+=dt;g.build_grid()
	g.companions.update(g,dt);R.update(g,dt)
	g.strikes=g.strikes.filter(func(s):s.life-=dt;return s.life>0)
