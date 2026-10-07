extends RefCounted
const SHEET=preload("res://assets/rite-cast.png")
const HANDS=[Vector2(265,250),Vector2(310,195),Vector2(340,145),Vector2(355,105),Vector2(355,70),Vector2(355,70),Vector2(340,145),Vector2(265,250)]
static var mist_texture:Texture2D
static var fragments={}
static var surfaces={}
static var hide_textures={}
static var hide_images={}
static var blood_stamps={}
static func surface(identity,id):
	if not surfaces.has(identity):
		var image=preload("res://scripts/remnant_system.gd").corpse_art(identity).get_image()
		var cells=[]
		for section in range(9):cells.append([])
		for y in range(0,image.get_height(),8):
			for x in range(0,image.get_width(),8):
				if image.get_pixel(x,y).a<.5:continue
				var section=mini(2,int(float(y)/image.get_height()*3))*3+mini(2,int(float(x)/image.get_width()*3))
				cells[section].append(Vector2(float(x)/image.get_width()-.5,float(y)/image.get_height()-.5))
		surfaces[identity]=cells
	return surfaces[identity][id]
const DURATION=18.0
static func lift_amount(clock):return smoothstep(2.5,4.5,clock)*40
static func split_time(id):return 7.08+id*.065
static func fold_amount(id,t):return clampf((t*DURATION-split_time(id))/2.34,0,1)
static func inward_amount(fold):return smoothstep(.2,1,fold)
static func passage(id,t):return clampf((t*DURATION-split_time(id)-.468)/1.7,0,1)
static func drift(id,t):
	var clock=t*DURATION
	var seed=id*2.399
	return Vector2(sin(clock*1.7+seed)*7+sin(clock*3.1+seed*.7)*2,cos(clock*2.1+seed)*6)
static func tumble(id,t):return sin(t*DURATION*1.8+id*2.399)*.13+cos(t*DURATION*2.7+id)*.045
static func flesh_position(offset,p,id,t):
	var fold=fold_amount(id,t)
	var spread=spread_amount(fold)
	var inward=inward_amount(fold)
	var lift=lift_amount(t*DURATION)
	var at=p+offset*(1+spread*1.35-inward*.78)+Vector2(0,-lift-inward*12-spread*18)
	if passage(id,t)>0:at=passage_position(offset,p,passage(id,t))
	return at+drift(id,t)*smoothstep(.025,.1,fold)
static func assembly_order(identity):
	return {"thorn":[2,5,8,4,7,6,3,1,0],"basalt":[7,6,4,3,0,1,8,5,2],"hunt":[7,4,6,3,1,0,8,5,2],"aurora":[7,4,3,6,0,1,8,5,2],"warden":[7,4,1,0,3,6,8,5,2],"bloom":[4,1,0,3,6,7,8,5,2]}.get(identity,[4,3,7,6,0,1,8,5,2])
static func assembly_join(id,t,identity="thorn"):
	var order=assembly_order(identity)
	var start=11.4+order.find(id)*.64
	return smoothstep(start,start+.52,t*DURATION)
static func orbit_position(offset,p,id,t):
	var at=passage_position(offset,p,passage(id,t))
	var age=maxf(0,t*DURATION-split_time(id)-.468-1.7)
	# Accelerate smoothly out of the passage into a projected circular swirl.
	var angle=(.95+.12*sin(id*2.399))*(age-.22*(1-exp(-age/.22)))
	var pivot=p+Vector2(0,-65)
	var projection=Vector2(1,.65)
	var swirl=((at-pivot)/projection).rotated(angle)*projection
	var seed=id*2.399
	var weaving=Vector2(sin(age*2.1+seed)-sin(seed),cos(age*1.6+seed)-cos(seed))*12
	return pivot+swirl+weaving*smoothstep(0,.3,age)
