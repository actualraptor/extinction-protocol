from pathlib import Path
r=Path('native/scripts')
def edit(n,a,b):
 p=r/n;s=p.read_text(encoding='utf-8-sig');assert a in s,(n,a[:50]);p.write_text(s.replace(a,b),encoding='utf-8')
edit('world_pickups.gd','const DEFINITIONS = {','const DEFINITIONS = {\n\t"amber":{"name":"AMBER CACHE","desc":"+8 amber","duration":0.0,"icon":7,"color":"ffc76e"},')
edit('world_pickups.gd','match id:\n','match id:\n\t\t"amber": g.amber+=8\n')
edit('world.gd','\t\tif not e.boss and not e.elite and not e.anchor: continue','''		if e.get("breakable",false):
			var at=screen(e.p)
			if visible_rect().grow(80).has_point(at):
				prop([0,6,8][e.prop_art],at,54,Color(1.7,1.7,1.7) if e.flash>0 else Color("ddc4a0"))
			continue
		if not e.boss and not e.elite and not e.anchor: continue''')
edit('readability.gd','\tfor h in s.hazards:','''	elif s.boss!=null:
		var e=s.boss
		var p=world.screen(e.p)
		var tint=Color(1.6,1.6,1.6) if e.flash>0 else Color.WHITE
		if e.kind>=5:
			var region=world.frontier_regions[e.kind-14] if e.kind>=14 else world.monster_regions[e.kind-5]
			var dims=region.size/maxf(region.size.x,region.size.y)*e.size*3
			draw_set_transform(p,0,Vector2(-1 if e.p.x>s.pos.x else 1,1))
			draw_texture_rect_region(world.frontier_sheet if e.kind>=14 else world.monster_sheet,Rect2(Vector2(-dims.x/2,-dims.y*0.75),dims),region,tint)
			draw_set_transform(Vector2.ZERO)
		else: world.sprite(3+e.kind,p,e.size*3,e.p.x>s.pos.x,tint,0,self)
	for h in s.hazards:''')
print('modules ready')
