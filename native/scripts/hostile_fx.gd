extends RefCounted
const SHEET = preload("res://assets/hostile-fx-06.png")
static var meteor_fissures:Texture2D
static var meteor_rock_views:Array[Texture2D]=[]
static var seismic_earth:Texture2D
static var meteor_rubble_strip:Texture2D

static func load_meteor_rubble():
	if meteor_rubble_strip==null:
		var source="res://assets/boss-public/effects/meteor-rupture-strip-v1.png"
		var image=(load(source) as Texture2D).get_image()
		if image==null:return false
		image=image.get_region(image.get_used_rect())
		image.resize(1024,maxi(1,roundi(1024.0*image.get_height()/image.get_width())),Image.INTERPOLATE_LANCZOS)
		meteor_rubble_strip=ImageTexture.create_from_image(image)
	return true

static func prewarm_meteor():
	# Prepare disk-backed artwork before combat, never during a first strike.
	load_meteor_rocks()
	load_meteor_rubble()
	load_meteor_fissures()

static func draw_meteor_rubble_strip(canvas,h,p):
	if "--meteor-legacy-rubble-review" in OS.get_cmdline_user_args():return false
	if not load_meteor_rubble():return false
	var start=h.angle-h.arc*.5
	# Each strip bends with the footprint rather than rotating flat sprites.
	# Slight overlap joins the naturally ragged transparent ends.
	var sections=8
	for section in range(sections):
		var points=PackedVector2Array();var uv=PackedVector2Array();var colors=PackedColorArray()
		for edge in range(2):
			for sample in range(9):
				var u=float(sample)/8 if edge==0 else 1-float(sample)/8
				var fraction=clampf((section+u*1.06-.03)/sections,0,1)
				var angle=start+fraction*h.arc
				var taper=clampf(minf(fraction,1-fraction)*20,0,1)
				# Add stone mass behind the advancing edge, preserving its reach.
				var radius=h.radius-12+(30 if edge==0 else -65)*taper
				points.append(p+Vector2.from_angle(angle)*radius-Vector2(0,14*taper))
				uv.append(Vector2(u,edge))
				colors.append(Color(1.07,1.02,.94,.95*taper))
		canvas.draw_polygon(points,colors,uv,meteor_rubble_strip)
	return true

static func load_meteor_rocks():
	if meteor_rock_views.is_empty():
		for view in ["front-positive-z","three-quarter","side-positive-x","back-negative-z","side-negative-x","game-camera"]:
			var source="res://assets/boss-public/effects/"+view+".png"
			var image=(load(source) as Texture2D).get_image()
			if image==null:return false
			image.resize(128,128,Image.INTERPOLATE_LANCZOS)
			meteor_rock_views.append(ImageTexture.create_from_image(image))
	return true

static func textured_meteor_burst(canvas,h,p):
	if not load_meteor_rocks():return false
	var duration=.35 if h.get("meteor_eruption",false) else .5
	var age=clampf(1-h.life/duration,0,1)
	textured_meteor_warning(canvas,h,p,1-age*.35)
	# Authored dimensional stone fragments rise and fall over the footprint.
	# Fixed identities keep the burst continuous rather than flickering noise.
	for index in range(9):
		var angle=index*TAU/9+sin(index*7.1)*.32+h.p.x*.013
		var direction=Vector2.from_angle(angle)
		var ground=p+direction*h.radius*(.18+age*.58)
		var lift=sin(age*PI)*(18+index%3*9)
		var size=20+index%4*5
		canvas.draw_set_transform(ground,0,Vector2(1,.38))
		canvas.draw_circle(Vector2.ZERO,size*.30,Color(.025,.020,.015,.2*(1-age*.4)))
		canvas.draw_set_transform(ground-Vector2(0,lift),angle+age*(index%3-1)*1.2)
		canvas.draw_texture_rect(meteor_rock_views[index%6],Rect2(-Vector2.ONE*size*.5,Vector2.ONE*size),false,Color(1.15,1.05,.95,1-age*.35))
		canvas.draw_set_transform(Vector2.ZERO)
	return true

