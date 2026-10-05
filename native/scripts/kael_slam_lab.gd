extends Node
## Isolated playable effect prototype. Never writes run rewards or progression.
const Slam=preload("res://scripts/kael_slam.gd")
const Combat=preload("res://scripts/combat_engine.gd")
const CADENCES=[.8,.25,.08,.03]
var game
var speed=0
var variant=0
var next=0.0
var keys={}
var caption
func _ready():
	game.selected=1;game.chosen_mode="safari";game.start_run();game.paused=true
	var g=game.sim
	g.halloween=false;g.enemies.clear();g.boss=null;g.hazards.clear();g.shots.clear();g.zones.clear();g.echoes.clear();g.passives.clear();g.augments.clear();g.buff_stacks.clear()
	g.map_id="cradle";g.depth=0;g.time=0;g.level=1;g.boss_stage=0
	game.clear_menu();game.hud_root.visible=false
	caption=game.label(game.menu_root,"",18,"edddb6");caption.position=Vector2(45,30);caption.size=Vector2(1300,85)
	configure()
func configure():
	var g=game.sim;var id="earthshaker" if variant==2 else "club"
	g.weapons={id:{"level":1,"evolved":variant>0,"timer":99999,"casts":0}}
	g.kael_attack.clear();g.echoes.clear();game.world.effects.clear();g.enemies.clear()
	for i in range(16):
		var e=g.spawn_enemy(false,g.pos+Vector2.from_angle(i*TAU/16)*(150 if i%2==0 else 260));e.hp=1e12;e.max_hp=e.hp
	next=g.time
	caption.text="KAEL SLAM TEST — %s — %.2fs between attacks\nF6: speed  |  F7: weapon  |  F8: ground  |  F9: Halloween  |  WASD: move  |  Close window to exit"%[["Ancestor's Wrath","World Breaker","Earth Shaker"][variant],CADENCES[speed]]
func pressed(key):
	var down=Input.is_physical_key_pressed(key);var edge=down and not keys.get(key,false);keys[key]=down;return edge
func _process(dt):
	if game.sim==null:return
	var g=game.sim
	if pressed(KEY_F6):speed=(speed+1)%CADENCES.size();configure()
	if pressed(KEY_F7):variant=(variant+1)%3;configure()
	if pressed(KEY_F8):g.map_id="frostbreak" if g.map_id=="cradle" else "observatory" if g.map_id=="frostbreak" else "cradle";configure()
	if pressed(KEY_F9):g.halloween=not g.halloween
	var movement=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()
	g.pos=g.terrain.move(g.pos,movement*220*dt)
	if movement.x!=0:g.facing=-1 if movement.x<0 else 1
	g.time+=dt;g.build_grid();Combat.update(g,dt)
	if g.time>=next:
		var id="earthshaker" if variant==2 else "club"
		var stats=g.Rules.stats(g,id);stats.cooldown=CADENCES[speed];stats.repeat=0;stats.radius=180 if variant==0 else 270 if variant==1 else 320
		Slam.start(g,id,Vector2(g.facing,0),stats);next=g.time+CADENCES[speed]
