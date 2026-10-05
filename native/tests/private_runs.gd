extends SceneTree
const E=preload("res://scripts/expedition.gd")
var checks=0
var failures=0
func check(ok,text):
 checks+=1
 if not ok: failures+=1;printerr("FAIL / ",text)
func game(mode="expedition",map_id="cradle"):
 var g=E.new();g.setup(2,mode,{},917,map_id)
 g.map_id=map_id;g.terrain.layout=g.Maps.DATA[map_id].layout
 return g
func claim(g):
 check(g.choosing and not g.options.is_empty(),"Reward awaits acknowledgement")
 var t=g.time;var hp=g.hp;var w=g.weapons.duplicate(true)
 g.tick(1.0,Vector2.RIGHT)
 check(g.time==t and g.hp==hp and g.weapons==w,"Simulation pauses throughout reveal")
 g.choose(0);var awarded=g.weapons.duplicate(true);var amber=g.amber
 g.choose(0)
 check(not g.choosing and g.weapons==awarded and g.amber==amber,"Reward claim is idempotent")
func defeat(g):
 var target=g.boss
 g.boss_time=4
 for phase_index in range(3):
  if target.dead: break
  target.reform=0
  for anchor in g.anchors.duplicate():g.hit(anchor,1e10,"lightning",false)
  g.hit(target,1e10,"lightning",false)
 check(target.dead,"Boss dies through actual damage and phase gates")
func _initialize():
 for map_id in E.Maps.DATA:
  for mode in ["expedition","daily"]:
   var g=game(mode,map_id)
   g.weapons={"frost":{"level":10,"evolved":false,"timer":0.1},"lightning":{"level":10,"evolved":false,"timer":0.1}}
   var ending=[];g.ended.connect(func(won):ending.append(won))
   for stage in range(1,4):
    g.time=g.next_boss-.01;g.invul=100;g.transition_time=0
    g.tick(.02,Vector2.ZERO)
    check(g.boss!=null and g.boss_stage==stage,"Scheduled boss / %s %s %s"%[mode,map_id,stage])
    if g.boss==null:break
    defeat(g)
    if stage==3 and mode=="expedition":
     check(not g.active and g.won and ending==[true],"Expedition wins exactly once")
     var report=g.report().duplicate(true);g.tick(10,Vector2.RIGHT);g.finish(false)
     check(g.report()==report,"Finished report remains stable")
     break
    check(g.active and g.portal!=null,"Defeated boss opens portal")
    var old_depth=g.depth;var old_loop=g.daily_loop
    g.enter_portal()
    check(g.depth==old_depth and g.daily_loop==old_loop and g.portal!=null,"Portal cannot skip unclaimed boss reward")
    claim(g)
    if stage==1:check(g.weapons.size()==1 and g.weapons.has("whiteout"),"Boss chest fuses two max weapons and frees slot")
    g.xp=g.xp_goal+1;g.invul=100;g.tick(.01,Vector2.ZERO)
    claim(g)
    g.explored[0][Vector2i(99,99)]=true;g.breakable_cells["previous"]=true
    g.pos=g.portal;g.linger=3;g.tick(.4,Vector2.ZERO)
    check(g.portal==null and g.transition_time>0,"Physical portal entry starts transition")
    check(g.hazards.is_empty() and g.hostile_shots.is_empty() and g.proc_queue.is_empty(),"Transition clears transient attacks")
    if stage==3:
     check(g.daily_loop==1 and g.depth==0 and g.boss_stage==0 and ending.is_empty(),"Daily loops without ending")
     check(not g.explored[0].has(Vector2i(99,99)) and g.breakable_cells.is_empty(),"New Daily map resets exploration and breakables")
     g.time=g.next_boss;g.transition_time=0;g.tick(.01,Vector2.ZERO)
     check(g.boss!=null and g.boss.max_hp==180000,"Next Daily circuit schedules stronger boss")
 var g=game();g.spawn_boss(1);g.boss.hp=1;g.build_grid()
 g.hostile_shots.append({"p":g.pos,"v":Vector2.ZERO,"life":1,"damage":999})
 g.brood_queue.append(g.pos)
 g.add_hazard("friendly",g.boss.p,0,120,0,.5,999);g.hazards[-1].id="fire"
 g.add_hazard("circle",g.pos,0,120,0,.5,999)
 var hp=g.hp;g.update_hazards(.01)
 check(g.boss==null and g.choosing and g.hp>=hp,"Killing impact interrupts pending hostile hazards")
 check(g.hazards.is_empty() and g.hostile_shots.is_empty() and g.brood_queue.is_empty(),"No attacks return after boss clear")
 g=game();g.cache_pos=g.pos;g.shrine_pos=g.pos;g.shrine_progress=6
 g.open_choices(false);var amber=g.amber
 g.update_objectives(.1)
 check(g.cache_timer==0 and not g.shrine_done and g.amber==amber,"Pending reward cannot consume another objective")
 g.choose(0);g.update_objectives(.1)
 check(g.choosing and not g.shrine_done,"Cache and shrine rewards cannot overwrite each other")
 g=game("daily");g.open_choices(false);var options=g.options.duplicate(true);var rerolls=g.rerolls
 check(not g.reroll_choices() and g.rerolls==rerolls and g.options==options,"Daily cannot reroll predetermined reveal")
 g=game();g.spawn_boss(3);g.boss_time=209.99;var ended=[];g.ended.connect(func(won):ended.append(won));g.update_boss(.02)
 check(not g.active and not g.won and g.extinction_timeout and ended==[false],"Meteor timeout ends once as defeat")
 var score=g.score;g.kill(g.boss)
 check(g.score==score and ended==[false],"Late attack cannot mutate a completed defeat")
 print("PRIVATE RUN INTEGRATION / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