static func load_meteor_fissures():
	if meteor_fissures==null:
		var source="res://assets/boss-public/effects/meteor-ground-fissures-v1.png"
		var image=(load(source) as Texture2D).get_image()
		if image==null:return false
		image.resize(512,512,Image.INTERPOLATE_LANCZOS)
		meteor_fissures=ImageTexture.create_from_image(image)
	return true

static func textured_meteor_warning(canvas,h,p,progress):
	if not load_meteor_fissures():return false
	# Clip artwork to the actual damage circle. Texture coordinates rotate
	# deterministically per strike rather than identical symbols at each point.
	var points=PackedVector2Array();var uv=PackedVector2Array()
	var rotation=fposmod(h.p.x*.017+h.p.y*.023,TAU)
	var scorched=PackedVector2Array()
	for index in range(64):
		var direction=Vector2.from_angle(index*TAU/64)
		points.append(p+direction*h.radius)
		uv.append(Vector2.ONE*.5+direction.rotated(rotation)*.46)
		# Small inward chips preserve the true reach while breaking the
		# silhouette of the burnt ground, rather than outlining it as UI.
		var inset=absf(sin(index*2.3+rotation)*2.2+sin(index*5.1)*1.1)
		scorched.append(p+direction*(h.radius-inset))
	var inner=PackedVector2Array()
	var soil=Color(.055,.035,.018,.22+progress*.10)
	for vertex in scorched:inner.append(p+(vertex-p).normalized()*maxf(0,(vertex-p).length()-6))
	if not h.has("warning_soil_mesh"):
		var vertices=PackedVector3Array([Vector3.ZERO]);var colors=PackedColorArray([Color(.055,.035,.018,.32)]);var indices=PackedInt32Array()
		for ring in [inner,scorched]:
			for point in ring:
				var local=point-p
				vertices.append(Vector3(local.x,local.y,0))
				colors.append(Color(.055,.035,.018,.32 if ring==inner else 0.0))
		for index in range(64):
			var next=(index+1)%64
			indices.append_array(PackedInt32Array([0,1+index,1+next,1+index,65+index,65+next,1+index,65+next,1+next]))
		var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
		var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);h.warning_soil_mesh=mesh
	canvas.draw_mesh(h.warning_soil_mesh,null,Transform2D(0,p),Color(1,1,1,soil.a/.32))
	canvas.draw_polygon(points,PackedColorArray([Color(1.6,1.3,1.1,.65+progress*.35)]),uv,meteor_fissures)
	return true

static func piece(canvas,index,p,dimensions,angle = 0.0,alpha = 1.0):
	var cell = Vector2(SHEET.get_size())/Vector2(3,2)
	var source = Rect2(Vector2(index%3,floori(float(index)/3))*cell+Vector2.ONE*5,cell-Vector2.ONE*10)
	canvas.draw_set_transform(p,angle)
	canvas.draw_texture_rect_region(SHEET,Rect2(-dimensions/2,dimensions),source,Color(1,1,1,alpha))
	canvas.draw_set_transform(Vector2.ZERO)

