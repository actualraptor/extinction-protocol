extends RefCounted
const RECIPES={
	"tfk_broadcast":{"parts":["tfk_phone","tfk_list"],"name":"Den Sista Sändningen","desc":"Ljudlänkar följs av en gigantisk mikrofon och chockvåg.","base":"tfk_phone","damage":52.0,"cooldown":4.5,"radius":210.0},
	"tfk_meltdown":{"parts":["tfk_backpack","tfk_facts"],"name":"Psykisk Härdsmälta","desc":"Förträngda problem frigör psykiska projektiler och kaotiska effekter.","base":"tfk_backpack","damage":38.0,"cooldown":5.0,"radius":200.0},
	"tfk_disaster":{"parts":["tfk_scenario","tfk_mac"],"name":"Helt Jävla Urspårat","desc":"Woolkes sändningsmaskin utlöser markerade katastrofer.","base":"tfk_scenario","damage":60.0,"cooldown":22.0,"radius":240.0}}
const RELICS={
	"tfk_poppis":["Pöppis","Var femte aktivering kan upprepas.",{"tfk_repeat":.25}],
	"tfk_shoblainx":["Shoblainx!","Kritiska träffar kan skapa en extra projektil.",{"tfk_extra":.20}],
	"tfk_job":["Vårt Gamla Jobb","Mer erfarenhet från besegrade fiender.",{"xp":.12}],
	"tfk_cut":["Johannes, Klipp Bort Det Där","Johannes klipper bort en träff. Lång återhämtning.",{"tfk_guard":1.0}],
	"tfk_product":["Produkten Ska Bort Från Marknaden","Svaga vanliga fiender kan avrättas.",{"tfk_execute":.15}],
	"tfk_ad":["Gissa Annonsen","Eliter kan tappa ytterligare en upptagbar bonus.",{"tfk_loot":.20}],
	"tfk_coffee":["Kaffepaus","Nästa attack förstärks efter en skadefri paus.",{"tfk_coffee":.25}],
	"tfk_skin":["Under Skinnet","Woolke skrämmer fiender som blir mer sårbara.",{"tfk_fear":1.0}],
	"tfk_edit":["Det Tar Vi I Efterhand","Johannes upprepar föregående attack med lägre skada.",{"tfk_edit":.4}],
	"tfk_reunion":["Originaluppsättningen","Woolkes inhopp förstärks och trion återförenas kort i direktsändning.",{"tfk_reunion":.25}]}
static func install(catalog):
	preload("res://scripts/evolutions.gd").UNIONS.merge(RECIPES)
	for id in RECIPES:
		var recipe=RECIPES[id];var d=catalog.WEAPONS[recipe.base].duplicate(true)
		d.merge(recipe,true);d.fusion=true;d.evolution=recipe.name;d.profile="tfk"
		catalog.WEAPONS[id]=d
	for id in RELICS:
		var data=RELICS[id]
		catalog.RELICS[id]={"name":data[0],"desc":data[1],"mods":data[2],"color":"c9a3ff","rarity":"RARE","min_tier":"EPIC" if id=="tfk_reunion" else "COMMON","profile":"tfk","roll_weight":.3 if id=="tfk_reunion" else 1.0,"max_copies":10,"filter":{}}
	preload("res://scripts/relic_system.gd").definitions_cache.merge(catalog.RELICS)
static func prepare(g,s):
	var result=s.duplicate(true)
	var mods=g.Relics.modifiers(g)
	if mods.get("tfk_coffee",0)>0 and g.time-g.tfk_state.get("last_damage",0)>=8 and g.time>=g.tfk_state.get("coffee_ready",0):
		result.power*=1+minf(.75,mods.tfk_coffee)
		result.tfk_coffee_used=true
	return result
static func cameo(g,name,duration=1.5):
	g.tfk_state.cameo=name;g.tfk_state.cameo_until=g.time+duration
	if name=="Johannes Lindh":preload("res://scripts/tfk_dialogue.gd").speak(g,"klipp_bort")
static func on_cast(g,id,s,cast_number):
	if g.tfk_state.get("replaying",false):return
	if s.get("tfk_coffee_used",false):g.tfk_state.coffee_ready=g.time+8
	var mods=g.Relics.modifiers(g)
	var system=load("res://scripts/tfk_system.gd")
	if cast_number%5==0 and g.rng.randf()<minf(.75,mods.get("tfk_repeat",0)):
		system.schedule(g,{"wait":.2,"kind":"replay","id":id,"stats":s.duplicate(true),"p":g.pos})
	var previous=g.tfk_state.get("last_attack",{})
	if mods.get("tfk_edit",0)>0 and not previous.is_empty() and g.weapons.has(previous.id) and g.time>=g.tfk_state.get("edit_ready",0):
		var replay=previous.stats.duplicate(true);replay.power*=minf(.65,mods.tfk_edit)
		system.schedule(g,{"wait":.35,"kind":"replay","id":previous.id,"stats":replay,"p":g.pos})
		g.tfk_state.edit_ready=g.time+12;cameo(g,"Johannes Lindh")
		g.tfk_state.editing_until=g.time+1.5
	g.tfk_state.last_attack={"id":id,"stats":s.duplicate(true)}
	if mods.get("tfk_fear",0)>0 and g.time>=g.tfk_state.get("fear_ready",0):
		g.tfk_state.fear_ready=g.time+20;cameo(g,"Jimmy Woolke")
		for e in g.nearby(g.pos,180):
			if not e.boss and not e.anchor:e.tfk_fear_until=g.time+2;e.tfk_vulnerable_until=g.time+2
static func block(g):
	if g.Relics.modifiers(g).get("tfk_guard",0)<=0 or g.time<g.tfk_state.get("guard_ready",0):return false
	g.tfk_state.guard_ready=g.time+60;cameo(g,"Johannes Lindh")
	return true
static func on_critical(g,e,id,power):
	if g.tfk_state.get("replaying",false) or g.proc_depth>0 or g.time<g.tfk_state.get("extra_ready",0):return
	if g.rng.randf()>=minf(.6,g.Relics.modifiers(g).get("tfk_extra",0)):return
	g.tfk_state.extra_ready=g.time+.4
	if g.shots.size()<80:
		g.shoot(id,g.pos,(e.p-g.pos).normalized(),power*.25,400,1.5,1)
		g.shots[-1].tfk_proc=true
static func on_kill(g,e):
	if e.elite and not e.boss and g.pickups.size()<30 and g.rng.randf()<minf(.6,g.Relics.modifiers(g).get("tfk_loot",0)):
		g.Pickups.drop(g,e.p,true,false)
