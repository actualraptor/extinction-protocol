extends RefCounted
## Private painted-rig contact correction. Coordinates include the viewport yaw
## and the 2D boss's actual translated ground position, not just bone targets.
var skeleton:Skeleton3D
var anchors={}
var turn_steps={}
var previous_clip=""
var previous_origin=Vector3.ZERO
var maximum_error=0.0
var maximum_leg_length_error=0.0
var distance_replants=0
var unreachable_releases=0
var completed_turn_steps=0
var edge_contact_adjustments=0
var body_drop=0.0
var maximum_body_drop=0.0
var body_shift=Vector3.ZERO
var maximum_body_shift=0.0
func find_skeleton(node):
	if node is Skeleton3D:return node
	for child in node.get_children():
		var found=find_skeleton(child)
		if found!=null:return found
	return null
func reset():anchors.clear();turn_steps.clear();previous_clip="";body_drop=0.0;body_shift=Vector3.ZERO
func retarget_stride(rig:Skeleton3D,direction:Vector3):
	skeleton=rig
	for side in ["L","R"]:
		var upper=rig.find_bone("thigh"+side);var lower=rig.find_bone("shin"+side)
		var foot=rig.find_bone("foot"+side);var toes=rig.find_bone("toes"+side)
		var foot_pose=rig.get_bone_global_pose(foot)
		var toe_pose=rig.get_bone_global_pose(toes)
		var toe_relative=foot_pose.affine_inverse()*toe_pose
		var stride=foot_pose.origin.x-rig.get_bone_global_rest(foot).origin.x
		var ankle=foot_pose.origin+Vector3((direction.x-1)*stride,0,direction.z*stride)
		var hip=rig.get_bone_global_pose(upper).origin;var knee=rig.get_bone_global_pose(lower).origin
		var lower_pose=rig.get_bone_global_pose(lower)
		var a=hip.distance_to(knee);var b=knee.distance_to(foot_pose.origin)
		var axis=(ankle-hip).normalized();var distance=clampf(hip.distance_to(ankle),absf(a-b)+.001,a+b-.001)
		ankle=hip+axis*distance
		var along=(a*a-b*b+distance*distance)/(2*distance)
		var pole=knee-hip;pole-=axis*pole.dot(axis)
		if pole.length_squared()<.00001:pole=Vector3.RIGHT-axis*axis.x
		var solved=hip+axis*along+pole.normalized()*sqrt(maxf(0,a*a-along*along))
		aim(upper,hip,solved,knee)
		lower_pose.basis=Basis(Quaternion((foot_pose.origin-knee).normalized(),(ankle-solved).normalized()))*lower_pose.basis
		lower_pose.origin=solved;rig.set_bone_global_pose(lower,lower_pose)
		foot_pose.origin=ankle;rig.set_bone_global_pose(foot,foot_pose)
		rig.set_bone_global_pose(toes,foot_pose*toe_relative);rig.force_update_all_bone_transforms()
func aim(index:int,start:Vector3,end:Vector3,original_end:Vector3):
	var pose=skeleton.get_bone_global_pose(index)
	var old_direction=(original_end-pose.origin).normalized()
	var direction=(end-start).normalized()
	pose.basis=Basis(Quaternion(old_direction,direction))*pose.basis;pose.origin=start
	skeleton.set_bone_global_pose(index,pose);skeleton.force_update_all_bone_transforms()