static func textured_meteor_ridge(canvas,h,p):
	if not load_meteor_rocks():return false
	var start=h.angle-h.arc*.5
	var end=start+h.arc
	# A continuous fractured base joins the debris without extending the
	# damaging front into the safe opening. Its width tapers at both ends.
	var base=PackedVector2Array()
	var inner=PackedVector2Array()
	var ash_colors=PackedColorArray()
	for index in range(97):
		var fraction=float(index)/96
		var angle=start+fraction*h.arc
		var taper=clampf(minf(fraction,1-fraction)*16,0,1)
		var grit=(sin(angle*31)*3+sin(angle*67)*1.5)*taper
		base.append(p+Vector2.from_angle(angle)*(h.radius+grit))
		ash_colors.append(Color(.11,.095,.075,.16*taper))
		inner.append(p+Vector2.from_angle(angle)*(h.radius-(23+sin(angle*23)*5)*taper))
	for index in range(inner.size()-1,-1,-1):
		base.append(inner[index]);ash_colors.append(Color(.11,.095,.075,0))
	canvas.draw_polygon(base,ash_colors)
	# Ash trails inward; the outer face remains at the committed hit front.
	for wake in range(5):
		meteor_ground_front(canvas,p,h.radius-5-wake*6,start,end,Color(.16,.125,.085,.055-wake*.01),10+wake*3,1.8)
	if draw_meteor_rubble_strip(canvas,h,p):return true
	# Overlapping rendered fragments form a broken, dimensional ridge.
	# Fixed angular identities prevent changes of radius from remapping rocks.
	# Small collapsed material fills the inner foot of the rupture, rather
	# than leaving evenly spaced, isolated stones hanging above the ground.
	for index in range(36):
		var fraction=(index+.5)/36.0
		var angle=start+fraction*h.arc
		var direction=Vector2.from_angle(angle)
		var at=p+direction*(h.radius-21+sin(index*3.9)*4)
		var taper=clampf(minf(fraction,1-fraction)*24,0,1)
		var width=clampf(h.radius*h.arc/36.0*1.7,18,86)
		canvas.draw_set_transform(at,0,Vector2(1,.55))
		for layer in range(5):canvas.draw_circle(Vector2.ZERO,width*(.65-layer*.09),Color(.13,.10,.065,.045*taper))
		canvas.draw_set_transform(at-Vector2(0,5),sin(index*4.3)*.3)
		canvas.draw_texture_rect(meteor_rock_views[(index+3)%6],Rect2(-Vector2(width,24)*.5,Vector2(width,24)),false,Color(.8,.74,.66,.65*taper))
		canvas.draw_set_transform(Vector2.ZERO)
	for index in range(72):
		var fraction=(index+.5)/72.0
		var angle=start+fraction*h.arc
		var grain=fposmod(sin(index*127.1+19.7)*43758.5453,1.0)
		var direction=Vector2.from_angle(angle)
		var at=p+direction*(h.radius-4+sin(index*2.3)*5)
		var lift=(10+grain*13)*(.75+.25*sin(h.radius*.035+index*2.1))
		var width=clampf(h.radius*h.arc/72.0*2.8,13,86)
		var dimensions=Vector2(width*(.85+grain*.3),24+grain*19)
		var taper=clampf(minf(fraction,1-fraction)*24,.0,1)
		# Preserve the rendered stone's upright volume. Rotating every sprite
		# tangent to the circle made the wave resemble a bead necklace.
		canvas.draw_set_transform(at-Vector2(0,lift),sin(index*3.2)*.22)
		canvas.draw_texture_rect(meteor_rock_views[index%6],Rect2(-dimensions*.5,dimensions),false,Color(1.1,1.04,.96,.88*taper))
		canvas.draw_set_transform(Vector2.ZERO)
	return true

