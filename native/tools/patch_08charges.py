from pathlib import Path
p=Path('native/scripts/expedition_maps.gd');s=p.read_text();s=s.replace('[0,4,14,14,2,3]','[0,0,4,4,14,2,3]').replace('[0,4,14,14,15,15,7]','[0,0,4,4,14,15,15,7]').replace('[0,4,14,15,15,6,12]','[0,4,4,14,15,15,6,12]');p.write_text(s)
p=Path('native/scripts/expedition.gd');s=p.read_text();s=s.replace('var campaign_bosses = 0','var campaign_bosses = 0\nvar charge_ready = 0.0');s=s.replace('\tvar species = Bestiary.DATA[kind]','''	if Bestiary.DATA[kind].role=="charge" and kind_override<0:
		var chargers=0
		for creature in enemies:
			if not creature.dead and creature.get("role","")=="charge": chargers+=1
			if chargers>=5+depth: break
		if chargers>=5+depth:
			var alternatives=composition.filter(func(k):return Bestiary.DATA[k].role!="charge")
			if not alternatives.is_empty(): kind=alternatives[rng.randi_range(0,alternatives.size()-1)]
	var species = Bestiary.DATA[kind]''');s=s.replace('if e.attack<=0 and delta.length()<430:','if e.attack<=0 and delta.length()<430 and time>=charge_ready:\n\t\t\t\t\tcharge_ready=time+maxf(0.75,1.15-depth*0.15)');p.write_text(s)
