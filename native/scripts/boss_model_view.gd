extends Node2D
## An isolated 3D world composited into the 2D scene. The source model is a
## temporary motion study; replacing it does not alter encounter geometry.
var viewport:SubViewport
var model:Node3D
var pivot:Node3D
var player:AnimationPlayer
var camera:Camera3D
var desired_heading=0.0
var heading=0.0
var turn_speed=0.0
var heading_rate=1.2
var action=""
var sprite:Sprite2D
var show_sprite=true
var screen_units=60.0
var animation_clock=0.0
var gait_pace=0.0
var initialized=false
var source="res://assets/boss-rigs/trex-custom-v1.glb"
var foot_plant=preload("res://scripts/boss_foot_plant.gd").new()
var transition_poses=[]
var transition_time=0.0
var rig_skeleton:Skeleton3D
var pre_tracking_poses=[]
var gaze_yaw=0.0
var hunting_posture=0.0
var gaze_pitch=0.0
var force_triceratops=false
func rig_mode():return "--painted-foot-plant" in OS.get_cmdline_user_args() or "--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")
func painted_mode():return "--painted-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")
func _ready():
	if force_triceratops or "--triceratops-rig-test" in OS.get_cmdline_user_args():source="res://assets/boss-public/triceratops-painted-rig.glb"
	elif painted_mode():
		source="res://assets/boss-public/trex-painted-articulated.glb"
	viewport=SubViewport.new();viewport.size=Vector2i(1024,1024) if "--pr-boss-capture" in OS.get_cmdline_user_args() or "--boss-detail-review" in OS.get_cmdline_user_args() else Vector2i(512,512)
	viewport.transparent_bg=true;viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_4X;add_child(viewport)
	var environment=WorldEnvironment.new();var env=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color(0,0,0,0)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("a5afa1");env.ambient_light_energy=.42
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;environment.environment=env;viewport.add_child(environment)
	var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-48,-35,0)
	key.light_color=Color("c7cab7");key.light_energy=.72;key.shadow_enabled=true;viewport.add_child(key)
	if force_triceratops or "--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"):
		# Preserve volume without doubling the painted reconstruction's dark
		# folds with near-black, small-scale self shadows.
		key.shadow_opacity=.55
		key.shadow_normal_bias=1.5
	var rim=DirectionalLight3D.new();rim.rotation_degrees=Vector3(-20,140,0)
	rim.light_color=Color("9ba89d");rim.light_energy=.18;viewport.add_child(rim)
	pivot=Node3D.new();viewport.add_child(pivot)
	var packed=load(source) as PackedScene
	assert(packed!=null,"Boss model could not be loaded")
	model=packed.instantiate();pivot.add_child(model)
	rig_skeleton=foot_plant.find_skeleton(model)
	player=find_player(model)
	assert(player!=null,"Boss model has no animation player")
	print("MODEL CLIPS / ",player.get_animation_list())
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=8.5;camera.position=Vector3(0,6,10);viewport.add_child(camera)
	camera.look_at(Vector3(0,1.5,0));camera.current=true
	sprite=Sprite2D.new();sprite.texture=viewport.get_texture();sprite.position=Vector2(0,-80);sprite.visible=show_sprite;add_child(sprite)
	set_action("idle")
func find_player(node):
	if node is AnimationPlayer:return node
	for child in node.get_children():
		var found=find_player(child)
		if found!=null:return found
	return null
func set_action(next):
	if next==action:return
	action=next
	if player.has_animation(next):
		player.get_animation(next).loop_mode=Animation.LOOP_LINEAR if next in ["idle","walk","run"] else Animation.LOOP_NONE
		# Manual seek has its own explicit pose transition in the contact
		# prototype; a second mixer blend distorts the contact trajectory.
		player.play(next,0.0 if rig_mode() else .16)
func advance(dt):
	var previous_heading=heading
	if rig_mode():
		heading=step_heading(heading,desired_heading,dt,heading_rate)
	else:heading=lerp_angle(heading,desired_heading,1-exp(-5*dt))
	pivot.rotation.y=heading
	turn_speed=absf(wrapf(heading-previous_heading,-PI,PI))/maxf(dt,.001)
static func step_heading(current:float,target:float,dt:float,rate:float=1.2)->float:
	return current+clampf(wrapf(target-current,-PI,PI),-rate*dt,rate*dt)
static func strike_time(clip:String,progress:float,length:float)->float:
	# Physical damage is committed at 45% of the encounter strike. Put the
	# authored bite closure / sweep extension / roar crest on that instant.
	var impact=.25 if clip=="bite" else .30
	if progress<=.45:return progress/.45*impact
	return impact+(progress-.45)/.55*(length-impact)