static func bone_position(id,p,t,left,dimensions,flesh_dimensions,identity="thorn"):
	var join=assembly_join(id,t,identity)
	var cell=Vector2(id%3+.5,int(id/3)+.5)
	var ground=p+Vector2(0,-sin(smoothstep(.45,1,t)*PI)*18)
	var destination=ground+Vector2(left,-dimensions.y)+cell*dimensions/3
	var offset=(cell/3-Vector2(.5,.5))*flesh_dimensions
	return orbit_position(offset,p,id,t).lerp(destination,join)+drift(id,t)*(1-join)
static func wisp(canvas,points,strength):
	if strength<=0:return
	canvas.draw_polyline(points,Color(.06,.52,.27,strength*.045),16,false)
	canvas.draw_polyline(points,Color(.16,.81,.46,strength*.15),3.5,false)
	canvas.draw_polyline(points,Color(.53,1,.72,strength*.18),.8,false)
static func part_mist(canvas,c,p,t):
	var flesh=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var flesh_dimensions=flesh.get_size()/flesh.get_width()*c.size*3.2
	var rig=preload("res://scripts/remnant_rig.gd")
	var art=rig.atlas_pose(c.identity,0)
	if art==null:return
	var index=rig.IDS.find(c.identity)
	var factor=rig.height(c.identity)/rig.layouts[index][0][3]
	var left=(rig.layouts[index][0][0]-.5*rig.sheets[c.identity].get_width()/4)*factor
	var dimensions=art.get_size()*factor
	var strength=smoothstep(.04,.15,t)*(1-smoothstep(.78,.98,t))
	for id in range(9):
		var offset=(Vector2(id%3+.5,int(id/3)+.5)/3-Vector2(.5,.5))*flesh_dimensions
		var at=flesh_position(offset,p,id,t) if passage(id,t)<.54 else bone_position(id,p,t,left,dimensions,flesh_dimensions,c.identity)
		var seed=id*2.399
		# Soft clouds follow the moving sections, with no hard luminous strands.
		for cloud in range(3):
			var angle=seed+cloud*2.1+t*DURATION*.8
			var puff=Vector2(96,66)*(1.0+.18*sin(angle))
			var cloud_at=at+Vector2(cos(angle)*16,sin(angle)*12)
			canvas.draw_texture_rect(mist_texture,Rect2(cloud_at-puff*.5,puff),false,Color(.14,.66,.37,strength*.42*(1-smoothstep(.45,.66,passage(id,t))*.78)))
static func passage_position(offset,p,u):
	var start=p+offset*2.35+Vector2(0,-46)
	var centre=p+Vector2(0,-48)
	var exit=p-offset*2.4+Vector2(0,-100)
	var normal=Vector2(-offset.y,offset.x).normalized()
	if offset.length_squared()<1:normal=Vector2.RIGHT
	if u<.5:
		var v=pow(u*2,1.7)
		var control=start.lerp(centre,.22)+normal*38
		return start.lerp(control,v).lerp(control.lerp(centre,v),v)
	var v=1-pow(1-(u-.5)*2,2)
	var control=centre.lerp(exit,.72)-normal*48
	return centre.lerp(control,v).lerp(control.lerp(exit,v),v)
static func spread_amount(fold):
	# Yank in 94 ms, hold apart for 374 ms, then pool inward.
	if fold<.03:return 1-pow(1-fold/.03,5)
	return 1-inward_amount(fold)
static func fluid(identity):
	match identity:
		"basalt":return Color(.46,.018,.022)
		"aurora":return Color(.42,.015,.025)
		"warden":return Color(.38,.012,.02)
		"bloom":return Color(.44,.02,.018)
	return Color(.4,.015,.025)
static func fluid_flight(height,velocity):
	return (-velocity+sqrt(velocity*velocity+2*260*height))/260
