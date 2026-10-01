from pathlib import Path
r=Path('native/scripts')
def edit(n,a,b):
 p=r/n;s=p.read_text(encoding='utf-8-sig');assert a in s,(n,a[:60]);p.write_text(s.replace(a,b),encoding='utf-8')
edit('combat_rules.gd','\tout = preload("res://scripts/evolutions.gd").enrich(out)','''	out.thorns={"name":"Ironbriar","desc":"Thorn bursts. Retaliates when hit. Armor adds damage.","color":"9feeab","damage":25.0,"cooldown":2.4,"evolution":"BRAMBLE CROWN","evolution_desc":"Wider, stronger thorn bursts and retaliation.","requires":"armor","tags":["WEAPON","PHYSICAL","AREA","DEFENSIVE","RETALIATION","KNOCKBACK","CRITICAL"],"delivery":"thorns","radius":115.0,"icon":3}
	out = preload("res://scripts/evolutions.gd").enrich(out)''')
edit('evolutions.gd','const UNIONS = {','const UNIONS = {\n\t"thornking":{"parts":["thorns","club"],"name":"IRONBRIAR KING","desc":"Armored thorn bursts slam the horde backward. Retaliation releases a stronger shockwave.","base":"thorns","damage":48.0,"cooldown":1.8,"radius":155.0,"color":"baffb0"},')
edit('combat_rules.gd','"filter":{"all":["DEFENSIVE"]}','"filter":{"all":["DEFENSIVE"],"none":["RETALIATION"]}')
edit('combat_rules.gd','const AUGMENTS = {','''const AUGMENTS = {
	"spines":{"name":"Hardened Spines","desc":"+25% thorn damage. +15% thorn area.","tags":["PASSIVE","RETALIATION"],"filter":{"all":["RETALIATION"]},"stats":{"power":0.25,"radius":0.15},"max":3},
	"retribution":{"name":"Quick Retort","desc":"Thorn bursts attack 15% faster.","tags":["PASSIVE","RETALIATION"],"filter":{"all":["RETALIATION"]},"stats":{"haste":0.15},"max":3},''')
edit('combat_rules.gd','"power":d.damage*','"power":(d.damage+(minf(g.armor,25)*4 if "RETALIATION" in d.tags else 0))*')
edit('combat_rules.gd','if behavior=="shield": return','if behavior=="thorns": return "Stronger thorn bursts. Armor adds +4 base damage per point (up to 25)."\n\tif behavior=="shield": return')
edit('upgrade_copy.gd','"health","armor","speed"','"health","speed"')
edit('upgrade_copy.gd','\tvar d=g.C.AUGMENTS','\tif o.type=="passive" and o.id=="armor": return g.weapons.keys().filter(func(id):return "RETALIATION" in g.C.WEAPONS[id].tags)\n\tvar d=g.C.AUGMENTS')
edit('discoveries.gd','["club","spear","frost"]','["club","spear","thorns"]')
edit('discoveries.gd','const ENTRIES = {','const ENTRIES = {\n\t"ironbriar":{"name":"The Ironbriar Cache","desc":"Unlock Ironbriar: armor-scaling thorn bursts and retaliation.","cost":0,"depth":0,"pos":Vector2(-510,980),"map":"cradle","weapons":["thorns"],"goal":"kills","target":800},')
edit('combat_engine.gd','\t\tmatch d.delivery:\n','\t\tmatch d.delivery:\n\t\t\t"thorns":\n\t\t\t\tg.blast(g.pos,s.radius,s.power,id)\n')
edit('combat_engine.gd','"aura","shield","utility","orbital"','"aura","shield","utility","orbital","thorns"')
edit('expedition.gd','\tif shield>0:\n','''	if not piercing and time>=relic_state.get("thorns_ready",0.0):
		for id in weapons:
			if C.WEAPONS[id].delivery!="thorns": continue
			var stats=Rules.stats(self,id)
			relic_state.thorns_ready=time+maxf(0.65,stats.cooldown*0.4)
			blast(pos,stats.radius,stats.power*(1.15 if id=="thornking" else 0.8),id)
			sound.emit("thorns")
			break
	if shield>0:
''')
edit('atlas_icons.gd','static func frontier(index):','''static func field(index):
	var t=AtlasTexture.new();t.atlas=preload("res://assets/thorns-breakables-08.png")
	var cell=Vector2(t.atlas.get_size())/2
	t.region=Rect2(Vector2(index%2,floori(index/2.0))*cell,cell)
	return t
static func frontier(index):''')
edit('atlas_icons.gd','\tif cache.has(key): return cache[key]','\tif cache.has(key): return cache[key]\n\tif id in ["thorns","thornking","spines","retribution"]: return field(0)')
edit('world.gd','prop([0,6,8][e.prop_art],at,54,Color(1.7,1.7,1.7) if e.flash>0 else Color("ddc4a0"))','draw_texture_rect(preload("res://scripts/atlas_icons.gd").field(e.prop_art+1),Rect2(at-Vector2(30,47),Vector2(60,60)),false,Color(1.7,1.7,1.7) if e.flash>0 else Color.WHITE)')
edit('combat_engine.gd','"p":p,"angle":0.0,"radius":s.radius,"wait":0.75+j*0.12','"p":p,"launch":g.pos,"flight":0.75+j*0.12,"angle":0.0,"radius":s.radius,"wait":0.75+j*0.12')
edit('spell_fx.gd','\tfor h in s.hazards:\n\t\tif h.wait>0','''	for h in s.hazards:
		if h.has("launch") and h.wait>0:
			var t=clampf(1.0-h.wait/h.flight,0,1)
			var base=h.launch.lerp(h.p,t)
			var lift=4*t*(1-t)*minf(230,100+h.launch.distance_to(h.p)*0.25)
			var p=world.screen(base)+Vector2(0,-lift)
			var tangent=(h.p-h.launch)/h.flight+Vector2(0,-4*(1-2*t)*minf(230,100+h.launch.distance_to(h.p)*0.25)/h.flight)
			piece(6,p,Vector2(55,34),tangent.angle(),1.0)
			for j in range(1,4):
				var tail=maxf(0,t-j*0.025)
				var tp=world.screen(h.launch.lerp(h.p,tail))+Vector2(0,-4*tail*(1-tail)*minf(230,100+h.launch.distance_to(h.p)*0.25))
				piece(6,tp,Vector2(40,23),tangent.angle(),0.2/j)
			continue
		if h.wait>0''')