func _process(dt):advance(dt)
func present(b,dt,speed,ground_position:Vector2,target_position:Vector2):
	var dir:Vector2=b.get("motion",b.aim)
	if dir.length_squared()<.01:dir=b.aim
	desired_heading=-dir.angle()
	if b.action=="recover" and rig_mode():desired_heading=-b.get("rig_heading",dir.angle())
	heading_rate=6.0 if b.move=="TAIL SWEEP" and b.action=="windup" else 1.2
	# The simulation can turn at 1.2 rad/s. Leave a little rendering headroom
	# to recover tick/frame phase lag rather than preserving it through a turn.
	if b.action=="recover":heading_rate=maxf(1.35,absf(b.get("rig_turn_velocity",0.0))+.15)
	if rig_mode() and b.move=="TAIL SWEEP" and b.action=="strike":
		var swing_progress=clampf(1-b.action_left/maxf(.01,b.action_length),0,1)
		var turn_progress=clampf(swing_progress/.45,0,1)
		turn_progress=turn_progress*turn_progress*(3-2*turn_progress)
		desired_heading=-b.aim.angle()+PI*turn_progress
		heading_rate=14.0
	if not initialized:
		heading=desired_heading;initialized=true;foot_plant.reset()
		gaze_yaw=0.0;gaze_pitch=0.0;hunting_posture=0.0
		transition_poses.clear();pre_tracking_poses.clear();animation_clock=0.0
	var frame_heading=heading
	advance(dt)
	if rig_mode() and b.move=="TAIL SWEEP" and b.action=="strike":
		# This turn is authored against strike progress, just like the tail
		# bones. A second wall-clock rate limiter delays it relative to the
		# physical hit when physics and rendering run at different rates.
		heading=desired_heading;pivot.rotation.y=heading
		turn_speed=absf(wrapf(heading-frame_heading,-PI,PI))/maxf(dt,.001)
	if rig_mode():
		if b.action!="recover":b.rig_heading=-heading
		if b.move=="TAIL SWEEP" and b.action=="strike":b.motion=Vector2.from_angle(-heading)
	var progress=clampf(1-b.get("action_left",0)/maxf(.01,b.get("action_length",1)),0,1)
	var clip="idle";var timed=false
	if b.get("reform",0)>0:clip="roar"
	elif b.action=="windup":
		clip="windup";timed=true
		if painted_mode():
			if b.move=="APEX ROAR":clip="windup_roar"
			elif b.move=="TAIL SWEEP":clip="windup_sweep"
			elif b.move=="SEISMIC STOMP":clip="windup_stomp"
		if rig_mode():
			var turn_left=absf(wrapf(desired_heading-heading,-PI,PI))
			if turn_left>.08:clip="walk";timed=false
			else:
				var elapsed=b.action_length-b.action_left
				progress=clampf((elapsed-b.get("rig_turn_time",0.0))/maxf(.01,b.action_length-b.get("rig_turn_time",0.0)),0,1)
	elif b.action=="strike":
		clip="stomp" if b.move=="SEISMIC STOMP" else "roar" if b.move=="APEX ROAR" else "sweep" if b.move=="TAIL SWEEP" else "bite";timed=true
	elif b.action=="charge":clip="run"
	elif b.action=="intro" and progress>.65:clip="roar";timed=true;progress=clampf((progress-.65)/.35,0,1)
	elif speed>4:clip="run" if speed>130 else "walk"
	elif b.action=="recover" and turn_speed>.1 and rig_mode():clip="walk"
	if clip!=action:
		transition_poses.clear();transition_time=0.0
		if rig_skeleton!=null and rig_mode():
			for index in rig_skeleton.get_bone_count():transition_poses.append(pre_tracking_poses[index] if pre_tracking_poses.size()==rig_skeleton.get_bone_count() else rig_skeleton.get_bone_pose(index))
		animation_clock=0.0;gait_pace=0.0;set_action(clip)
	var length=player.get_animation(clip).length
	if timed:
		animation_clock=strike_time(clip,progress,length) if b.action=="strike" and rig_mode() else progress*length
	else:
		var pace=1.0
		if clip=="walk":pace=speed/(screen_units*1.25/(1.4*.62))
		if clip=="run":pace=speed/(screen_units*1.5/(.78*.56))
		if painted_mode():
			if clip=="walk":pace=speed/(screen_units*1.6/(1.6*.64))
			if clip=="run":pace=speed/(screen_units*2.2/(.95*.57))
			if clip in ["walk","run"] and rig_mode():
				var stride=1.6 if clip=="walk" else 2.2
				var stance=.64 if clip=="walk" else .57
				# Rotating feet travel around the body even when translation
				# slows. Keep stepping instead of freezing a long stance.
				pace=maxf(pace,turn_speed*.55/(stride/(length*stance)))
		if clip in ["walk","run"]:
			gait_pace=clampf(pace,.05,4) if gait_pace==0 else lerpf(gait_pace,clampf(pace,.05,4),1-exp(-12*dt))
			animation_clock+=dt*gait_pace
		else:animation_clock+=dt
	if rig_mode():rig_skeleton.reset_bone_poses()
	player.advance(dt)
	player.seek(fposmod(animation_clock,length) if clip in ["walk","run","idle"] else minf(animation_clock,length),true)
	if b.action=="recover" and clip in ["walk","run"] and rig_mode():
		rig_skeleton.force_update_all_bone_transforms()
		var travel=Vector3(dir.x,0,dir.y)
		foot_plant.retarget_stride(rig_skeleton,(rig_skeleton.global_basis.inverse()*travel).normalized())
	if not transition_poses.is_empty():
		transition_time+=dt
		var blend=clampf(transition_time/.16,0,1)
		blend=blend*blend*(3-2*blend)
		for index in transition_poses.size():rig_skeleton.set_bone_pose(index,transition_poses[index].interpolate_with(rig_skeleton.get_bone_pose(index),blend))
		rig_skeleton.force_update_all_bone_transforms()
		if transition_time>=.16:transition_poses.clear()
	if rig_mode():
		# A blended swing pose is not a valid ground contact. Acquire the
		# authored stance only after the transition settles.
		if not transition_poses.is_empty():foot_plant.reset()
		else:foot_plant.apply(model,clip,animation_clock,length,ground_position,screen_units,0.0 if b.action=="windup" else speed)
	pre_tracking_poses.clear()
	for index in rig_skeleton.get_bone_count():pre_tracking_poses.append(rig_skeleton.get_bone_pose(index))
	if rig_mode():
		var hunting=b.action=="recover" or (b.action=="intro" and progress<.65)
		var biting=b.move=="CRUSHING BITE" and b.action in ["windup","strike"]
		var charging=b.action=="charge" or (b.move=="PREDATORY RUSH" and b.action=="windup")
		var sweeping=b.move=="TAIL SWEEP" and b.action in ["windup","strike"]
		hunting_posture=lerpf(hunting_posture,1.0,1-exp(-9*dt))
		# Lock the strike to its telegraphed target; do not bend the hit cone.
		var look_target:Vector2=b.target if biting and b.action=="strike" else target_position
		if charging:
			# Once a rush is telegraphed, the muzzle follows its committed
			# corridor. A dodging player must not bend the head sideways or
			# pull it backwards as the body passes the original target.
			look_target=ground_position+b.aim*maxf(180.0,ground_position.distance_to(b.target))
		var target_angle=-(look_target-ground_position).angle()
		var wanted=clampf(wrapf(target_angle-heading,-PI,PI),-.65,.65) if hunting or biting or charging else 0.0
		gaze_yaw=lerpf(gaze_yaw,wanted,1-exp(-7*dt))
		var head_index=rig_skeleton.find_bone("head")
		var head_point=rig_skeleton.global_transform*rig_skeleton.get_bone_global_pose(head_index).origin
		var target_point=Vector3((look_target.x-ground_position.x)/screen_units,.65,(look_target.y-ground_position.y)/screen_units)
		var horizontal=Vector2(target_point.x-head_point.x,target_point.z-head_point.z).length()
		var head_forward=(rig_skeleton.global_basis*rig_skeleton.get_bone_global_pose(head_index).basis.y).normalized()
		var authored_pitch=atan2(head_forward.y,Vector2(head_forward.x,head_forward.z).length())
		var downward=clampf(authored_pitch+atan2(head_point.y-target_point.y,maxf(.35,horizontal)),0,.95)
		# The prey is behind the head in a tail attack. Hold a grounded
		# head pose rather than trying to look through the spine.
		if sweeping or not (hunting or biting or charging):downward=clampf(authored_pitch+.15,0,.95)
		gaze_pitch=lerpf(gaze_pitch,downward,1-exp(-12*dt))
		# Prevent an upward authored frame from escaping the correction during blends.
		gaze_pitch=maxf(gaze_pitch,clampf(authored_pitch-.03,0,.95))
		var gaze_base={}
		for bone_name in ["neck","head"]:
			var bone_index=rig_skeleton.find_bone(bone_name)
			gaze_base[bone_index]=rig_skeleton.get_bone_pose(bone_index)
		for refinement in range(3 if biting else 1):
			# Neck rotation moves the skull. Restore the authored local poses
			# before refining absolute aim; never accumulate additive rotations.
			for bone_index in gaze_base:rig_skeleton.set_bone_pose(bone_index,gaze_base[bone_index])
			rig_skeleton.force_update_all_bone_transforms()
			for entry in [["neck",.65,.6],["head",.35,.4]]:
				var index=rig_skeleton.find_bone(entry[0])
				var pose=rig_skeleton.get_bone_global_pose(index)
				var inverse_basis=rig_skeleton.global_basis.inverse()
				var yaw_axis=(inverse_basis*Vector3.UP).normalized()
				var pitch_axis=(inverse_basis*(pivot.global_basis*Vector3.FORWARD)).normalized()
				pose.basis=Basis(Quaternion(yaw_axis,gaze_yaw*entry[1]))*Basis(Quaternion(pitch_axis,gaze_pitch*entry[2]))*pose.basis
				rig_skeleton.set_bone_global_pose(index,pose);rig_skeleton.force_update_all_bone_transforms()
			if biting and refinement<2:
				var final_pose=rig_skeleton.get_bone_global_pose(head_index)
				var final_point=rig_skeleton.global_transform*final_pose.origin
				var final_forward=(rig_skeleton.global_basis*final_pose.basis.y).normalized()
				var final_horizontal=Vector2(final_forward.x,final_forward.z).length()
				var desired_pitch=atan2(target_point.y-final_point.y,maxf(.35,Vector2(target_point.x-final_point.x,target_point.z-final_point.z).length()))
				var pitch_error=atan2(final_forward.y,final_horizontal)-desired_pitch
				gaze_pitch=clampf(gaze_pitch+pitch_error*.75,maxf(0,authored_pitch-.03),.95)