static func hazard(canvas,h,p,clock):
	if h.get("meteor_fragment",false):
		if h.wait>0:
			terrain_warning(canvas,h,p)
			if h.wait<=.45:
				var progress=clampf(1-h.wait/.45,0,1)
				var origin=p+h.launch_origin-h.p
				var at=origin.lerp(p,progress)+Vector2(0,-sin(progress*PI)*110)
				var direction=(p-origin).normalized()
				for ember in range(5):
					canvas.draw_circle(at-direction*(ember*6),8-ember,Color(1,.28,.025,.5-ember*.08))
				canvas.draw_circle(at,11,Color(.095,.075,.045))
				for chip in range(5):
					canvas.draw_circle(at+Vector2.from_angle(chip*TAU/5)*7,4+chip%3,Color(.19,.14,.08))
		else:
			if "--meteor-fresh-study" in OS.get_cmdline_user_args() and textured_meteor_burst(canvas,h,p):return
			canvas.draw_circle(p,h.radius,Color(.16,.07,.025,.5))
			piece(canvas,1,p,Vector2.ONE*h.radius*2.1,0,.9)
		return
	if h.get("meteor_rupture",false):
		if h.wait<=0 and "--meteor-fresh-study" in OS.get_cmdline_user_args() and textured_meteor_ridge(canvas,h,p):return
		var start=h.angle-h.arc*.5
		var end=start+h.arc
		var charging=h.wait>0
		if charging and h.get("volley_wave",0)==0:
			# The source ridge is hidden beneath the shell. Scattered dusty
			# fractures reveal threatened ground, leaving the safe sector clear.
			for lane in range(32):
				var angle=start+(lane+.5)*h.arc/32
				var direction=Vector2.from_angle(angle)
				for segment in range(4):
					var at=p+direction*(190+segment*155)+direction.orthogonal()*sin(lane*7+segment)*12
					var to=at+direction*(65+sin(lane*3+segment)*18)+direction.orthogonal()*sin(lane+segment*5)*9
					var fracture=PackedVector2Array()
					for bend in range(5):
						fracture.append(at.lerp(to,bend/4.0)+direction.orthogonal()*sin(lane*11+segment*7+bend*4)*7)
					canvas.draw_polyline(fracture,Color(.10,.075,.045,.18),13,true)
					canvas.draw_polyline(fracture,Color(.63,.36,.12,.40),2.5,true)
		var color=Color(.74,.53,.28,.7) if charging else Color(.95,.30,.055,.85)
		# Weathered fronts retain the committed arc and footprint. Grit
		# breaks up the surface inward rather than implying extra reach.
		for band in range(3):
			meteor_ground_front(canvas,p,h.radius-8+band*8,start,end,Color(.12,.095,.065,.12 if charging else .20),9,1.4)
		if not charging:
			# Painted fractured earth gives the travelling ridge substance;
			# sparse clumps leave the committed escape opening legible.
			for cluster in range(18):
				var fraction=(cluster+.5)/18.0
				var angle=start+fraction*h.arc
				var direction=Vector2.from_angle(angle)
				var variation=fposmod(sin(cluster*91.7)*13758.53,1.0)
				if variation<.18:continue
				var at=p+direction*(h.radius-6-sin(cluster*2.7)*5)
				var width=clampf(h.radius*h.arc/18.0,25,70)
				piece(canvas,4,at,Vector2(width,24+variation*10),angle+PI/2,.52)
				piece(canvas,0,at,Vector2(width*.8,14),angle+PI/2,.32+variation*.2)
		# Molten cracks and dust carry the front; no red outline rings.
		# Keep angular identities fixed while travelling: changing the count
		# every frame remapped all chips and made the ground shimmer.
		var count=128
		for index in range(count):
			# Uneven clusters and gaps avoid a necklace of identical stones.
			var grain=fposmod(sin(index*127.1+19.7)*43758.5453,1.0)
			if grain<.22 or fposmod(sin(index*47.3)*15473.3,1.0)>clampf(h.radius/500.0,.24,1.0):continue
			var angle=start+(index+.5+sin(index*9.7)*.40)*h.arc/count
			var direction=Vector2.from_angle(angle)
			var at=p+direction*(h.radius-8+sin(index*2.3)*9+sin(index*5.1)*5)
			var size=2.0+grain*5.0
			var lift=0.0 if charging else (4+grain*11)*(.65+.35*sin(h.radius*.035+index*2.1))
			canvas.draw_circle(at+Vector2(0,3),size+4,Color(.17,.14,.10,.10 if charging else .18))
			if not charging:
				# A shallow wake of ash trails inward; the raised chip has its
				# own ground shadow instead of reading as a painted bead.
				canvas.draw_circle(at-direction*(5+grain*8),size*2,Color(.28,.22,.15,.08))
				var raised=at-Vector2(0,lift)
				if "--meteor-fresh-study" in OS.get_cmdline_user_args() and load_meteor_rocks():
					var dimensions=Vector2(size*4,size*3.5)
					canvas.draw_set_transform(raised,sin(index*3.2)*.5)
					canvas.draw_texture_rect(meteor_rock_views[index%6],Rect2(-dimensions*.5,dimensions),false,Color(1,1,1,.85))
					canvas.draw_set_transform(Vector2.ZERO)
				else:
					canvas.draw_circle(raised,size,Color(.16,.115,.065,.8))
					canvas.draw_circle(raised+direction.orthogonal()*size*.65,size*.6,Color(.22,.17,.105,.65))
			if not charging and grain>.46:
				var crack=PackedVector2Array([at-direction*(3+grain*7),at+direction.orthogonal()*sin(index)*3,at+direction*(3+grain*4)+direction.orthogonal()*sin(index*4)*5])
				canvas.draw_polyline(crack,Color(.72,.22,.04,.25+grain*.25),1.2,true)
		return
	if h.get("meteor_eruption",false):
		if h.wait>0:
			terrain_warning(canvas,h,p)
		else:
			if "--meteor-fresh-study" in OS.get_cmdline_user_args() and textured_meteor_burst(canvas,h,p):return
			canvas.draw_circle(p,h.radius,Color(.18,.045,.012,.6))
			piece(canvas,1,p,Vector2.ONE*h.radius*2.2,0,.95)
			for index in range(7):
				var direction=Vector2.from_angle(index*TAU/7)
				var point=p+direction*h.radius*.8
				# Overlapping rounded chips and ash soften the eruption's
				# silhouette. Decorative rubble never enlarges its hit area.
				var size=4+index%3
				canvas.draw_circle(point+Vector2(0,3),size+3,Color(.12,.10,.075,.23))
				canvas.draw_circle(point,size,Color(.10,.08,.055,.9))
				canvas.draw_circle(point+direction.orthogonal()*size*.45,size*.7,Color(.16,.13,.09,.8))
		return
	if h.has("theme"):
		themed_hazard(canvas,h,p,clock)
		return
	var charging = h.wait>0
	var progress = clampf(1-h.wait/maxf(0.01,h.warning),0,1)
	var pulse = 0.65+sin(clock*14)*0.12
	var color = Color("ffb95e") if charging else Color("ffedd2")
	if h.kind=="line":
		var dir = Vector2.from_angle(h.angle)
		var side = dir.orthogonal()*h.radius
		var end = p+dir*1000
		# Edge lines show the exact damaging footprint; painted lava gives it substance.
		canvas.draw_colored_polygon(PackedVector2Array([p+side,end+side,end-side,p-side]),Color(0.55,0.10,0.03,0.13 if charging else 0.25))
		for i in range(4): piece(canvas,0,p+dir*(125+i*250),Vector2(285,h.radius*2.4),h.angle,(0.18+progress*0.32) if charging else 0.95)
		canvas.draw_line(p+side,end+side,Color(color,pulse if charging else 0.85),2,true)
		canvas.draw_line(p-side,end-side,Color(color,pulse if charging else 0.85),2,true)
	elif h.kind=="ring":
		piece(canvas,2,p,Vector2.ONE*h.radius*2.5,clock*0.025,0.25+progress*0.25 if charging else 0.9)
		canvas.draw_arc(p,h.radius,0,TAU,80,Color(0.8,0.2,0.04,0.12 if charging else 0.4),40,true)
		for r in [h.radius-20,h.radius+20]: canvas.draw_arc(p,r,0,TAU,80,Color(color,pulse),2,true)
	else:
		piece(canvas,5 if charging else 1,p,Vector2.ONE*h.radius*2.65,clock*0.08 if charging else 0,0.5+progress*0.35 if charging else 1)
		canvas.draw_circle(p,h.radius,Color(0.6,0.12,0.02,0.1 if charging else 0.28))
		canvas.draw_arc(p,h.radius,0,TAU,64,Color(color,0.85),2,true)
		if charging: canvas.draw_arc(p,h.radius-5,-PI/2,-PI/2+TAU*progress,64,Color("ffe7a7"),3,true)

