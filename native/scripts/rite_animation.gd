extends RefCounted
const SHEET=preload("res://assets/rite-cast.png")
const HANDS=[Vector2(265,250),Vector2(310,195),Vector2(340,145),Vector2(355,105),Vector2(355,70),Vector2(355,70),Vector2(340,145),Vector2(265,250)]
static var mist_texture:GradientTexture2D
static var fragments={}
const DURATION=12.0
static func split_time(id):return (.12+id*.013)*9.0
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
	var lift=smoothstep(.03,.2,t)*28
	var at=p+offset*(1+spread*1.35-inward*.78)+Vector2(0,-lift-inward*12-spread*18)
	if passage(id,t)>0:at=passage_position(offset,p,passage(id,t))
	return at+drift(id,t)*smoothstep(.025,.1,fold)
static func assembly_join(id,t):
	var order=[4,3,7,6,0,1,8,5,2]
	var start=5.4+order.find(id)*.64
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
static func bone_position(id,p,t,left,dimensions,flesh_dimensions):
	var join=assembly_join(id,t)
	var cell=Vector2(id%3+.5,int(id/3)+.5)
	var ground=p+Vector2(0,-sin(smoothstep(.45,1,t)*PI)*18)
	var destination=ground+Vector2(left,-dimensions.y)+cell*dimensions/3
	var offset=(cell/3-Vector2(.5,.5))*flesh_dimensions
	return orbit_position(offset,p,id,t).lerp(destination,join)+drift(id,t)*(1-join)
static func wisp(canvas,points,strength):
	if strength<=0:return
	canvas.draw_polyline(points,Color(.06,.52,.27,strength*.045),16,true)
	canvas.draw_polyline(points,Color(.16,.81,.46,strength*.15),3.5,true)
	canvas.draw_polyline(points,Color(.53,1,.72,strength*.18),.8,true)
static func part_mist(canvas,c,p,t):
	var flesh=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var flesh_dimensions=flesh.get_size()/flesh.get_width()*c.size*3.2
	var rig=preload("res://scripts/remnant_rig.gd")
	var art=rig.atlas_pose(c.identity,0)
	if art==null:return
	var index=rig.IDS.find(c.identity)
	var factor=(135.0 if c.identity=="basalt" else 105.0)/rig.layouts[index][0][3]
	var left=(rig.layouts[index][0][0]-.5*rig.sheets[c.identity].get_width()/4)*factor
	var dimensions=art.get_size()*factor
	var strength=smoothstep(.04,.15,t)*(1-smoothstep(.78,.98,t))
	for id in range(9):
		var offset=(Vector2(id%3+.5,int(id/3)+.5)/3-Vector2(.5,.5))*flesh_dimensions
		var at=flesh_position(offset,p,id,t) if passage(id,t)<.54 else bone_position(id,p,t,left,dimensions,flesh_dimensions)
		var seed=id*2.399
		# Curling tendrils remain attached to each flesh/bone section.
		for strand in range(2):
			var points=PackedVector2Array()
			for k in range(24):
				var u=k/23.0
				var angle=u*TAU*(.42+.2*sin(seed))+t*DURATION*1.4+seed+strand*2.1
				var radius=7+sin(u*PI)*15+u*14
				points.append(at+Vector2(cos(angle)*radius,sin(angle)*radius*.5+(u-.5)*36)+Vector2(sin(u*9+seed)*5,cos(u*7+seed)*4))
			wisp(canvas,points,strength*.7)
		# An actual motion trail follows the section's previous positions.
		var trail=PackedVector2Array()
		for k in range(16):
			var u=k/15.0
			var past=maxf(0,t-u*.055)
			var point=flesh_position(offset,p,id,past) if passage(id,past)<.54 else bone_position(id,p,past,left,dimensions,flesh_dimensions)
			trail.append(point+Vector2(sin(u*8+t*12+seed),cos(u*9-t*10+seed))*u*8)
		wisp(canvas,trail,strength*.45)
		var puff=Vector2(40,27)
		canvas.draw_texture_rect(mist_texture,Rect2(at-puff*.5,puff),false,Color(.08,.6,.3,strength*.16))
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
	if fold<.04:return 1-pow(1-fold/.04,4)
	return 1-inward_amount(fold)
static func fluid(identity):
	match identity:
		"basalt":return Color(1,.24,.015)
		"aurora":return Color(.35,.8,1)
		"warden":return Color(.48,.39,.055)
		"bloom":return Color(.43,.7,.15)
	return Color(.4,.015,.025)
static func fluid_flight(height,velocity):
	return (-velocity+sqrt(velocity*velocity+2*260*height))/260
