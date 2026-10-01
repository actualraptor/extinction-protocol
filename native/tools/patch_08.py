from pathlib import Path
root=Path('native/scripts')
def edit(name,old,new):
 p=root/name;s=p.read_text(encoding='utf-8-sig');assert old in s,(name,old[:70]);p.write_text(s.replace(old,new),encoding='utf-8')
edit('catalog.gd','"fortune":{"name":"Scavenger\'s Luck", "desc":"+5% amber and improved chest rarity odds / rank", "cost":80,"max":5}', '''"fortune":{"name":"Scavenger's Legacy", "desc":"+5% amber and luck / rank (legacy)", "cost":80,"max":5},
	"reroll":{"name":"Second Thoughts","desc":"+1 starting reroll / rank","cost":180,"max":5},
	"luck":{"name":"Lucky Fossil","desc":"+1% luck / rank","cost":120,"max":10},
	"projectiles":{"name":"Full Magazine","desc":"+1 projectile / rank","cost":1800,"max":2},
	"chains":{"name":"Storm Memory","desc":"+1 chain target / rank","cost":2000,"max":2},
	"revive":{"name":"Refuse Extinction","desc":"One revival at 50% health per run","cost":3000,"max":1},
	"greed":{"name":"Amber Prospector","desc":"+5% amber earned / rank","cost":100,"max":8},
	"growth":{"name":"Ancient Insight","desc":"+3% XP earned / rank","cost":120,"max":8},
	"magnet":{"name":"Gathering Instinct","desc":"+12 XP pickup radius / rank","cost":90,"max":8},
	"armor":{"name":"Fossil Plating","desc":"+1 armor / rank","cost":220,"max":3},
	"recovery":{"name":"Living History","desc":"+0.15 health per second / rank","cost":240,"max":4}''')
edit('evolutions.gd','if not g.weapons.has(part) or g.weapons[part].level<10: valid = false','if not g.weapons.has(part): valid = false\n\t\tif valid and maxi(g.weapons[UNIONS[id].parts[0]].level,g.weapons[UNIONS[id].parts[1]].level)<10: valid=false')
edit('evolutions.gd','w.level>=8 and g.rank_of(g.C.WEAPONS[id].requires)>=2','w.level>=10')
edit('evolutions.gd','" at rank X → "','" (either weapon maxed) → "')
edit('combat_rules.gd','const EVOLUTION_RANK = 8','const EVOLUTION_RANK = 10')
edit('combat_rules.gd','var count = d.get("count",1)+g.rank_of("count")+int(rank>=5)+int(rank>=9)+(2 if evo else 0)','''var milestones = int(rank>=5)+int(rank>=10 if id=="lightning" else rank>=9)
	var count = d.get("count",1)+g.rank_of("count")+milestones+(2 if evo else 0)
	if d.delivery=="chain": count+=g.research_ranks.get("chains",0)
	elif d.delivery=="projectile": count+=g.research_ranks.get("projectiles",0)''')
edit('combat_rules.gd','if rank==10: return "MASTERED / +20% final power. Eligible for compatible unions."','if rank==10: return "+20% power. Chest evolution ready."+ (" +1 chain target." if d.name=="Stormbinder" else "")\n\tif rank==5 and d.name=="Stormbinder": return "+1 chain target. More damage."')
edit('combat_rules.gd','out.area.filter = {"any":["AREA"]}','out.area.filter = {"any":["AREA"]}\n\tout.area.desc = "+12% attack area."')
edit('expedition.gd','var campaign_bosses = 0','var campaign_bosses = 0\nvar research_ranks = {}\nvar revives = 0\nvar permanent_luck = 0.0\nvar daily_plan = {}\nvar breakable_clock = 0.0\nvar breakable_cells = {}\nconst Daily = preload("res://scripts/daily_challenge.gd")\nconst Breakables = preload("res://scripts/breakables.gd")')
edit('expedition.gd','\thero = character\n\tmode = run_mode','''	hero = character
	mode = run_mode
	research_ranks = research.duplicate(true) if mode=="expedition" else {}
	revives = int(research_ranks.get("revive",0))
	rerolls = 3+int(research_ranks.get("reroll",0))
	permanent_luck = research_ranks.get("luck",0)*0.01+research_ranks.get("fortune",0)*0.05
	if mode=="daily":
		daily_plan=Daily.plan(seed_value)
		hero=daily_plan.hero
		map_id=daily_plan.map
		terrain.layout=Maps.DATA[map_id].layout''')
edit('expedition.gd','armor = data.armor','armor = data.armor+research_ranks.get("armor",0)')
edit('expedition.gd','fortune = 1.0 + (research.get("fortune",0)*0.05 if mode=="expedition" else 0.0)','fortune = 1.0+research_ranks.get("fortune",0)*0.05+research_ranks.get("greed",0)*0.05')
edit('expedition.gd','hp+rank_of("regen")*0.35*dt','hp+(rank_of("regen")*0.35+research_ranks.get("recovery",0)*0.15)*dt')
edit('expedition.gd','var radius = 95+rank_of("pickup")*35','var radius = 95+rank_of("pickup")*35+research_ranks.get("magnet",0)*12')
edit('expedition.gd','xp += gem.value*(1+rank_of("pickup")*0.08)','xp += gem.value*(1+research_ranks.get("growth",0)*0.03)*(1+rank_of("pickup")*0.08)')
edit('relic_system.gd','maxf(0,g.fortune-1)','g.permanent_luck')
edit('expedition.gd','\tif hp<=0:\n\t\tdeath_reason = reason','''	if hp<=0 and revives>0:
		revives-=1
		hp=max_hp*0.5
		invul=3.0
		buffs.immune=3.0
		effect.emit("evolve",pos,Color("ffe8a2"),380)
		sound.emit("evolve")
		banner.emit("EXTINCTION REFUSED","50% HEALTH / THREE SECONDS OF IMMUNITY")
		log_event("revive",{})
		return
	if hp<=0:
		death_reason = reason''')
edit('expedition.gd','\toptions = []\n\toption_is_relic = relic','\tif mode=="daily":\n\t\tDaily.reward(self,relic)\n\t\treturn\n\toptions = []\n\toption_is_relic = relic')
edit('expedition.gd','rerolls = mini(5,rerolls+1)','rerolls = mini(5+int(research_ranks.get("reroll",0)),rerolls+1)')
edit('expedition.gd','\tupdate_exploration()\n\tif terrain','\tupdate_exploration()\n\tBreakables.update(self,dt)\n\tif terrain')
edit('expedition.gd','\t\tif e.dead: continue\n\t\tvar step','\t\tif e.dead or e.get("breakable",false): continue\n\t\tvar step')
edit('expedition.gd','\te.dead = true\n\tRelics.on_kill','\te.dead = true\n\tif e.get("breakable",false):\n\t\tBreakables.destroy(self,e)\n\t\treturn\n\tRelics.on_kill')
edit('swarm_renderer.gd','if e.dead or e.boss or e.anchor or e.elite: continue','if e.dead or e.boss or e.anchor or e.elite or e.get("breakable",false): continue')
edit('crowd.gd','\treturn result\n','''	if g.boss!=null and not e.boss and not e.anchor:
		var gap: Vector2 = result-g.boss.p
		var spacing: float = g.boss.size*1.15+radius(e)+18
		if gap.length_squared()<spacing*spacing:
			result=g.boss.p+(gap.normalized() if gap.length_squared()>0.01 else Vector2.from_angle(e.uid*2.399))*spacing
	return result
''')
print('core patched')
