extends RefCounted
static var parchment:Texture2D
static func launch_time(id):return .15+int(id/3)*.28 if id%3==1 else 4.2+id*.07
static func path(at,id,clock,p,dimensions):
	var local=coil(at,id,clock)
	var fan=smoothstep(4.5,6.6,clock)
	if id%3!=1:return local
	var centre=p+Vector2(0,(int(id/3)-1)*dimensions.y*.24-preload("res://scripts/rite_animation.gd").lift_amount(clock))
	for k in range(local.size()):
		var u=k/float(local.size()-1)
		var angle=u*TAU*1.25+id*2.399+minf(clock,4.5)*.4
		# A helix advances along the animal's long axis, crossing its silhouette
		# above and below instead of orbiting in a flat ring around its centre.
		var whole=centre+Vector2((u-.5)*dimensions.x*.86+cos(angle)*12,sin(angle)*dimensions.y*.38)
		local[k]=whole.lerp(local[k],fan)
	return local
static func coil(at,id,clock):
	var tightened=smoothstep(2.7,4.4,clock)
	var radius=(34+id%3*6)*(1-tightened*.25)
	var points=PackedVector2Array()
	for k in range(33):
		var u=k/32.0
		var angle=u*TAU*.85+id*2.399+maxf(0,clock-6.0)*.72
		points.append(at+Vector2(cos(angle)*radius,sin(angle)*13+(u-.5)*34))
	return points
static func ribbon(canvas,points,width,opacity,clock):
	if opacity<.01 or points.size()<3:return
	if parchment==null:parchment=load("res://assets/ritual-vfx/parchment-strip-v1.png")
	var vertices=PackedVector2Array();var uv=PackedVector2Array()
	for side in [1,-1]:
		for step in range(points.size()):
			var i=step if side==1 else points.size()-1-step
			var direction=(points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
			var normal=Vector2(-direction.y,direction.x)
			var u=float(i)/(points.size()-1)
			var fold=.73+.27*sin(u*TAU*2+clock*2)
			vertices.append(points[i]+normal*width*.5*side*fold)
			uv.append(Vector2(u,.25 if side==1 else .72))
	var indices=PackedInt32Array();var count=points.size()
	for i in range(count-1):
		indices.append_array(PackedInt32Array([i,i+1,count*2-2-i,i,count*2-2-i,count*2-1-i]))
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(),indices,vertices,PackedColorArray([Color(.81,.74,.54,opacity)]),uv,PackedInt32Array(),PackedFloat32Array(),parchment.get_rid())
	# Place the existing Aurebesh stroke alphabet on the curved material.
	var lines=PackedVector2Array();var word="NAGASH"
	for i in range(2,points.size()-2,3):
		var direction=(points[i+1]-points[i-1]).normalized()
		var normal=Vector2(-direction.y,direction.x)
		var letter=word[int(i/3)%word.length()]
		for path in preload("res://scripts/rite_circle.gd").GLYPHS[letter]:
			for n in range(0,path.size()-2,2):
				for k in [n,n+2]:lines.append(points[i]+direction*(path[k]-.5)*width*.6+normal*(path[k+1]-.45)*width*.55)
	if not lines.is_empty():
		canvas.draw_multiline(lines,Color(.10,.85,.38,opacity*.08),3,false)
		canvas.draw_multiline(lines,Color(.33,1,.63,opacity*.20),2.0,false)
		canvas.draw_multiline(lines,Color(.78,1,.84,opacity),1.0,false)
static func wrap(canvas,c,p,t,front=true):
	var opacity=1-smoothstep(.86,.99,t)
	if opacity<.01:return
	var rig=preload("res://scripts/remnant_rig.gd")
	var art=rig.atlas_pose(c.identity,0)
	if art==null:return
	var a=preload("res://scripts/rite_animation.gd")
	var flesh=preload("res://scripts/remnant_system.gd").corpse_art(c.identity)
	var flesh_dimensions=flesh.get_size()/flesh.get_width()*c.size*3.2
	var index=rig.IDS.find(c.identity)
	var factor=rig.height(c.identity)/rig.layouts[index][0][3]
	var left=(rig.layouts[index][0][0]-.5*rig.sheets[c.identity].get_width()/4)*factor
	var dimensions=art.get_size()*factor
	for id in range(9):
		var offset=(Vector2(id%3+.5,int(id/3)+.5)/3-Vector2(.5,.5))*flesh_dimensions
		var at=a.flesh_position(offset,p,id,t) if a.passage(id,t)<.54 else a.bone_position(id,p,t,left,dimensions,flesh_dimensions,c.identity)
		var clock=t*a.DURATION
		var growth=clampf((clock-launch_time(id)-.85)/1.05,0,1)
		if growth<=0:continue
		var full=path(at,id,clock,p,flesh_dimensions)
		var points=PackedVector2Array()
		var last=growth*(full.size()-1)
		for k in range(int(last)+1):points.append(full[k])
		if int(last)<full.size()-1:points.append(full[int(last)].lerp(full[int(last)+1],fmod(last,1)))
		# Split the coils at depth crossings: rear arcs are occluded by flesh/bones.
		var run=PackedVector2Array()
		for k in range(points.size()):
			var fan=smoothstep(4.5,6.6,clock)
			var angle=k/float(full.size()-1)*TAU*lerpf(1.25,.85,fan)+id*2.399+lerpf(minf(clock,4.5)*.4,maxf(0,clock-6.0)*.72,fan)
			if (sin(angle)>=0)==front:
				if run.is_empty() and k>0:run.append(points[k-1])
				run.append(points[k])
			elif not run.is_empty():
				run.append(points[k]);ribbon(canvas,run,11,opacity*.7,clock+id);run=PackedVector2Array()
		if not run.is_empty():ribbon(canvas,run,11,opacity*.7,clock+id)