func draw_body(canvas,at,tint):
	var size=camera.size*screen_units
	var floor_offset=1.5*.91*screen_units
	canvas.draw_set_transform(at)
	canvas.draw_texture_rect(viewport.get_texture(),Rect2(Vector2(-size*.5,-size*.5-floor_offset),Vector2.ONE*size),false,tint)
	canvas.draw_set_transform(Vector2.ZERO)
func projected_ground(name:String,at:Vector2)->Vector3:
	var index=rig_skeleton.find_bone(name)
	if index<0:return Vector3(at.x,at.y,0)
	var point=rig_skeleton.global_transform*rig_skeleton.get_bone_global_pose(index).origin
	var height=maxf(0,point.y)
	point.y=0
	var pixel=camera.unproject_position(point)
	var size=camera.size*screen_units
	var screen=at+Vector2(-size*.5,-size*.5-1.5*.91*screen_units)+pixel*size/float(viewport.size.x)
	return Vector3(screen.x,screen.y,height)
func shadow_ellipse(canvas,center:Vector2,radius:float,flatten:float,angle:float,opacity:float):
	# Four nested low-opacity shapes soften the edge without new textures.
	for layer in range(4):
		canvas.draw_set_transform(center,angle,Vector2(1,flatten))
		canvas.draw_circle(Vector2.ZERO,radius*(1-layer*.16),Color(0,0,0,opacity*.25))
	canvas.draw_set_transform(Vector2.ZERO)
func draw_contact_shadows(canvas,at:Vector2):
	if rig_skeleton==null:return
	var pelvis=projected_ground("pelvis",at);var neck=projected_ground("neck",at)
	var tail=projected_ground("tail2",at)
	var center=Vector2(pelvis.x,pelvis.y)
	var forward=Vector2(neck.x-pelvis.x,neck.y-pelvis.y)
	shadow_ellipse(canvas,center,76,.42,forward.angle(),.28)
	shadow_ellipse(canvas,Vector2(tail.x,tail.y),42,.35,forward.angle(),.17)
	var foot_names=["footforeL","footforeR","foothindL","foothindR"] if rig_skeleton.find_bone("footforeL")>=0 else ["toesL","toesR"]
	for foot_name in foot_names:
		var foot=projected_ground(foot_name,at)
		shadow_ellipse(canvas,Vector2(foot.x,foot.y),21+foot.z*5,.38,0,.40/(1+foot.z*7))