static func falling_fluid(canvas,identity,origin,height,velocity,age,seed,ground):
	if age<0:return
	var flight=fluid_flight(height,velocity.y)
	var elapsed=minf(age,flight)
	var at=origin+Vector2(velocity.x*elapsed,velocity.y*elapsed+130*elapsed*elapsed-height)
	var ink=fluid(identity)
	if ground:
		if age<flight:return
		var landed=age-flight
		var fade=1-smoothstep(.3,2.1,landed)
		if fade<=0:return
		canvas.draw_set_transform(at,0,Vector2(1,.38))
		for j in range(5):
			var a=seed+j*2.399
			var radius=2.5+fmod(seed+j,3)
			canvas.draw_circle(Vector2.from_angle(a)*(2+j*.9),radius,Color(ink,fade*.6))
		canvas.draw_set_transform(Vector2.ZERO)
	elif age<flight:
		var trail=Vector2(velocity.x,velocity.y+260*age).normalized()*5
		canvas.draw_line(at-trail,at,Color(ink,.85),1.7,true)
		canvas.draw_circle(at,1.8+fmod(seed,2),Color(ink,.95))
static func runoff(canvas,c,p,t,ground):
	var art=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var dimensions=art.get_size()/art.get_width()*c.size*3.2
	var clock=t*DURATION
	for id in range(9):
		var offset=(Vector2(id%3+.5,int(id/3)+.5)/3-Vector2(.5,.5))*dimensions
		for drop in range(4):
			var emitted=.38+drop*.24+id*.055
			var lift=smoothstep(.03,.2,emitted/DURATION)*28
			var origin=p+offset+Vector2(sin(id*3.1+drop)*12,6)
			falling_fluid(canvas,c.identity,origin,lift+5,Vector2(sin(id+drop)*8,10),clock-emitted,id*7+drop,ground)
		# Launch from each moving section during the sharp outward yank.
		var emitted=split_time(id)+.065
		var fold=fold_amount(id,emitted/DURATION)
		var spread=spread_amount(fold)
		var origin=p+offset*(1+spread*1.35)
		var height=smoothstep(.03,.2,emitted/DURATION)*28+spread*18
		for drop in range(5):
			var velocity=Vector2(offset.x*.6+sin(id*2.7+drop)*45,-25-drop*7)
			falling_fluid(canvas,c.identity,origin,height,velocity,clock-emitted,id*11+drop,ground)
