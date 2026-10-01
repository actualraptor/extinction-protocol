from pathlib import Path
r=Path('native/scripts')
def edit(n,a,b):
 p=r/n;s=p.read_text(encoding='utf-8-sig');assert a in s,(n,a[:50]);p.write_text(s.replace(a,b),encoding='utf-8')
edit('sound.gd','\tbank.gun = bank.revolver','''	for id in "revolver shotgun frost fire lightning club spear orbital mortar pyre winter miasma dread aegis stasis thunderstorm thunder_hit chain_tick ricochet return harpoon lantern glacier sunbow thorns breakable impact_frost impact_fire impact_metal".split(" "):
		bank[id]=load("res://assets/audio/"+id+"_08.wav")
	bank.thornking=bank.thorns
	bank.gun = bank.revolver''')
edit('sound.gd','voice.volume_db -= 4','voice.volume_db -= 2')
edit('sound.gd','\tvoice.pitch_scale = pitch','\tvar active_voices=0\n\tfor other in voices:\n\t\tif other.playing: active_voices+=1\n\tvoice.volume_db-=minf(7,active_voices*0.45)\n\tvoice.pitch_scale = pitch')
edit('expedition.gd','func speed(): return C.HEROES[hero].speed*(1+rank_of("speed")*0.08)','func speed(): return C.HEROES[hero].speed*(1+rank_of("speed")*0.08)*(1+minf(0.15,(level-1)*0.005) if hero==3 else 1.0)')
edit('expedition.gd','\treturn base_damage*','\tvar growth=1.0+minf(0.5,(level-1)*0.01) if hero==1 and "PHYSICAL" in tags else 1.0+minf(0.4,(level-1)*0.01) if hero==2 and "SPELL" in tags else 1.0\n\treturn growth*base_damage*')
edit('expedition.gd','func crit_chance():','''func trait_text():
	match hero:
		0: return "GUNSLINGER / +%s projectiles (one per 10 levels; max 3)"%mini(3,level/10)
		1: return "FIRST HUNTER / +%s%% physical damage (1%% per level; max 50%%)"%mini(50,level-1)
		2: return "RIFTWALKER / +%s%% spell damage (1%% per level; max 40%%)"%mini(40,level-1)
		3: return "POLAR HUNTER / +%.1f%% movement (0.5%% per level; max 15%%)"%minf(15,(level-1)*0.5)
	return "ASTRONOMER / +%.1f%% arcane attack speed (0.5%% per level; max 20%%)"%minf(20,(level-1)*0.5)
func crit_chance():''')
edit('combat_rules.gd','elif d.delivery=="projectile": count+=g.research_ranks.get("projectiles",0)','elif d.delivery=="projectile": count+=g.research_ranks.get("projectiles",0)+(mini(3,g.level/10) if g.hero==0 else 0)')
edit('combat_rules.gd','\tvar relic_mods = g.Relics.modifiers(g)','\tif g.hero==4 and "ARCANE" in d.tags: haste+=minf(0.2,(g.level-1)*0.005)\n\tvar relic_mods = g.Relics.modifiers(g)')
edit('backpack_panel.gd','"%s / LEVEL %s   •   Hover equipment for full effects"%[g.C.HEROES[g.hero].name,g.level]','g.trait_text()')
edit('backpack_panel.gd','g.rank_of("count")+int(mods.get("count",0))','g.rank_of("count")+int(mods.get("count",0))+g.research_ranks.get("projectiles",0)+(mini(3,g.level/10) if g.hero==0 else 0)')
edit('backpack_panel.gd','g.rank_of("regen")*0.35','g.rank_of("regen")*0.35+g.research_ranks.get("recovery",0)*0.15')
edit('backpack_panel.gd','95+g.rank_of("pickup")*35','95+g.rank_of("pickup")*35+g.research_ranks.get("magnet",0)*12')
edit('backpack_panel.gd','(1+g.rank_of("pickup")*0.08)*(1+mods','(1+g.research_ranks.get("growth",0)*0.03)*(1+g.rank_of("pickup")*0.08)*(1+mods')
edit('backpack_panel.gd','["Luck rank",str(g.rank_of("luck"))]','["Luck bonus","+%.0f%%"%((g.rank_of("luck")*0.1+g.permanent_luck)*100)]')
edit('backpack_panel.gd','["Hits taken",str(g.hits)]','["Revives remaining",str(g.revives)]')
edit('catalog.gd','+16% critical chance. Precision becomes carnage.','+16% critical chance. +1 projectile every 10 levels (max 3).')
edit('catalog.gd','Heavy cleaves. Thick skin. Relentless knockback.','+1% physical damage per level (max 50%). Armor strengthens Ironbriar.')
edit('catalog.gd','Starts with Stormbinder. +20% spell damage.','Stormbinder. +20% spell damage, +1% per level (max +40%).')
edit('catalog.gd','+20% ice damage. Piercing harpoon starter.','+20% ice damage. +0.5% speed per level (max 15%).')
edit('catalog.gd','+20% arcane damage. Seeking spectral volleys.','+20% arcane damage. +0.5% arcane speed per level (max 20%).')
# Display individual terrain hazard cells after district transforms.
edit('world.gd','elif posmod(x,16)==10 and posmod(y,16)==4:\n\t\t\t\tp += Vector2(96,64)','else:\n\t\t\t\tp += Vector2.ZERO')
edit('world.gd','Rect2(p-Vector2(138,106),Vector2(276,212))','Rect2(p-Vector2(40,40),Vector2(80,80))')
print('traits audio ready')