static func meteor_ground_front(canvas,p,radius,start,end,color,width,roughness):
	var points=PackedVector2Array()
	for index in range(97):
		var fraction=float(index)/96
		var angle=lerpf(start,end,fraction)
		# Stable spatial noise avoids shimmer as the wave travels.
		var grit=(sin(angle*19.0+1.7)*2.2+sin(angle*43.0)*1.1)*roughness
		var taper=sin(fraction*PI)
		points.append(p+Vector2.from_angle(angle)*(radius+grit*taper))
	canvas.draw_polyline(points,color,width,true)

static func terrain_warning(canvas,h,p):
	var progress=clampf(1-h.wait/maxf(.01,h.warning),0,1)
	if h.get("meteor_fragment",false) or h.get("meteor_eruption",false):
		if "--meteor-fresh-study" in OS.get_cmdline_user_args() and textured_meteor_warning(canvas,h,p,progress):return
		# Heat opens uneven fissures in the actual strike footprint. The
		# perimeter remains readable without a UI ring or straight spokes.
		for index in range(17):
			var angle=index*TAU/17.0+sin(index*3.7)*.16
			var direction=Vector2.from_angle(angle)
			var side=direction.orthogonal()
			var reach=h.radius*(.76+.2*absf(sin(index*7.3)))
			var crack=PackedVector2Array()
			for joint in range(5):
				var distance=reach*(.30+joint*.175)
				crack.append(p+direction*distance+side*sin(index*13.1+joint*2.7)*h.radius*.065)
			canvas.draw_polyline(crack,Color(.035,.025,.018,.55),5,true)
			canvas.draw_polyline(crack,Color(.95,.35,.065,.22+progress*.46),1.4+progress,true)
			if index%3==0:
				piece(canvas,0,p+direction*reach*.65,Vector2(h.radius*.72,h.radius*.32),angle,.12+progress*.16)
		return
	var alpha=.46+progress*.28
	var edge=Color(.70,.62,.46,alpha)
	var under=Color(.035,.045,.032,.42)
	var paths=[]
	if h.kind=="line":
		var forward=Vector2.from_angle(h.angle);var side=forward.orthogonal()*h.radius
		var length=h.get("length",1000.0)
		for sign in [-1,1]:
			for i in range(18):
				paths.append(PackedVector2Array([p+side*sign+forward*length*i/18.0,p+side*sign+forward*length*(i+.86)/18.0]))
	else:
		var arc=h.get("arc",TAU) if h.kind=="cone" else TAU
		var start=h.angle-arc*.5 if h.kind=="cone" else 0.0
		for i in range(32):
			var segment=PackedVector2Array()
			for j in range(4):
				var angle=start+arc*(i+float(j)*.28)/32
				var weathering=0.0
				if h.get("meteor_fragment",false) or h.get("meteor_eruption",false):
					weathering=-absf(sin(angle*17+1.3)*1.6+sin(angle*31)*.9)
				segment.append(p+Vector2.from_angle(angle)*(h.radius+weathering))
			paths.append(segment)
		if h.kind=="cone":
			for angle in [start,start+arc]:paths.append(PackedVector2Array([p,p+Vector2.from_angle(angle)*h.radius]))
	for points in paths:
		canvas.draw_polyline(points,Color(edge,.09+progress*.08),8,true)
		canvas.draw_polyline(points,under,3.5,true)
		canvas.draw_polyline(points,edge,2.2,true)
		var middle=points[points.size()/2]
		var outward=(middle-p).normalized()
		# Fixed grit and short fissures anchor the tell to the terrain.
		var grain=sin(middle.x*.23+middle.y*.31)
		canvas.draw_line(middle,middle+outward*(5+grain*3)+outward.orthogonal()*grain*5,Color(under,.45),1.5,true)
		canvas.draw_line(middle+outward*3,middle+outward*7,Color(edge,.16+progress*.14),4,true)

