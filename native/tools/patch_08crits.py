from pathlib import Path
r=Path('native/scripts')
def edit(n,a,b):
 p=r/n;s=p.read_text(encoding='utf-8-sig');assert a in s,(n,a[:50]);p.write_text(s.replace(a,b),encoding='utf-8')
edit('expedition.gd',' and kind_override<0:',':')
edit('expedition.gd','func crit_chance(): return minf(0.65,C.HEROES[hero].crit+rank_of("crit")*0.07)','''static func crit_curve(raw):
	return minf(raw,1.0)+clampf(raw-1.0,0,1)*0.65+clampf(raw-2.0,0,2)*0.4+maxf(0,raw-4)*0.25
func crit_chance(): return crit_curve(C.HEROES[hero].crit+rank_of("crit")*0.07+research_ranks.get("critical",0)*0.02)
func roll_crit_tier(chance): return floori(chance)+int(rng.randf()<fposmod(chance,1.0))''')
edit('expedition.gd','var critical = can_crit and rng.randf()<crit_chance()\n\tif critical: amount *= 1.9','var crit_tier = roll_crit_tier(crit_chance()) if can_crit else 0\n\tvar critical = crit_tier>0\n\tif critical: amount *= 1.0+0.9*crit_tier')
edit('expedition.gd','\te.last_critical = critical','\te.last_critical = critical\n\te.last_crit_tier = crit_tier')
edit('expedition.gd','effect.emit("number",e.p,Color("ffe2a2") if critical else Color.WHITE,dealt)','effect.emit("crit_number_%s"%crit_tier if critical else "number",e.p,Color("ffe2a2") if critical else Color.WHITE,dealt)\n\t\tif critical: effect.emit("crit",e.p,Color("ffe2a2"),crit_tier)')
edit('catalog.gd','"desc":"+7% critical chance", "max":5','"desc":"+7% crit chance; smaller gains above 100%.", "max":60')
edit('catalog.gd','const RESEARCH = {','const RESEARCH = {\n\t"critical":{"name":"Hunter\'s Eye","desc":"+2% crit chance / rank (diminishes above 100%)","cost":200,"max":10},')
edit('upgrade_copy.gd','\treturn d.desc','\tif o.type=="passive" and o.id=="crit":\n\t\tvar raw=g.C.HEROES[g.hero].crit+g.rank_of("crit")*0.07+g.research_ranks.get("critical",0)*0.02\n\t\treturn "+%.1f%% crit chance.\\n%.1f%% → %.1f%%"%[(g.crit_curve(raw+0.07)-g.crit_chance())*100,g.crit_chance()*100,g.crit_curve(raw+0.07)*100]\n\treturn d.desc')
edit('world.gd','if kind=="number":','if kind=="number" or kind.begins_with("crit_number_"):')
edit('world.gd','"text":str(int(size)),"life":0.65','"text":str(int(size))+("!".repeat(mini(3,int(kind.get_slice("_",2)))) if kind.begins_with("crit_number_") else ""),"life":0.65')
edit('world.gd','var life = 0.10 if kind=="muzzle"','var life = 0.10 if kind in ["muzzle","crit"]')
edit('spell_fx.gd','elif kind in ["muzzle","sparks","hurt","blast_club"]: continue','elif kind in ["muzzle","sparks","hurt","blast_club","blast_thorns","blast_thornking"]: continue\n\t\t\telif kind=="crit":\n\t\t\t\tpiece(8,p,Vector2.ONE*(22+minf(3,e.size)*3),0,0.7*(1-progress),Color("ffe49b"))\n\t\t\t\tcontinue')
edit('boss_bar.gd','var value = 100.0','var value = 100.0\nvar health = 0\nvar maximum = 0')
edit('boss_bar.gd','\tfor y in range(ceili(channel.size.y)):', '\tfor y in range(ceili(channel.size.y)):')
p=r/'boss_bar.gd';s=p.read_text();s+='''
	var text="%s / %s HP"%[maxi(0,ceili(health)),ceili(maximum)]
	var font=ThemeDB.fallback_font
	var at=channel.position+Vector2((channel.size.x-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x)/2,channel.size.y/2+4)
	draw_string_outline(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,2,Color("15121c"))
	draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff2d5"))
''';p.write_text(s)
edit('main.gd','(boss_y+50)*factor','(boss_y+5)*factor')
edit('main.gd','boss_bar.value = sim.boss.hp/sim.boss.max_hp*100','boss_bar.value = sim.boss.hp/sim.boss.max_hp*100\n\t\tboss_bar.health=sim.boss.hp\n\t\tboss_bar.maximum=sim.boss.max_hp')
edit('backpack_panel.gd','"Critical chance","%.0f%%"','"Crit chance (tiers)","%.1f%%"')
print('crit and boss HP ready')
