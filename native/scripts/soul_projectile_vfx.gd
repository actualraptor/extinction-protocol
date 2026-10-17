extends Node2D
## Soul Reaper / Soul Dominion: authored vapor frames and a curved motion wake.
static var sheet
var world
var frame_dt=0.016
func _process(dt):
	frame_dt=dt
	queue_redraw()
func _draw():
	if world==null or world.sim==null:return
	for shot in world.sim.shots:
		if applies(world.sim,shot.id):render_shot(self,world,shot,frame_dt)
	for effect in world.effects:
		if effect.kind.begins_with("impact_") and applies(world.sim,effect.kind.trim_prefix("impact_")):impact(self,world,effect)
static func texture():
	if sheet==null:sheet=load("res://assets/soul-projectile-frames-v2.png")
	return sheet
static func applies(g,id):return g.C.WEAPONS.get(id,{}).get("role","")=="soul"
static func record(shot):
	if not shot.has("soul_wake"):shot.soul_wake=PackedVector2Array([shot.old])
	var wake:PackedVector2Array=shot.soul_wake
	if wake[-1].distance_squared_to(shot.p)>=36:
		wake.append(shot.p)
		if wake.size()>12:wake.remove_at(0)
	shot.soul_wake=wake
static func render_shot(canvas,world,shot,dt=0.016):
	var g=world.sim;var evolved=g.weapons.get(shot.id,{}).get("evolved",false)
	var wake:PackedVector2Array=shot.get("soul_wake",PackedVector2Array())
	var scale=1.22 if evolved else 1.0
	for i in range(1,wake.size()):
		var weight=float(i)/wake.size()
		canvas.draw_line(world.screen(wake[i-1]),world.screen(wake[i]),Color(.35,.8,.65,weight*.3),maxf(1,weight*5*scale),true)
	var position:Vector2=world.screen(shot.p)
	# Heading follows the velocity through a low-pass filter: homing corrections steer the shot every tick and
	# an unfiltered sprite visibly twitches with them.
	var target:float=shot.v.angle() if shot.v.length_squared()>.01 else shot.get("soul_facing",0.0)
	var facing:float=target if not shot.has("soul_facing") else lerp_angle(shot.soul_facing,target,1.0-exp(-dt*12.0))
	shot.soul_facing=facing
	var phase:float=shot.age*10.0
	var frame:int=int(phase)%6
	var mix:float=fposmod(phase,1)
	var atlas=texture()
	var cell=Vector2(atlas.get_width()/6.0,atlas.get_height())
	canvas.draw_set_transform(position,facing,Vector2.ONE*scale)
	# Anchor the skull at the projectile, retaining the painted trailing vapor.
	for index in range(2):
		var alpha=(1-mix) if index==0 else mix
		if alpha<.01:continue
		canvas.draw_texture_rect_region(atlas,Rect2(-78,-100,100,200),Rect2(Vector2(((frame+index)%6)*cell.x,0),cell),Color(1,1,1,alpha*.92))
	canvas.draw_set_transform(Vector2.ZERO)
static func impact(canvas,world,e):
	var progress=clampf(1-e.life/e.max,0,1)
	var fade=1-progress
	var center:Vector2=world.screen(e.p)
	for i in range(5):
		var angle=i*TAU/5+progress*.7
		var at=center+Vector2.from_angle(angle)*(8+progress*30)
		canvas.draw_line(at,at-Vector2.from_angle(angle)*(6+progress*12),Color(.6,1,.82,fade*.65),maxf(1,fade*3),true)
	canvas.draw_circle(center,6+progress*13,Color(.7,1,.85,fade*.22))