static func blood_stamp(identity,variant):
	var key=identity+str(variant)
	if blood_stamps.has(key):return blood_stamps[key]
	var image=Image.create(48,48,false,Image.FORMAT_RGBA8)
	var ink=fluid(identity)
	for y in range(48):
		for x in range(48):
			var alpha=0.0
			var uv=(Vector2(x,y)-Vector2(24,24))/24.0
			for lobe in range(5):
				var centre=Vector2.from_angle(variant+lobe*2.399)*(.09+lobe*.055)
				var radius=.31+fmod(variant+lobe,4)*.045
				alpha=maxf(alpha,(1-smoothstep(radius*.6,radius*1.4,uv.distance_to(centre)))*.58)
			image.set_pixel(x,y,Color(ink*.65,alpha))
	var texture=ImageTexture.create_from_image(image);blood_stamps[key]=texture;return texture
static func falling_fluid(canvas,identity,origin,height,velocity,age,seed,ground):
	if age<0:return
	var flight=fluid_flight(height,velocity.y)
	var elapsed=minf(age,flight)
	var at=origin+Vector2(velocity.x*elapsed,velocity.y*elapsed+130*elapsed*elapsed-height)
	var ink=fluid(identity)
	if ground:
		if age<flight:return
		var fade=1.0
		var stamp=blood_stamp(identity,int(seed)%4)
		var size=Vector2(26,12)
		canvas.draw_texture_rect(stamp,Rect2(at-size*.5,size),false)
	elif age<flight:
		var trail=Vector2(velocity.x,velocity.y+260*age).normalized()*5
		canvas.draw_line(at-trail,at,Color(ink,.85),1.7,true)
		canvas.draw_circle(at,1.8+fmod(seed,2),Color(ink,.95))
static func runoff(canvas,c,p,t,ground):
	var art=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var dimensions=art.get_size()/art.get_width()*c.size*3.2
	var clock=t*DURATION
	for id in range(9):
		var points=surface(c.identity,id)
		if points.is_empty():continue
		var offset=points[(id*31)%points.size()]*dimensions
		for drop in range(4):
			var emitted=.38+drop*.24+id*.055
			var lift=lift_amount(emitted)
			var origin=p+points[(id*31+drop*67)%points.size()]*dimensions+Vector2(0,6)
			falling_fluid(canvas,c.identity,origin,lift+5,Vector2(sin(id+drop)*8,10),clock-emitted,id*7+drop,ground)
		# Launch from each moving section during the sharp outward yank.
		var emitted=split_time(id)+.065
		var fold=fold_amount(id,emitted/DURATION)
		var spread=spread_amount(fold)
		var origin=p+offset*(1+spread*1.35)
		var height=lift_amount(emitted)+spread*18
		for drop in range(5):
			var velocity=Vector2(offset.x*.6+sin(id*2.7+drop)*45,-25-drop*7)
			var scatter=Vector2(sin(id*1.79+drop*2.399)*16,cos(id*2.73+drop*1.71)*24)
			falling_fluid(canvas,c.identity,origin+scatter,height,velocity,clock-emitted,id*11+drop,ground)