edit('spell_fx.gd','\t\tif e.kind=="blast_club":','''		if e.kind in ["blast_thorns","blast_thornking"]:
			for j in range(10):
				var angle=j*TAU/10
				var at=p+Vector2.from_angle(angle)*e.size*progress
				draw_set_transform(at,angle+progress*2)
				draw_texture_rect(Icons.field(0),Rect2(-Vector2.ONE*26,Vector2.ONE*52),false,Color(1,1,1,(1-progress)*0.8))
				draw_set_transform(Vector2.ZERO)
		if e.kind=="blast_club":''')
# Per-district arrangements retain connected perimeter roads and generous gaps.
edit('terrain_map.gd','\tvar result = 0','''	var variant=h%3
	if variant==1:
		var swapped=x;x=y;y=swapped
	elif variant==2:
		x=15-x
	var result = 0''')
edit('terrain_map.gd','\tcached[c] = result','''	if variant==2 and center(c).length()>520 and x>2 and y>2:
		if layout==0: result=1 if (x in [5,6,11] and y in [4,5,10,11]) else 0
		elif layout==1: result=1 if (x in [4,5,11,12] and y in [4,5,11,12]) else 0
		elif layout==2: result=1 if (y in [4,11] and x in [4,5,6,10,11,12]) else 0
	cached[c] = result''')
edit('world.gd','\tfor chest in sim.relic_chests:','''	# Sparse nonblocking scenery breaks up repeated districts without covering paths.
	for gx in range(floori((center.x-get_viewport_rect().size.x/2-100)/384),ceili((center.x+get_viewport_rect().size.x/2+100)/384)):
		for gy in range(floori((center.y-get_viewport_rect().size.y/2-100)/384),ceili((center.y+get_viewport_rect().size.y/2+100)/384)):
			var h=absi(gx*92821 ^ gy*68917 ^ sim.terrain.seed_value)
			if h%3!=0: continue
			var at=Vector2(gx*384+50+h%80,gy*384+50+(h/7)%80)
			if not sim.terrain.walkable(at,36): continue
			if sim.map_id=="cradle": prop(6+sim.depth,screen(at),75+h%30,Color(0.7,0.8,0.74,0.65))
			else: draw_texture_rect(preload("res://scripts/atlas_icons.gd").frontier(9 if sim.map_id=="frostbreak" else 11),Rect2(screen(at)-Vector2(50,50),Vector2(100,85)),false,Color(0.7,0.8,0.9,0.65))
	for chest in sim.relic_chests:''')
print('thorns mortar terrain ready')
