extends RefCounted
const CHANNEL=2.5
const RITUAL=12.0
const ID="r08"
const IDENTITIES=["thorn","basalt","hunt","aurora","warden","bloom"]
static var corpse_poses={}
static func corpse_art(identity):
	if corpse_poses.has(identity):return corpse_poses[identity]
	var index=IDENTITIES.find(identity)
	if index<0:return null
	var art=AtlasTexture.new();art.atlas=preload("res://assets/field-remains.png")
	var regions=[Rect2(0,50,550,470),Rect2(550,50,465,470),Rect2(1015,50,521,470),Rect2(0,525,525,499),Rect2(525,515,490,509),Rect2(1015,520,521,504)]
	art.region=regions[index];art.filter_clip=true
	# Match painted wound fluid and ground stains to the ritual's boss palette.
	if identity in ["basalt","aurora","warden","bloom"]:
		var image=art.atlas.get_image()
		var target=preload("res://scripts/rite_animation.gd").fluid(identity)
		var bounds=Rect2i(art.region)
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x):
				var pixel=image.get_pixel(x,y)
				if pixel.a>.01 and pixel.r>pixel.g*1.65 and pixel.r>pixel.b*1.45 and pixel.s>.55:
					var stained=Color.from_hsv(target.h,target.s,pixel.v,pixel.a)
					image.set_pixel(x,y,stained)
		art.atlas=ImageTexture.create_from_image(image)
	corpse_poses[identity]=art
	return art

static func enabled(g):return g.companions!=null and preload("res://scripts/content_extension.gd").is_profile(g)
static func occupied(g,identity=""):return g.companions!=null and g.companions.units.any(func(u):return u.hp>0 and u.get("boss_form",false) and u.identity==identity)
static func leave(g,b):
	if g.boss_corpses.any(func(c):return c.uid==b.uid):return
	var identity=b.get("identity","meteor")
	var marker=g.terrain.open_position(b.p+Vector2(-90,125))
	g.boss_corpses.append({"uid":b.uid,"p":b.p,"kind":b.kind,"identity":identity,"marker":marker,"charge":0.0,"ritual":0.0,"raising":false,"consumed":false,"size":b.size})
	g.log_event("remnant-left",{"identity":identity})
static func portal_position(g,corpse):
	for radius in [320,420,540]:
		for i in range(24):
			var p=g.terrain.open_position(corpse.p+Vector2.from_angle(i*TAU/24)*radius)
			if p.distance_to(corpse.p)>=220 and p.distance_to(corpse.marker)>=150:return p
	return g.terrain.open_position(corpse.p+Vector2(650,0))
static func update(g,dt):
	for c in g.boss_corpses:
		if c.consumed:
			c.afterglow=maxf(0,c.get("afterglow",0.0)-dt)
			continue
		if c.identity not in IDENTITIES:continue
		if not enabled(g) or occupied(g,c.identity) or g.companions.units.size()>=g.companions.LIMIT:
			if c.raising:g.sound.emit("rite_stop")
			c.charge=0;c.ritual=0;c.raising=false;continue
		if g.pos.distance_to(c.marker)>42:
			if c.raising:g.sound.emit("rite_stop")
			c.charge=0;c.ritual=0;c.raising=false;continue
		if not c.raising:
			var previous=c.charge
			c.charge=minf(CHANNEL,c.charge+dt)
			preload("res://scripts/rite_circle.gd").beats(g,previous,c.charge)
			if c.charge>=CHANNEL:
				c.raising=true;c.ritual=0;g.sound.emit("rite_hum")
		else:
			var before=c.ritual
			c.ritual+=dt
			preload("res://scripts/rite_circle.gd").beats(g,CHANNEL+before,CHANNEL+c.ritual)
			for piece in [0,3,6,8]:
				var beat=preload("res://scripts/rite_animation.gd").split_time(piece)
				if before<beat and c.ritual>=beat:g.sound.emit("rite_crunch")
			for part in range(9):
				var lock=5.92+part*.64
				if before<lock and c.ritual>=lock:g.sound.emit("rite_lock")
			if c.ritual>=RITUAL and g.companions.raise_remnant(g,c):
				c.consumed=true
				c.afterglow=.9
				g.sound.emit("rite_stop");g.sound.emit("rite_finish")
				g.voice_event.emit("resurrection")
				g.log_event("remnant-raised",{"identity":c.identity})
static func clear(g):
	if g.boss_corpses.any(func(c):return c.raising and not c.consumed):g.sound.emit("rite_stop")
	g.boss_corpses.clear()
static func draw(world,g):
	for c in g.boss_corpses:
		if c.consumed:
			if c.get("afterglow",0.0)>0:
				preload("res://scripts/rite_circle.gd").draw(world,g,c,world.screen(c.marker),false,true,smoothstep(0,.65,c.afterglow))
			continue
		var p=world.screen(c.p)
		if not world.visible_rect().grow(250).has_point(p):continue
		var amount=clampf(c.ritual/RITUAL,0,1) if c.raising else 0.0
		world.draw_set_transform(p,-.16,Vector2(1,.48))
		var shade=1-smoothstep(.05,.4,amount) if c.raising else 1.0
		world.draw_circle(Vector2.ZERO,c.size*1.3*(.65+.35*shade),Color(0,0,0,.4*shade))
		if c.raising:
			var settled=smoothstep(.82,1,amount)
			world.draw_circle(Vector2.ZERO,c.size*.75,Color(0,0,0,.25*settled))
		world.draw_set_transform(Vector2.ZERO)
		if c.identity=="meteor":
			world.prop(2,p,c.size*1.8,Color(.35,.28,.25))
		else:
			var art=corpse_art(c.identity)
			if c.raising:
				preload("res://scripts/rite_animation.gd").runoff(world,c,p,amount,true)
				preload("res://scripts/rite_animation.gd").collapse(world,c,p,amount)
				preload("res://scripts/rite_animation.gd").blood(world,c,p,amount)
				preload("res://scripts/rite_animation.gd").runoff(world,c,p,amount,false)
			else:
				var dimensions=art.get_size()/art.get_width()*c.size*3.2
				world.draw_texture_rect(art,Rect2(p-dimensions*.5,dimensions),false)

		if not enabled(g) or c.identity not in IDENTITIES:continue
		var marker=world.screen(c.marker)
		var blocked=occupied(g,c.identity) or g.companions.units.size()>=g.companions.LIMIT
		preload("res://scripts/rite_circle.gd").draw(world,g,c,marker,blocked)
		if c.raising:
			preload("res://scripts/rite_animation.gd").energy(world,g,c,p)
			preload("res://scripts/rite_animation.gd").assemble(world,c,p,amount)
			preload("res://scripts/rite_animation.gd").mist(world,g,c,p)