static func hide_scrap(identity,id,flake):
	var key=identity+":"+str(id)+":"+str(flake)
	if hide_textures.has(key):return hide_textures[key]
	if not hide_images.has(identity):
		hide_images[identity]=preload("res://scripts/remnant_system.gd").corpse_art(identity).get_image()
	var original=hide_images[identity]
	# Sample the torso's own exterior, not horns, feet or neighbouring atlas poses.
	var candidates=surface(identity,4)
	if candidates.is_empty():candidates=surface(identity,id)
	var centre=(candidates[(id*31+flake*67)%candidates.size()]+Vector2(.5,.5))*Vector2(original.get_size())
	var feathered=identity in ["aurora","warden"]
	var image=Image.create(48,48,false,Image.FORMAT_RGBA8)
	var seed=id*2.399+flake*1.71
	for y in range(48):
		for x in range(48):
			var uv=(Vector2(x,y)-Vector2(23.5,23.5))/23.5
			var shape=Vector2(uv.x*(2.3 if feathered else 1.0),uv.y)
			var angle=atan2(shape.y,shape.x)
			var rim=.82+.09*sin(angle*5+seed)+.06*sin(angle*9-seed)
			var alpha=1-smoothstep(rim-.09,rim,shape.length())
			if alpha<=0:continue
			var sample=centre+Vector2(x-24,y-24)*1.4
			var pixel=original.get_pixel(clampi(int(sample.x),0,original.get_width()-1),clampi(int(sample.y),0,original.get_height()-1))
			var stain=smoothstep(.35,.85,sin(uv.x*4+uv.y*3+seed))*.32
			pixel=pixel.lerp(fluid(identity),stain)
			pixel.a=original.get_pixel(clampi(int(sample.x),0,original.get_width()-1),clampi(int(sample.y),0,original.get_height()-1)).a*alpha
			# Fine barbs keep feather scraps legible while retaining species colours.
			if feathered:
				pixel.a*=.72+.28*abs(sin(y*1.7+abs(uv.x)*8))
			image.set_pixel(x,y,pixel)
	var texture=ImageTexture.create_from_image(image)
	hide_textures[key]=texture
	return texture
static func scrap_flight(c,id,flake):
	if not c.has("scrap_flights"):c.scrap_flights={}
	var key=id*3+flake
	if c.scrap_flights.has(key):return c.scrap_flights[key]
	var art=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var dimensions=art.get_size()/art.get_width()*c.size*3.2
	var seed=id*2.399+flake*1.71+c.get("ritual_seed",0.0)
	var emitted=split_time(id)+1.05+flake*.19+.09*sin(seed)
	var offset=(Vector2(id%3+.5,int(id/3)+.5)/3-Vector2(.5,.5))*dimensions
	var source=flesh_position(offset,Vector2.ZERO,id,emitted/DURATION)
	var before=flesh_position(offset,Vector2.ZERO,id,(emitted-.025)/DURATION)
	var after=flesh_position(offset,Vector2.ZERO,id,(emitted+.025)/DURATION)
	var inherited=((after-before)/.05).limit_length(240)
	var radial=(source+Vector2(0,45)).normalized().rotated(sin(seed)*.5)
	if radial.length_squared()<.1:radial=Vector2.from_angle(seed)
	var plane=inherited*.65+radial*(85+flake*22)+Vector2.from_angle(seed)*28
	var height=55+flake*14
	var velocity=Vector2(0,-45-flake*12)
	var flight=fluid_flight(height,velocity.y)
	var record={"emitted":emitted,"source":source,"plane":plane,"height":height,"velocity":velocity,"flight":flight,"seed":seed}
	c.scrap_flights[key]=record
	return record
static func shedding(canvas,c,p,t,ground):
	for id in range(9):
		if surface(c.identity,id).is_empty():continue
		for flake in range(3):
			var motion=scrap_flight(c,id,flake)
			var age=t*DURATION-motion.emitted
			if age<0:continue
			var elapsed=minf(age,motion.flight)
			var source=p+motion.source
			var at=source+motion.plane*elapsed+Vector2(0,motion.velocity.y*elapsed+130*elapsed*elapsed)
			var size=Vector2(30+flake*4,24+flake*3)
			var texture=hide_scrap(c.identity,id,flake)
			falling_fluid(canvas,c.identity,source+motion.plane*elapsed+Vector2(0,motion.height),motion.height,motion.velocity,age,id*13+flake,ground)
			if ground and age>=motion.flight:
				canvas.draw_set_transform(at,motion.seed+motion.flight*4,Vector2(1,.48))
				canvas.draw_texture_rect(texture,Rect2(-size*.5,size),false,Color(.78,.72,.68,.92))
				canvas.draw_set_transform(Vector2.ZERO)
			elif not ground and age<motion.flight:
				canvas.draw_set_transform(at,motion.seed+age*4,Vector2(.45+.55*abs(cos(age*7+motion.seed)),1))
				canvas.draw_texture_rect(texture,Rect2(-size*.5,size),false)
				canvas.draw_set_transform(Vector2.ZERO)
			var impact_age=age-motion.flight
			if impact_age>=0:
				var landing=source+motion.plane*motion.flight+Vector2(0,motion.height)
				for drop in range(3):
					var splash_velocity=Vector2(sin(motion.seed+drop*2.399)*35,-20-drop*3)
					falling_fluid(canvas,c.identity,landing,0,splash_velocity,impact_age,id*17+drop,ground)
