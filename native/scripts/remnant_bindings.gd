extends RefCounted
# Bindings are authored in each standalone pose's coordinates and baked once.
const ANCHORS={
	"thorn":[[.43,.30,.62,.60],[.57,.32,.45,.62],[.32,.42,.42,.46],[.33,.74,.42,.77],[.56,.74,.65,.76]],
	"basalt":[[.49,.26,.68,.51],[.65,.27,.51,.54],[.46,.39,.55,.43],[.42,.73,.50,.75],[.61,.72,.69,.73]],
	"hunt":[[.49,.29,.67,.52],[.64,.30,.52,.53],[.45,.41,.55,.44],[.40,.75,.47,.76],[.59,.71,.66,.73]],
	"aurora":[[.51,.26,.69,.49],[.66,.27,.53,.52],[.48,.37,.57,.40],[.42,.74,.49,.76],[.63,.69,.70,.71]],
	"warden":[[.48,.34,.64,.55],[.61,.35,.50,.57],[.42,.46,.51,.48],[.40,.75,.47,.77],[.62,.61,.69,.63]],
	"bloom":[[.51,.42,.68,.61],[.66,.43,.54,.64],[.48,.54,.57,.56],[.45,.81,.52,.82],[.66,.76,.73,.78]]
}
static func draw(canvas,id,dimensions,frame,source):
	var index=0
	for band in ANCHORS[id]:
		var a=Vector2(band[0],band[1])*dimensions
		var b=Vector2(band[2],band[3])*dimensions
		if index>=2:
			# Find the actual joint in this pose, keeping small cuffs off empty space.
			var centre=(a+b)*.5;var found=centre;var distance=INF
			var radius=int(dimensions.y*.12)
			for y in range(maxi(0,int(centre.y)-radius),mini(source.get_height(),int(centre.y)+radius)):
				for x in range(maxi(0,int(centre.x)-radius),mini(source.get_width(),int(centre.x)+radius)):
					if source.get_pixel(x,y).a<.6:continue
					var point=Vector2(x,y);var d=point.distance_squared_to(centre)
					if d<distance:distance=d;found=point
			var half=maxf(7,dimensions.y*.036)
			a=found-Vector2(half,0);b=found+Vector2(half,0)
		# Short articulated bands leave the bone silhouette readable.
		var points=PackedVector2Array()
		var steps=17 if index<2 else 7
		for k in range(steps):
			var u=k/float(steps-1)
			points.append(a.lerp(b,u)+Vector2(0,sin(u*PI)*dimensions.y*.014))
		preload("res://scripts/ritual_parchment.gd").ribbon(canvas,points,maxf(8,dimensions.y*(.055 if index<2 else .04)),.95,index*.6)
		if index<2:
			var end=b+Vector2(dimensions.x*.018,dimensions.y*.085)
			var tail=PackedVector2Array()
			for k in range(13):
				var u=k/12.0
				tail.append(b.lerp(end,u)+Vector2(sin(u*TAU+frame)*dimensions.x*.01*u,0))
			preload("res://scripts/ritual_parchment.gd").ribbon(canvas,tail,maxf(5,dimensions.y*.022),.8,index)
		index+=1
