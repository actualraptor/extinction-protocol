extends SceneTree
const E=preload("res://scripts/expedition.gd")
const X=preload("res://scripts/content_extension.gd")
const R=preload("res://scripts/remnant_system.gd")
const Meter=preload("res://scripts/companion_meter.gd")
var checks=0
func check(ok,message):
	checks+=1
	if not ok:push_error(message);assert(ok,message)
func make(hero=5,map="cradle"):
	var g=E.new();g.setup(hero,"expedition",{},197,map);g.enemies.clear()
	if g.companions!=null:g.companions.units.clear()
	return g
func _initialize():
	X.install(preload("res://scripts/catalog.gd"))
	for map in ["cradle","frostbreak","observatory"]:
		for stage in [1,2]:
			var g=make(5,map);g.spawn_boss(stage);var boss=g.boss;g.kill(boss)
			check(g.boss_corpses.size()==1,"Each eligible boss leaves exactly one corpse")
			var c=g.boss_corpses[0]
			check(g.portal.distance_to(c.p)>=220 and g.portal.distance_to(c.marker)>=150,"Portal stays clear of corpse and marker")
			R.leave(g,boss);check(g.boss_corpses.size()==1,"Duplicate corpse insertion is harmless")
			check(R.enabled(g),"Rite is innate without a relic")
			check("r08" not in g.Relics.candidates(g),"Innate rite never takes a reward slot")
			g.pos=c.marker
			R.update(g,1);g.pos+=Vector2(100,0);R.update(g,.1)
			check(c.charge==0 and not c.raising,"Leaving marker cancels channel")
			g.pos=c.marker;R.update(g,R.CHANNEL)
			check(c.raising and not c.consumed,"Corpse remains while ritual runs")
			for frame in range(int((R.RITUAL+.25)*60)):R.update(g,1.0/60)
			check(c.consumed and g.companions.units.size()==1,"Completed rite consumes corpse and summons exactly once")
			var unit=g.companions.units[0]
			check(unit.max_hp>=650 and unit.max_hp<=1300,"Boss health has an identity-specific bounded base")
			check(unit.identity==c.identity and unit.role=="boss","Summon retains correct boss identity")
			check(Meter.census(g.companions.units,g.time).boss==1,"Boss minion contributes to counter")
			R.update(g,10);check(g.companions.units.size()==1,"Repeated update cannot duplicate resurrection")
			check(not g.companions.raise_remnant(g,c),"One living summon per boss identity")
			var victim=g.spawn_enemy(false,unit.p+Vector2(65,0));victim.hp=100000;victim.max_hp=victim.hp;g.build_grid()
			g.companions.remnant_impact(g,unit,victim,100)
			check(victim.hp<100000,"Each skeletal boss actually damages enemies")
			check(g.companions.army_report().strongest_summon.source=="u10","Actual boss damage appears in strongest-summon stats")
			g.choosing=false;g.enter_portal()
			check(g.boss_corpses.is_empty() and g.companions.units.has(unit),"Portal clears corpses but preserves living boss ally")
			unit.hp=0;g.companions.update(g,.1);g.time+=10;g.companions.update(g,.1)
			check(not g.companions.units.any(func(u):return u.get("boss_form",false)),"Dead boss never auto-reforms")
	var meteor=make();meteor.spawn_boss(3);R.leave(meteor,meteor.boss)
	var center=meteor.boss.p
	meteor.boss.p+=Vector2(90,0);meteor.update_boss(.01)
	check(meteor.boss.p==center,"Meteor resets attempted displacement to fixed arena anchor")
	meteor.companions.raise_remnant(meteor,{"identity":"thorn","p":center-Vector2(250,0)})
	var charger=meteor.companions.units[0];charger.charge_end=center+Vector2(250,0);charger.charge_until=meteor.time+2;charger.charge_hits={}
	meteor.build_grid()
	for i in range(60):meteor.companions.update_remnant_skill(meteor,charger,meteor.boss,.02)
	check(meteor.boss.p==center,"Summoned triceratops charge cannot displace meteor")
	check(charger.p.distance_to(center)>=meteor.companions.Contact.radius(charger)+meteor.companions.Contact.enemy_radius(meteor.boss),"Charge stops at meteor body")
	meteor.companions.units.clear()
	meteor.pos=meteor.boss_corpses[0].marker
	R.update(meteor,20);check(meteor.companions.units.is_empty(),"Meteor is never resurrectable")
	var ordinary=make(0);ordinary.spawn_boss(1);ordinary.kill(ordinary.boss)
	check(ordinary.boss_corpses.size()==1,"Ordinary heroes also leave persistent corpses")
	check(not R.enabled(ordinary),"Ordinary heroes cannot perform the innate rite")
	check(not ordinary.content_allowed("relics","r08") and not ordinary.content_allowed("weapons","u10"),"Exclusive ability remains hidden from ordinary heroes")
	check(not meteor.content_allowed("weapons","u10"),"Internal minion attack is never offered as a weapon")
	check(meteor.Relics.effects("r08","RARE")==meteor.Relics.effects("r08","ARTIFACT"),"Single-level strength does not scale with tier")
	print("REMNANTS / ",checks," checks passed")
	quit()