static func travelling_ground_fx(canvas,h,p):
	var age=1-h.life/h.get("max_life",.48)
	if h.kind=="gust":
		for band in range(4):
			var radius=h.radius-band*9
			canvas.draw_arc(p,radius,h.angle-h.arc*.5,h.angle+h.arc*.5,48,Color(.76,.73,.62,(1-age)*(.24-band*.045)),4+band*2,true)
		for i in range(14):
			var angle=h.angle-h.arc*.5+h.arc*i/13.0
			var at=p+Vector2.from_angle(angle)*(h.radius+sin(i*7)*18)
			canvas.draw_line(at,at-Vector2.from_angle(angle)*14,Color(.63,.57,.44,(1-age)*.5),2,true)
	else:
		var intensity=1-float(h.get("wave",0))*.22
		if seismic_earth==null:
			var source="res://assets/boss-public/effects/seismic-earth-v1.png"
			var earth_image=(load(source) as Texture2D).get_image()
			if earth_image==null:return
			earth_image.resize(512,int(512.0*earth_image.get_height()/earth_image.get_width()),Image.INTERPOLATE_LANCZOS)
			seismic_earth=ImageTexture.create_from_image(earth_image)
		# Artwork has asymmetric margins; explicit bounds avoid cutting a slab
		# in half or sampling its neighbour while keeping original proportions.
		var regions=[Rect2(0,0,.59,.465),Rect2(.595,0,.405,.465),Rect2(0,.465,.59,.535),Rect2(.60,.49,.40,.51)]
		# Stable fragment identities rise out of the soil, then settle as the
		# pressure dissipates. The final wave carries less mass and lift.
		var lift=sin(pow(clampf(age,0,1),.65)*PI)*48*intensity
		for i in range(12):
			var a=TAU*i/12+sin(i*3.7)*.23
			var outward=Vector2.from_angle(a)
			var at=p+outward*h.radius*(.24+float(i%3)*.18+age*.15)
			var size=(43+float(i%4)*9)*intensity
			canvas.draw_set_transform(at,0,Vector2(1,.35))
			canvas.draw_circle(Vector2.ZERO,size*.48,Color(.08,.065,.04,(1-age)*.32))
			canvas.draw_set_transform(at+Vector2(0,-lift*(.65+float(i%3)*.17)),sin(i*2.1)*.35+age*sin(i)*.4,Vector2.ONE)
			var region:Rect2=regions[i%4]
			region=Rect2(region.position*Vector2(seismic_earth.get_size()),region.size*Vector2(seismic_earth.get_size()))
			var dimensions=Vector2(size,size*region.size.y/region.size.x)
			canvas.draw_texture_rect_region(seismic_earth,Rect2(Vector2(-dimensions.x*.5,-dimensions.y*.7),dimensions),region,Color(1,1,1,(1-age)*intensity))
			canvas.draw_set_transform(Vector2.ZERO)
		for i in range(18):
			var a=TAU*i/18+sin(i*9.1)*.2
			var at=p+Vector2.from_angle(a)*h.radius*(.35+age*.6)
			at.y-=lift*.35
			canvas.draw_set_transform(at,0,Vector2(1,.55))
			var dust_radius=(15+age*24+float(i%3)*4)*intensity
			var dust_alpha=sin(age*PI)*(1-age)*.20*intensity
			# Layered falloff avoids hard circular particle edges. Dust follows
			# the outward eruption and lingers after the stones start settling.
			for layer in range(6):
				canvas.draw_circle(Vector2.ZERO,dust_radius*(1-float(layer)*.12),Color(.53,.48,.36,dust_alpha/6))
			canvas.draw_set_transform(Vector2.ZERO)