static func fragment(art,col,row,cols,rows,key,soft=true):
	if fragments.has(key):return fragments[key]
	var region=Rect2(art.region.position+Vector2(col,row)*art.region.size/Vector2(cols,rows),art.region.size/Vector2(cols,rows))
	var image=art.atlas.get_image().get_region(Rect2i(region))
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
		var gradient=Gradient.new()
		gradient.offsets=PackedFloat32Array([0,.3,.65,1])
		gradient.colors=PackedColorArray([Color(1,1,1,.8),Color(1,1,1,.55),Color(1,1,1,.12),Color(1,1,1,0)])
		mist_texture=GradientTexture2D.new();mist_texture.gradient=gradient
		mist_texture.width=64;mist_texture.height=64
		mist_texture.fill=GradientTexture2D.FILL_RADIAL
		mist_texture.fill_from=Vector2(.5,.5);mist_texture.fill_to=Vector2(1,.5)
	var t=clampf(c.ritual/DURATION,0,1)
	var veil=smoothstep(.06,.25,t)*(1-smoothstep(.73,.99,t))
	var art=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var dimensions=art.get_size()/art.get_width()*c.size*3.2
	var centre=p+Vector2(0,-lerpf(t*25,65,smoothstep(.38,.7,t)))
	var release=smoothstep(.73,1,t)
	# The transformation happens inside this dense central veil.
	var cover=smoothstep(.15,.23,t)*(1-smoothstep(.46,.57,t))
	for j in range(6):
		var size=Vector2(100,65)
		var at=p+Vector2(sin(g.time*2+j)*14,-48+cos(g.time*1.7+j)*10)
		canvas.draw_texture_rect(mist_texture,Rect2(at-size*.5,size),false,Color(.04,.42,.22,cover*.45))
	# Broad, translucent smoke ribbons wind over and around the body.
	# Each ribbon has a feathered width and a finer luminous filament.
	for j in range(36):
		var points=PackedVector2Array()
		var seed=j*2.399
		var radius=.24+.2*absf(sin(seed*1.7))
		var band=sin(seed*3.17)*dimensions.y*.24
		for k in range(40):
			var u=k/39.0
			var a=u*TAU*(.65+.35*sin(seed*2.3))+seed+g.time*(.5+.12*sin(seed))
			var flow=Vector2(cos(a)*dimensions.x*radius,sin(a)*dimensions.y*.19+band)
			flow+=Vector2(sin(a*2.1+seed-g.time)*22,cos(a*2.7+seed)*13)
			flow.y-=release*(20+u*35)
			flow.x+=release*sin(seed)*18
			points.append(centre+flow)
		for layer in range(4):
			var wide=[29.0,16.0,5.0,.8][layer]
			var alpha=[.065,.085,.085,.08][layer]*veil
			var color=[Color(.035,.36,.2),Color(.08,.58,.33),Color(.2,.82,.51),Color(.57,1,.76)][layer]
			var polygon=PackedVector2Array()
			var colors=PackedColorArray()
			for side in [1,-1]:
				for n in range(40):
					var k=n if side==1 else 39-n
					var u=k/39.0
					var tangent=points[mini(39,k+1)]-points[maxi(0,k-1)]
					var normal=Vector2(-tangent.y,tangent.x).normalized()
					var taper=pow(sin(u*PI),.7)
					polygon.append(points[k]+normal*wide*taper*side*(.6+.4*sin(u*8+seed)))
					colors.append(Color(color,alpha*taper))
			for k in range(39):
				var vertices=PackedVector2Array([polygon[k],polygon[k+1],polygon[78-k],polygon[79-k]])
				var shades=PackedColorArray([colors[k],colors[k+1],colors[78-k],colors[79-k]])
				canvas.draw_primitive(vertices,shades,PackedVector2Array())
		# Soft smoke gathered along the ribbons rather than a separate blob.
		for k in range(3,38,6):
			var size=Vector2(38,22)
			canvas.draw_texture_rect(mist_texture,Rect2(points[k]-size*.5,size),false,Color(.06,.48,.26,veil*.16))
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
	var factor=(135.0 if c.identity=="basalt" else 105.0)/rig.layouts[index][0][3]
	var left=(rig.layouts[index][0][0]-.5*rig.sheets[c.identity].get_width()/4)*factor
	for stream in range(6):
		var id=[0,2,3,5,6,8][stream]
		var offset=(Vector2(id%3+.5,int(id/3)+.5)/3-Vector2(.5,.5))*flesh_dimensions
		var endpoint=flesh_position(offset,p,id,t) if passage(id,t)<.54 else bone_position(id,p,t,left,bone_art.get_size()*factor,flesh_dimensions)
		var points=PackedVector2Array()
		for j in range(25):
			var u=j/24.0
			points.append((start+Vector2((stream%2)*8*flip,(stream%2)*5)).lerp(endpoint,u)+Vector2(sin(u*TAU*1.4-g.time*2+stream)*16,-sin(u*PI)*(30+stream*5))*sin(u*PI))
		wisp(canvas,points,strength*.9)
		for j in range(4):
			var u=fmod(j/15.0+g.time*.45,1)
			var at=points[mini(24,int(u*24))]
			canvas.draw_circle(at,1+sin(u*PI),Color(.24,1,.5,strength*.16))
	for j in range(32):
		var a=j*2.399+g.time*.7
		var at=p+Vector2(cos(a)*65,sin(a)*24-45*t-20*sin(j+g.time*2))
		canvas.draw_circle(at,4+3*sin(j+g.time),Color(.08,.8,.4,strength*.12))

static func collapse(canvas,c,p,t):
	var art=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var dimensions=art.get_size()/art.get_width()*c.size*3.2
	var lift=smoothstep(.03,.2,t)*28
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
	var factor=(135.0 if c.identity=="basalt" else 105.0)/rig.layouts[index][0][3]
	var bounds=rig.layouts[index][0]
	var left=(bounds[0]-.5*rig.sheets[c.identity].get_width()/4.0)*factor
	var dimensions=art.get_size()*factor
	var ground=p+Vector2(0,-sin(smoothstep(.45,1,t)*PI)*18)
	var solid=smoothstep(.94,.99,t)
	# Each section emerges from the far side of the same passage as its flesh.
	var corpse=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var flesh_dimensions=corpse.get_size()/corpse.get_width()*c.size*3.2
	var order=[4,3,7,6,0,1,8,5,2]
	for id in order:
		var col=id%3;var row=int(id/3)
		var join=assembly_join(id,t)
		var travel=passage(id,t)
		var revealed=smoothstep(.54,.66,travel)
		if revealed<=0:continue
		var piece=fragment(art,col,row,3,3,"passing-bone"+c.identity+str(id))
		var size=dimensions/Vector2(3,3)
		var destination=ground+Vector2(left,-dimensions.y)+(Vector2(col,row)+Vector2(.5,.5))*size
		var offset=(Vector2(col+.5,row+.5)/3-Vector2(.5,.5))*flesh_dimensions
		var emerged=passage_position(offset,p,travel)
		var at=bone_position(id,p,t,left,dimensions,flesh_dimensions)
		canvas.draw_set_transform(at,(sin(id*1.9)*.65+tumble(id,t))*(1-join),Vector2.ONE)
		canvas.draw_texture_rect(piece,Rect2(-size*.5,size),false,Color(.7+join*.3,1,.78+join*.22,revealed*(1-solid)))
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
		var lift=smoothstep(.03,.2,t)*28
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
		canvas.draw_polyline(tear,Color(fluid(c.identity),fade*.65),3,true)