static func fragment(art,col,row,cols,rows,key,soft=true):
	if fragments.has(key):return fragments[key]
	# Both corpse and skeletal poses can be standalone textures.
	# Extract from the rendered pose, never assume an atlas backing texture.
	var source=art.get_image()
	var cell=Vector2(source.get_size())/Vector2(cols,rows)
	var image=source.get_region(Rect2i(Vector2(col,row)*cell,cell))
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel=image.get_pixel(x,y)
			var edge=1.0
			if col>0:edge*=smoothstep(0,5,x)
			if col<cols-1:edge*=smoothstep(0,5,image.get_width()-1-x)
			if row>0:edge*=smoothstep(0,5,y)
			if row<rows-1:edge*=smoothstep(0,5,image.get_height()-1-y)
			pixel.a*=edge if soft else 1.0;image.set_pixel(x,y,pixel)
	var texture=ImageTexture.create_from_image(image);fragments[key]=texture;return texture
static func mist(canvas,g,c,p):
	if mist_texture==null:
		# Cache one irregular, feathered cloud; reuse it for every boss and frame.
		var noise=FastNoiseLite.new()
		noise.seed=7419;noise.frequency=.055;noise.fractal_octaves=3
		var image=Image.create(128,128,false,Image.FORMAT_RGBA8)
		for y in range(128):
			for x in range(128):
				var uv=(Vector2(x,y)-Vector2(63.5,63.5))/63.5
				var cloud=clampf(.62+noise.get_noise_2d(x,y)*.65,0,1)
				var edge=1-smoothstep(.18,1.0,uv.length())
				image.set_pixel(x,y,Color(1,1,1,cloud*edge))
		mist_texture=ImageTexture.create_from_image(image)
	var t=clampf(c.ritual/DURATION,0,1)
	var veil=smoothstep(.06,.25,t)*(1-smoothstep(.73,.99,t))
	var art=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var dimensions=art.get_size()/art.get_width()*c.size*3.2
	part_mist(canvas,c,p,t)
static func active(g):
	for c in g.boss_corpses:
		if not c.consumed and (c.raising or c.charge>0):return c
	return null
static func phase(c):
	if not c.raising:return clampf(c.charge/2.5,0,1)*3
	var t=c.ritual/DURATION
	return 3+t*3 if t<.33 else 4.0+sin(t*8)*.15 if t<.8 else 5+(t-.8)*10
static func caster(canvas,p,g,tint):
	var c=active(g)
	if c==null:return false
	var f=clampf(phase(c),0,7)
	var flip=-1.0 if c.p.x<g.pos.x else 1.0
	var cell=Vector2(SHEET.get_width()/4.0,SHEET.get_height()/2.0)
	canvas.draw_set_transform(p,0,Vector2(flip,1))
	for frame in [int(f),mini(7,int(f)+1)]:
		var weight=1-fmod(f,1) if frame==int(f) else fmod(f,1)
		if frame==7:weight=1
		canvas.draw_texture_rect_region(SHEET,Rect2(-45,-88,90,90),Rect2(Vector2(frame%4,int(frame/4))*cell,cell),Color(tint,weight))
		if frame==7:break
	canvas.draw_set_transform(Vector2.ZERO)
	return true