static func themed_hazard(canvas,h,p,clock):
	if h.kind=="gust" or (h.get("seismic",false) and h.wait<=0):
		travelling_ground_fx(canvas,h,p)
		return
	if h.get("seismic",false):
		terrain_warning(canvas,h,p)
		return
	if h.get("physical",false) and h.get("marker_only",false):
		terrain_warning(canvas,h,p)
		return
	var colors={"thorn":"a9d96a","basalt":"ff9d57","hunt":"a4eaff","aurora":"c0a0ff","warden":"f9da86","bloom":"b2ea80"}
	var color=Color(colors.get(h.theme,"ffffff"))
	var charging=h.wait>0
	var progress=clampf(1-h.wait/maxf(0.01,h.warning),0,1)
	var alpha=0.25+progress*0.45 if charging else 0.95

	if h.kind=="line":
		var dir=Vector2.from_angle(h.angle)
		var side=dir.orthogonal()*h.radius
		var length=h.get("length",1000.0)
		var end=p+dir*length
		canvas.draw_colored_polygon(PackedVector2Array([p+side,end+side,end-side,p-side]),Color(color,0.1 if charging else 0.25))
		canvas.draw_line(p+side,end+side,Color(color,0.85),2,true)
		canvas.draw_line(p-side,end-side,Color(color,0.85),2,true)

	elif h.kind=="cone":
		var points=PackedVector2Array([p])
		for j in range(33):points.append(p+Vector2.from_angle(h.angle-h.arc/2+h.arc*j/32)*h.radius)
		canvas.draw_colored_polygon(points,Color(color,0.12 if charging else 0.32))
		canvas.draw_polyline(points,Color(color,0.75),2,true)

	else:
		canvas.draw_arc(p,h.radius,0,TAU,48,Color(color,0.8),2,true)
		if charging:canvas.draw_arc(p,h.radius-5,-PI/2,-PI/2+TAU*progress,48,color,3,true)
		canvas.draw_circle(p,h.radius,Color(color,.08 if charging else .20))