func apply(model:Node3D,clip:String,clock:float,length:float,position:Vector2,units:float,travel_speed:float=0.0):
	if skeleton==null:skeleton=find_skeleton(model)
	if skeleton==null:return
	var origin=Vector3(position.x/units,0,position.y/units)
	if clip!=previous_clip or origin.distance_to(previous_origin)>1.5:anchors.clear();turn_steps.clear()
	previous_clip=clip;previous_origin=origin
	var world=Transform3D(Basis.IDENTITY,origin)*skeleton.global_transform
	var inverse=world.affine_inverse()
	var moving=clip in ["walk","run"]
	var stance=.64 if clip=="walk" else .57
	# The sweep turns the body through the attack. Both soles cannot remain
	# pinned at their original heading: step one foot while the other braces.
	# Schedule before support correction so a departing foot cannot pull the
	# body down for a frame before its step begins.
	if clip=="sweep" and turn_steps.is_empty():
		var chosen="";var largest=.25
		for side in ["L","R"]:
			if not anchors.has(side):continue
			var toes=skeleton.find_bone("toes"+side)
			var pose=skeleton.get_bone_global_pose(toes)
			var deviation=(world*pose).origin.distance_to(anchors[side].origin)
			var rotation=(world*pose).basis.get_rotation_quaternion().angle_to(anchors[side].basis.get_rotation_quaternion())
			if rotation>.18 and deviation>largest:chosen=side;largest=deviation
		if chosen!="":
			distance_replants+=1
			turn_steps[chosen]={"start":anchors[chosen],"landing_local":skeleton.get_bone_global_pose(skeleton.find_bone("toes"+chosen)),"elapsed":0.0}
	# Reserve knee flexion by transferring the body toward held feet. Estimate
	# in world coordinates so imported skeleton-axis conventions cannot tilt it.
	var desired_drop=0.0
	var desired_shift=Vector3.ZERO
	var support_count=0
	var support_constraints=[]
	for side in ["L","R"]:
		if side=="R" and (clip=="windup_stomp" or (clip=="stomp" and clock<.30)):
			anchors.erase(side);continue
		var phase=fposmod(clock/length+(0.0 if side=="L" else .5),1.0)
		if moving and not (phase>.025 and phase<stance-.025):continue
		var upper=skeleton.find_bone("thigh"+side);var lower=skeleton.find_bone("shin"+side)
		var foot=skeleton.find_bone("foot"+side);var toes=skeleton.find_bone("toes"+side)
		if mini(mini(upper,lower),mini(foot,toes))<0:continue
		var toe_pose=skeleton.get_bone_global_pose(toes)
		if not anchors.has(side):anchors[side]=world*toe_pose
		if turn_steps.has(side):continue
		support_count+=1
		var target=inverse*anchors[side]
		var ankle_pose=skeleton.get_bone_global_pose(foot)
		var basis=target.basis*toe_pose.basis.inverse()*ankle_pose.basis
		var ankle=target.origin-basis*(ankle_pose.affine_inverse()*toe_pose.origin)
		var hip=skeleton.get_bone_global_pose(upper).origin
		var knee=skeleton.get_bone_global_pose(lower).origin
		var reach=(world.basis*(hip-knee)).length()+(world.basis*(knee-ankle_pose.origin)).length()-.08
		support_constraints.append({"delta":world.basis*(hip-ankle),"reach":reach})
		var delta=world.basis*(hip-ankle)
		var horizontal=Vector2(delta.x,delta.z).length_squared()
		if delta.y>0 and reach*reach>horizontal:desired_drop=maxf(desired_drop,delta.y-sqrt(reach*reach-horizontal))
		var lowered_height=maxf(0,delta.y-.26)
		var safe_horizontal=sqrt(maxf(0,reach*reach-lowered_height*lowered_height))
		var horizontal_length=sqrt(horizontal)
		if horizontal_length>safe_horizontal:
			var shift=-Vector3(delta.x,0,delta.z).normalized()*minf(.30,horizontal_length-safe_horizontal)
			desired_shift+=shift
	if support_count>0:desired_shift/=support_count
	desired_drop=clampf(desired_drop,0,.26)
	body_drop=lerpf(body_drop,desired_drop,1-exp(-20*model.get_process_delta_time()))
	body_shift=body_shift.lerp(desired_shift,1-exp(-20*model.get_process_delta_time()))
	# Recheck reach after the smoothed lateral weight shift. A stale shift
	# can otherwise straighten the opposite leg before the drop catches up.
	for constraint in support_constraints:
		var delta:Vector3=constraint.delta+body_shift
		var horizontal=Vector2(delta.x,delta.z).length_squared()
		var required=maxf(0,delta.y-sqrt(maxf(0,constraint.reach*constraint.reach-horizontal)))
		body_drop=maxf(body_drop,minf(.35,required))
	if body_drop>maximum_body_drop+.02 and body_drop>.2 and "--trace-foot-contact" in OS.get_cmdline_user_args():
		print("BODY DROP TRACE / clip=",clip," clock=",clock," travel=",travel_speed," drop=",body_drop," desired=",desired_drop," shift=",body_shift," constraints=",support_constraints)
	maximum_body_drop=maxf(maximum_body_drop,body_drop)
	maximum_body_shift=maxf(maximum_body_shift,body_shift.length())
	var root_index=skeleton.find_bone("root")
	if root_index>=0 and (body_drop>0 or body_shift.length_squared()>0):
		var root_pose=skeleton.get_bone_global_pose(root_index)
		root_pose.origin+=world.basis.inverse()*(body_shift-Vector3.UP*body_drop)
		skeleton.set_bone_global_pose(root_index,root_pose);skeleton.force_update_all_bone_transforms()
	for side in ["L","R"]:
		if side=="R" and (clip=="windup_stomp" or (clip=="stomp" and clock<.30)):
			anchors.erase(side);continue
		var phase=fposmod(clock/length+(0.0 if side=="L" else .5),1.0)
		var planted=not moving or (phase>.025 and phase<stance-.025)
		if not planted and not turn_steps.has(side):anchors.erase(side);continue
		var upper=skeleton.find_bone("thigh"+side);var lower=skeleton.find_bone("shin"+side)
		var foot=skeleton.find_bone("foot"+side);var toes=skeleton.find_bone("toes"+side)
		if mini(mini(upper,lower),mini(foot,toes))<0:continue
		var hip=skeleton.get_bone_global_pose(upper).origin
		var lower_pose=skeleton.get_bone_global_pose(lower)
		var knee=lower_pose.origin
		var ankle_pose=skeleton.get_bone_global_pose(foot)
		var toe_pose=skeleton.get_bone_global_pose(toes)
		if not anchors.has(side):anchors[side]=world*toe_pose
		var target=inverse*anchors[side]
		var other="R" if side=="L" else "L"
		var other_phase=fposmod(phase+.5,1.0)
		var other_supports=other_phase>.025 and other_phase<stance-.025-.28/length and not turn_steps.has(other)
		var turning_contact=(world*toe_pose).basis.get_rotation_quaternion().angle_to(anchors[side].basis.get_rotation_quaternion())>.25
		if moving and turning_contact and other_supports and not turn_steps.has(side) and target.origin.distance_to(toe_pose.origin)>.70:
			distance_replants+=1
			turn_steps[side]={"start":anchors[side],"landing_local":toe_pose,"elapsed":0.0}
		var stepping=turn_steps.has(side)
		if stepping:
			var step=turn_steps[side]
			step.elapsed+=model.get_process_delta_time()
			var fraction=clampf(step.elapsed/(.16 if clip=="sweep" else .28),0,1)
			var eased=fraction*fraction*(3-2*fraction)
			var landing:Transform3D=world*step.landing_local
			landing.origin.y=step.start.origin.y
			var step_target:Transform3D=step.start.interpolate_with(landing,eased)
			step_target.origin.y+=.16*sin(PI*fraction)
			target=inverse*step_target
			if fraction>=1:
				anchors[side]=landing;turn_steps.erase(side);completed_turn_steps+=1
		var foot_basis=target.basis*toe_pose.basis.inverse()*ankle_pose.basis
		var offset=ankle_pose.affine_inverse()*toe_pose.origin
		var ankle=target.origin-foot_basis*offset
		var l1=hip.distance_to(knee);var l2=knee.distance_to(ankle_pose.origin)
		var axis=(ankle-hip).normalized();var distance=hip.distance_to(ankle)
		# A tiny reach overshoot must not pop the whole foot back to animation.
		# Move the contact horizontally within a narrow tolerance, preserving
		# sole height and leg length, then solve the same continuous IK pose.
		if distance>=l1+l2-.001:
			var vertical=ankle.y-hip.y
			var horizontal=Vector3(ankle.x-hip.x,0,ankle.z-hip.z)
			var safe=sqrt(maxf(0,pow(l1+l2-.005,2)-vertical*vertical))
			var correction=horizontal.length()-safe
			if correction>0 and correction<=(.6 if stepping else .08):
				var shift=-horizontal.normalized()*correction
				ankle+=shift;target.origin+=shift
				if not turn_steps.has(side):anchors[side]=world*target
				axis=(ankle-hip).normalized();distance=hip.distance_to(ankle)
				edge_contact_adjustments+=1
		if distance>=l1+l2-.001 or distance<absf(l1-l2)+.001:
			unreachable_releases+=1
			if "--trace-foot-contact" in OS.get_cmdline_user_args():print("CONTACT RELEASE / clip=",clip," side=",side," phase=",phase," clock=",clock," reach=",distance," bounds=",absf(l1-l2),"..",l1+l2," correction=",target.origin.distance_to(toe_pose.origin)," travel=",travel_speed," drop=",body_drop," wanted_drop=",desired_drop," shift=",body_shift," actual_delta=",world.basis*(hip-ankle)," constraints=",support_constraints)
			anchors.erase(side);turn_steps.erase(side);continue
		var along=(l1*l1-l2*l2+distance*distance)/(2*distance)
		var pole=(knee-hip)-axis*(knee-hip).dot(axis)
		if pole.length_squared()<.00001:pole=Vector3.FORWARD.cross(axis)
		var solved_knee=hip+axis*along+pole.normalized()*sqrt(maxf(0,l1*l1-along*along))
		aim(upper,hip,solved_knee,knee)
		# Preserve the animated rest-roll for the lower leg before the parent edit.
		lower_pose.basis=Basis(Quaternion((ankle_pose.origin-knee).normalized(),(ankle-solved_knee).normalized()))*lower_pose.basis
		lower_pose.origin=solved_knee;skeleton.set_bone_global_pose(lower,lower_pose)
		skeleton.set_bone_global_pose(foot,Transform3D(foot_basis,ankle))
		skeleton.set_bone_global_pose(toes,target);skeleton.force_update_all_bone_transforms()
		var corrected_hip=skeleton.get_bone_global_pose(upper).origin
		var corrected_knee=skeleton.get_bone_global_pose(lower).origin
		var corrected_ankle=skeleton.get_bone_global_pose(foot).origin
		maximum_leg_length_error=maxf(maximum_leg_length_error,maxf(absf(corrected_hip.distance_to(corrected_knee)-l1),absf(corrected_knee.distance_to(corrected_ankle)-l2)))
		if not turn_steps.has(side):maximum_error=maxf(maximum_error,(world*skeleton.get_bone_global_pose(toes)).origin.distance_to(anchors[side].origin))
