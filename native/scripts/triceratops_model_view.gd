extends "res://scripts/boss_model_view.gd"
## Private adapter for the painted quadruped; encounter remains authoritative.
var contacts=preload("res://scripts/quadruped_foot_plant.gd").new()
var previous_ground=Vector2.ZERO
func _ready():
	force_triceratops=true
	super._ready()
	configure_skin(model)
static func configure_skin(node):
	if node is MeshInstance3D:
		for index in node.mesh.get_surface_count():
			var source_material=node.get_active_material(index)
			if source_material is StandardMaterial3D:
				var skin=source_material.duplicate()
				skin.metallic=0.0;skin.metallic_texture=null
				skin.roughness=.9;skin.roughness_texture=null
				node.set_surface_override_material(index,skin)
	for child in node.get_children():configure_skin(child)
func present(b,dt,speed,ground_position:Vector2,target_position:Vector2):
	var direction:Vector2=b.get("motion",b.aim)
	if direction.length_squared()<.01:direction=b.aim
	if b.action=="recover":direction=Vector2.from_angle(b.get("rig_heading",direction.angle()))
	desired_heading=-direction.angle();heading_rate=4.8 if ground_position.distance_to(target_position)<100 else 3.8
	if not initialized:
		heading=desired_heading;initialized=true;contacts.reset();animation_clock=0;gaze_yaw=0;gaze_pitch=0
		previous_ground=ground_position
	# Cadence follows the same interpolated translation used by the contact
	# solver, not a separately filtered physics-speed estimate.
	var rendered_speed=previous_ground.distance_to(ground_position)/maxf(.0001,dt)
	previous_ground=ground_position
	advance(dt)
	if b.action!="recover":b.rig_heading=-heading
	var turning=absf(wrapf(desired_heading-heading,-PI,PI))>.08
	var clip="walk" if speed>5 or turning else "idle"
	if speed>150:clip="run"
	var progress=clampf(1-b.action_left/maxf(.01,b.action_length),0,1)
	if b.action=="windup":clip={"HORN CHARGE":"windup_charge","HORN SWEEP":"windup_sweep","EARTH STOMP":"windup_stomp"}.get(b.move,"windup")
	elif b.action=="charge":clip="charge"
	elif b.action=="strike":clip="sweep" if b.move=="HORN SWEEP" else "stomp"
	# Pivot with a stepping gait before loading the attack. Four anchored
	# feet cannot safely rotate the entire quadruped in place.
	if b.action=="windup" and turning:clip="walk"
	if clip!=action:
		transition_poses.clear()
		for index in rig_skeleton.get_bone_count():
			transition_poses.append(pre_tracking_poses[index] if pre_tracking_poses.size()==rig_skeleton.get_bone_count() else rig_skeleton.get_bone_pose(index))
		transition_time=0.0
		set_action(clip);animation_clock=0;contacts.reset()
	var length=player.get_animation(clip).length
	if clip.begins_with("windup"):
		var remaining_turn=absf(wrapf(desired_heading-heading,-PI,PI))
		var turn_time=b.get("rig_turn_time",0.0)
		var loading_time=maxf(.01,b.action_length-turn_time)
		var loading_progress=clampf((b.action_length-b.action_left-turn_time)/loading_time,0,1)
		animation_clock=length*loading_progress if remaining_turn<.08 else 0.0
	elif b.action=="strike":animation_clock=length*progress
	else:
		var pace=rendered_speed/(screen_units*1.0/(1.8*.76)) if clip=="walk" else rendered_speed/(screen_units*1.45/(1.1*.62)) if clip in ["run","charge"] else 1.0
		if clip in ["walk","run","charge"]:
			var stride=1.0 if clip=="walk" else 1.45
			var stance=.76 if clip=="walk" else .62
			# Forefeet (x=1.54, lateral=.72) travel around a 1.7-unit
			# turning radius; cadence must cover that arc, not only body travel.
			pace+=turn_speed*1.7/(stride/(length*stance))
		animation_clock+=dt*clampf(pace,.05,8)
	rig_skeleton.reset_bone_poses();player.advance(dt);player.seek(fposmod(animation_clock,length) if clip in ["walk","run","idle","charge"] else minf(animation_clock,length),true)
	rig_skeleton.force_update_all_bone_transforms()
	if clip in ["walk","run"] and b.action=="recover" and b.motion.length_squared()>.01:
		var movement=Vector3(b.motion.x,0,b.motion.y)
		var local_direction=(rig_skeleton.global_basis.inverse()*movement).normalized()
		contacts.retarget_stride(rig_skeleton,local_direction)
	# Redirect the fresh authored pose before blending. The previous pose
	# already contains its side step and must not be redirected a second time.
	if not transition_poses.is_empty():
		transition_time+=dt
		var blend=clampf(transition_time/.16,0,1);blend=blend*blend*(3-2*blend)
		for index in transition_poses.size():rig_skeleton.set_bone_pose(index,transition_poses[index].interpolate_with(rig_skeleton.get_bone_pose(index),blend))
		if transition_time>=.16:transition_poses.clear()
	rig_skeleton.force_update_all_bone_transforms()
	# Convert screen translation to rig units while preserving viewport rotation.
	var saved=model.global_position;model.global_position=Vector3(ground_position.x/screen_units,0,ground_position.y/screen_units)
	contacts.apply(rig_skeleton,clip,animation_clock,length,dt);model.global_position=saved
	# Gaze is a final additive layer. Do not bake it into the next clip's
	# transition and then apply the correction again.
	pre_tracking_poses.clear()
	for index in rig_skeleton.get_bone_count():pre_tracking_poses.append(rig_skeleton.get_bone_pose(index))
	var hunting=b.action=="recover" or b.action=="intro"
	var yaw=clampf(wrapf(-(target_position-ground_position).angle()-heading,-PI,PI),-.45,.45) if hunting else 0.0
	gaze_yaw=lerpf(gaze_yaw,yaw,1-exp(-7*dt))
	var head_index=rig_skeleton.find_bone("head")
	var head_point=rig_skeleton.global_transform*rig_skeleton.get_bone_global_pose(head_index).origin
	var look_target=target_position if hunting else ground_position+b.aim*maxf(60,ground_position.distance_to(target_position))
	if b.action=="charge":look_target=ground_position+b.aim*maxf(180.0,ground_position.distance_to(b.target))
	var target_point=Vector3((look_target.x-ground_position.x)/screen_units,.65,(look_target.y-ground_position.y)/screen_units)
	var horizontal=Vector2(target_point.x-head_point.x,target_point.z-head_point.z).length()
	var forward=(rig_skeleton.global_basis*rig_skeleton.get_bone_global_pose(head_index).basis.y).normalized()
	var authored_pitch=atan2(forward.y,Vector2(forward.x,forward.z).length())
	var downward=clampf(authored_pitch+atan2(head_point.y-target_point.y,maxf(.6,horizontal)),0,.55)
	# Keep the horn sweep authored and locked to its marked area; gaze must
	# not pull the frill away from the physical sweep during the strike.
	if b.move=="HORN SWEEP" and b.action in ["windup","strike"]:downward=clampf(authored_pitch+.08,0,.55)
	gaze_pitch=lerpf(gaze_pitch,downward,1-exp(-9*dt))
	gaze_pitch=maxf(gaze_pitch,clampf(authored_pitch-.03,0,.55))
	for entry in [["neck",.6],["head",.4]]:
		var index=rig_skeleton.find_bone(entry[0]);var pose=rig_skeleton.get_bone_global_pose(index)
		var inverse_basis=rig_skeleton.global_basis.inverse()
		var yaw_axis=(inverse_basis*Vector3.UP).normalized()
		var pitch_axis=(inverse_basis*(pivot.global_basis*Vector3.FORWARD)).normalized()
		pose.basis=Basis(Quaternion(yaw_axis,gaze_yaw*entry[1]))*Basis(Quaternion(pitch_axis,gaze_pitch*entry[1]))*pose.basis
		rig_skeleton.set_bone_global_pose(index,pose);rig_skeleton.force_update_all_bone_transforms()
func draw_contact_shadows(canvas,at:Vector2):
	var pelvis=projected_ground("pelvis",at);var neck=projected_ground("neck",at)
	shadow_ellipse(canvas,Vector2(pelvis.x,pelvis.y),72,.45,Vector2(neck.x-pelvis.x,neck.y-pelvis.y).angle(),.25)
	for end in ["fore","hind"]:
		for side in ["L","R"]:
			var foot=projected_ground("foot"+end+side,at)
			shadow_ellipse(canvas,Vector2(foot.x,foot.y),18,.4,0,.35/(1+foot.z*5))