static func energy(canvas,g,c,p):
	var t=clampf(c.ritual/DURATION,0,1)
	var strength=smoothstep(0,.18,t)*(1-smoothstep(.86,1,t))
	var f=clampf(phase(c),0,7)
	var hand=HANDS[int(f)].lerp(HANDS[mini(7,int(f)+1)],fmod(f,1))
	var flip=-1.0 if c.p.x<g.pos.x else 1.0
	var start=canvas.screen(g.pos)+Vector2((hand.x/443.5*90-45)*flip,hand.y/443.5*90-88)
	var flesh=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var flesh_dimensions=flesh.get_size()/flesh.get_width()*c.size*3.2
	var rig=preload("res://scripts/remnant_rig.gd")
	var bone_art=rig.atlas_pose(c.identity,0)
	var index=rig.IDS.find(c.identity)
	var factor=rig.height(c.identity)/rig.layouts[index][0][3]
	var left=(rig.layouts[index][0][0]-.5*rig.sheets[c.identity].get_width()/4)*factor
	for id in range(9):
		var launch=preload("res://scripts/ritual_parchment.gd").launch_time(id)
		var travel=clampf((c.ritual-launch)/.85,0,1)
		if travel<=0:continue
		var offset=(Vector2(id%3+.5,int(id/3)+.5)/3-Vector2(.5,.5))*flesh_dimensions
		var at=flesh_position(offset,p,id,t) if passage(id,t)<.54 else bone_position(id,p,t,left,bone_art.get_size()*factor,flesh_dimensions,c.identity)
		var endpoint=preload("res://scripts/ritual_parchment.gd").path(at,id,c.ritual,p,flesh_dimensions)[0]
		var points=PackedVector2Array()
		for j in range(33):
			var u=j/32.0*travel
			points.append(start.lerp(endpoint,u)+Vector2(sin(u*TAU*1.4-g.time*2+id)*16,-sin(u*PI)*(30+id*3))*sin(u*PI))
		preload("res://scripts/ritual_parchment.gd").ribbon(canvas,points,13+id%2*2,(1-smoothstep(.86,1,t)),g.time+id)

static func collapse(canvas,c,p,t):
	var art=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var dimensions=art.get_size()/art.get_width()*c.size*3.2
	var lift=lift_amount(t*DURATION)
	# Staggered flesh sections fold toward the chest while suspended.
	for row in range(3):
		for col in range(3):
			var id=row*3+col
			var fold=fold_amount(id,t)
			var region=fragment(art,col,row,3,3,"corpse"+c.identity+str(id))
			var whole=fragment(art,col,row,3,3,"uncut"+c.identity+str(id),false)
			var offset=(Vector2(col+.5,row+.5)/3-Vector2(.5,.5))*dimensions
			var spread=spread_amount(fold)
			var inward=inward_amount(fold)
			var at=flesh_position(offset,p,id,t)
			var travel=passage(id,t)
			var floating=smoothstep(.025,.1,fold)
			var fade=1-smoothstep(.42,.54,travel)
			canvas.draw_set_transform(at,sin(id*2.1)*(inward*.6+spread*.4)+tumble(id,t)*floating,Vector2.ONE*(1-inward*.5))
			var edge=smoothstep(0,.08,fold)
			canvas.draw_texture_rect(whole,Rect2(-dimensions/6,dimensions/3),false,Color(1,1,1,fade*(1-edge)))
			canvas.draw_texture_rect(region,Rect2(-dimensions/6,dimensions/3),false,Color(1,1,1,fade*edge))
	canvas.draw_set_transform(Vector2.ZERO)
