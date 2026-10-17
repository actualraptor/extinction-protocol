extends RefCounted
const IDS=["tfk_phone","tfk_backpack","tfk_list","tfk_facts","tfk_eyes","tfk_mac","tfk_scenario"]
static func playtest_enabled():return "--tfk-test" in OS.get_cmdline_user_args() or OS.has_feature("tfk_playtest")
const ARSENAL={
	"tfk_backpack":["Ryggsäcken","Förträngda problem laddar en cirkulär chockvåg.","Det Är Mycket Nu",24.0,5.0,160.0,"cfa577"],
	"tfk_list":["Johans Topplista","Fem markerade nedslag räknar ned till ett.","Sveriges Topp Ett",22.0,7.5,75.0,"ffd76c"],
	"tfk_facts":["Mathies Fantastiska Fakta","Sökande frågetecken sprider märkliga effekter.","Fullständigt Faktaresistent",20.0,3.2,110.0,"a0e8da"],
	"tfk_eyes":["Hajögon","En spektral blick låser vanliga fiender.","Tom Bakom Ögonen",12.0,6.0,175.0,"89d8ed"],
	"tfk_mac":["Dagens Mac","Elektriska pulser kopplar ihop fiender.","Planerat Åldrande",23.0,3.6,145.0,"93caff"],
	"tfk_scenario":["Dagens Scenario","Woolke dyker upp med ett katastrofalt scenario.","Det Finns Inga Bra Alternativ",45.0,30.0,200.0,"f5b08b"]}
## Registration appends after existing content; historical survivor IDs stay stable.
static func install(catalog):
	for i in range(catalog.HEROES.size()):
		if catalog.HEROES[i].get("profile","")=="tfk":return i
	catalog.HEROES.append({"name":"TFK: Mathie & Johan","title":"De Sista Programledarna","profile":"tfk","weapon":"tfk_phone","hp":130.0,"speed":240.0,"armor":2.0,"crit":0.10,"color":"c9a3ff","desc":"Världen går under. Avsnittet fortsätter.\nSamspelet laddar Direktsändning."})
	catalog.WEAPONS.tfk_phone={"name":"Ring En Främling","desc":"En förbannad telefon skickar ljudvågor mellan fiender.","color":"c9a3ff","damage":28.0,"cooldown":2.2,"count":3,"range":210.0,"radius":85.0,"tags":["SPELL","OFFENSIVE","CHAIN","ARCANE","CRITICAL","AREA"],"delivery":"tfk","icon":4,"requires":"haste","evolution":"Hemligt Nummer","evolution_desc":"Den sista ljudlänken exploderar.","targeting":"nearest","projectile_interval":0.0,"max_active":24,"terrain_blocks":false,"boss_hit_interval":0.0}
	for id in ARSENAL:
		var a=ARSENAL[id];var d=catalog.WEAPONS.tfk_phone.duplicate(true)
		d.merge({"name":a[0],"desc":a[1],"evolution":a[2],"evolution_desc":a[1],"damage":a[3],"cooldown":a[4],"radius":a[5],"color":a[6],"count":2,"tags":["SPELL","OFFENSIVE","ARCANE","AREA","CRITICAL"]},true)
		if id=="tfk_mac":d.tags.append("LIGHTNING");d.tags.append("CHAIN")
		if id=="tfk_facts":d.tags.append("PROJECTILE")
		if id=="tfk_eyes":d.tags.append("CROWD_CONTROL");d.tags.append("FREEZE")
		catalog.WEAPONS[id]=d
	for id in IDS:catalog.WEAPONS[id].profile="tfk"
	preload("res://scripts/tfk_items.gd").install(catalog)
	return catalog.HEROES.size()-1
static func active(g):
	return g.C.HEROES[g.hero].get("profile","")=="tfk"