static func assemble(canvas,c,p,t):
	var rig=preload("res://scripts/remnant_rig.gd")
	var art=rig.atlas_pose(c.identity,0)
	if art==null:return
	var index=rig.IDS.find(c.identity)
	var factor=rig.height(c.identity)/rig.layouts[index][0][3]
	var bounds=rig.layouts[index][0]
	var left=(bounds[0]-.5*rig.sheets[c.identity].get_width()/4.0)*factor
	var dimensions=art.get_size()*factor
	var ground=p+Vector2(0,-sin(smoothstep(.45,1,t)*PI)*18)
	var solid=smoothstep(.94,.99,t)
	# Each section emerges from the far side of the same passage as its flesh.
	var corpse=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var flesh_dimensions=corpse.get_size()/corpse.get_width()*c.size*3.2
	var order=assembly_order(c.identity)
	for id in order:
		var col=id%3;var row=int(id/3)
		var join=assembly_join(id,t,c.identity)
		var travel=passage(id,t)
		var revealed=smoothstep(.54,.66,travel)
		if revealed<=0:continue
		var piece=fragment(art,col,row,3,3,"passing-bone"+c.identity+str(id))
		var size=dimensions/Vector2(3,3)
		var destination=ground+Vector2(left,-dimensions.y)+(Vector2(col,row)+Vector2(.5,.5))*size
		var offset=(Vector2(col+.5,row+.5)/3-Vector2(.5,.5))*flesh_dimensions
		var emerged=passage_position(offset,p,travel)
		var at=bone_position(id,p,t,left,dimensions,flesh_dimensions,c.identity)
		canvas.draw_set_transform(at,(sin(id*1.9)*.65+tumble(id,t))*(1-join),Vector2.ONE)
		canvas.draw_texture_rect(piece,Rect2(-size*.5,size),false,Color(.9+join*.1,1,.9+join*.1,revealed*(1-solid)))
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_texture_rect(art,Rect2(ground+Vector2(left,-dimensions.y),dimensions),false,Color(1,1,1,solid))
static func blood(canvas,c,p,t):
	var dimensions=preload("res://scripts/remnant_system.gd").corpse_art(c.identity).get_size()
	dimensions=dimensions/dimensions.x*c.size*3.2
	var clock=t*DURATION
	for seam in range(12):
		var vertical=seam<6
		var n=seam if vertical else seam-6
		var row=int(n/2) if vertical else int(n/3)+1
		var col=n%2+1 if vertical else n%3
		var id=row*3+col
		var age=clock-split_time(id)
		if age<0 or age>1.1:continue
		var fold=fold_amount(id,t)
		var local=Vector2(col/3.0-.5,(row+.5)/3.0-.5) if vertical else Vector2((col+.5)/3.0-.5,row/3.0-.5)
		var lift=lift_amount(t*DURATION)
		var spread=spread_amount(fold)
		var inward=inward_amount(fold)
		var origin=p+local*dimensions*(1+spread*1.35-inward*.78)+Vector2(0,-lift-inward*12-spread*18)
		origin+=drift(id,t)*smoothstep(.025,.1,fold)
		var tangent=Vector2.DOWN if vertical else Vector2.RIGHT
		var normal=Vector2.RIGHT if vertical else Vector2.UP
		var fade=1-smoothstep(.4,1.1,age)
		for j in range(9):
			var sign_value=1 if j%2==0 else -1
			var v=normal*sign_value*(18+j*3)+Vector2(0,-12-j*2)
			var along=tangent*(j-4)*dimensions.y/36.0
			var at=origin+along+v*age+Vector2(0,age*age*36)
			var ink=Color(fluid(c.identity),fade*.9)
			if c.identity=="hunt" and j%4==0:ink=Color(.5,.78,.9,fade*.65)
			if c.identity in ["basalt","aurora","bloom"]:
				canvas.draw_circle(at,4+j%3,Color(ink,fade*.12))
			canvas.draw_line(at-v.normalized()*(3+j%3),at,ink,1.4+j%2,true)
			canvas.draw_circle(at,1.2+j%3*.55,ink)
		var tear=PackedVector2Array()
		for j in range(9):tear.append(origin+tangent*(j-4)*dimensions.y/36.0+normal*sin(j*2.7+seam)*3)
		canvas.draw_polyline(tear,Color(fluid(c.identity),fade*.65),3,false)
