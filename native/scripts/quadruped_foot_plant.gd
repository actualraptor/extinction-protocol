extends RefCounted
## Private four-foot contact study. Anchors live in world space across body yaw.
var anchors={}
var previous_clip=""
var unreachable=0
var maximum_length_error=0.0
var maximum_contact_error=0.0
var steps={}
var last_clock=0.0
var completed_steps=0
var maximum_body_drop=0.0
var support_shift=Vector3.ZERO
var maximum_support_shift=0.0
var adaptive_steps=0
var landed_feet=[]
func reset():anchors.clear();steps.clear();previous_clip=""
func aim(skeleton,index,start,end):
	var pose=skeleton.get_bone_global_pose(index)
	var old=pose.basis.y.normalized()
	pose.basis=Basis(Quaternion(old,(end-start).normalized()))*pose.basis
	pose.origin=start;skeleton.set_bone_global_pose(index,pose);skeleton.force_update_all_bone_transforms()
func retarget_stride(skeleton:Skeleton3D,direction:Vector3):
	# Redirect ankle travel while the shoulders and skull still face prey.
	# Preserve authored lift and anatomical limb lengths during side steps.
	for key in ["hindL","foreL","hindR","foreR"]:
		var upper=skeleton.find_bone("upper"+key);var lower=skeleton.find_bone("lower"+key);var foot=skeleton.find_bone("foot"+key)
		var pose=skeleton.get_bone_global_pose(foot)
		var rest=skeleton.get_bone_global_rest(foot).origin
		var stride=pose.origin.x-rest.x
		var ankle=pose.origin+Vector3((direction.x-1)*stride,0,direction.z*stride)
		var hip=skeleton.get_bone_global_pose(upper).origin;var old_knee=skeleton.get_bone_global_pose(lower).origin
		var a=hip.distance_to(old_knee);var b=old_knee.distance_to(pose.origin)
		var delta=ankle-hip;var distance=clampf(delta.length(),absf(a-b)+.001,a+b-.001)
		var axis=delta.normalized();ankle=hip+axis*distance
		var along=(a*a-b*b+distance*distance)/(2*distance)
		var pole=old_knee-hip;pole-=axis*pole.dot(axis)
		if pole.length_squared()<.00001:pole=Vector3.RIGHT-axis*axis.x
		var knee=hip+axis*along+pole.normalized()*sqrt(maxf(0,a*a-along*along))
		aim(skeleton,upper,hip,knee);aim(skeleton,lower,knee,ankle)
		pose.origin=ankle;skeleton.set_bone_global_pose(foot,pose);skeleton.force_update_all_bone_transforms()
func apply(skeleton:Skeleton3D,clip:String,clock:float,length:float,real_dt:float=-1.0):
	landed_feet.clear()
	if previous_clip!=clip:anchors.clear();steps.clear();last_clock=clock
	var dt=clampf(real_dt if real_dt>=0 else clock-last_clock,0,.05);last_clock=clock
	previous_clip=clip
	var moving=clip in ["walk","run","charge"]
	var offsets={"hindL":0.0,"foreL":.25,"hindR":.5,"foreR":.75} if clip=="walk" else {"hindL":0.0,"foreR":0.0,"hindR":.5,"foreL":.5}
	var stance=.76 if clip=="walk" else .62
	var world=skeleton.global_transform;var inverse=world.affine_inverse()
	var held=[];var drop=0.0
	for key in offsets:
		var phase=fposmod(clock/length+offsets[key],1.0)
		var planted=not moving or (phase>.025 and phase<stance-.025)
		if key=="foreL" and (clip=="windup_stomp" or (clip=="stomp" and clock<length*.45)):planted=false
		if not planted and not steps.has(key):anchors.erase(key);continue
		var upper=skeleton.find_bone("upper"+key);var lower=skeleton.find_bone("lower"+key);var foot=skeleton.find_bone("foot"+key)
		assert(mini(upper,mini(lower,foot))>=0)
		if not anchors.has(key):anchors[key]=world*skeleton.get_bone_global_pose(foot)
		var authored=skeleton.get_bone_global_pose(foot)
		var desired=world*authored
		var turn=anchors[key].basis.get_rotation_quaternion().angle_to(desired.basis.get_rotation_quaternion())
		if moving and not steps.has(key):
			var hip_pose=skeleton.get_bone_global_pose(upper).origin
			var knee_pose=skeleton.get_bone_global_pose(lower).origin
			var reach=hip_pose.distance_to(knee_pose)+knee_pose.distance_to(authored.origin)
			var held_delta=hip_pose-(inverse*anchors[key]).origin
			# Turning can exhaust a planted leg before the nominal gait swing.
			# Lift and replant before full extension instead of dropping the
			# pelvis excessively or discarding an unreachable anchor abruptly.
			if held_delta.length()>reach*.90 and anchors[key].origin.distance_to(desired.origin)>.12:
				steps[key]={"start":anchors[key],"landing":authored,"elapsed":0.0}
				adaptive_steps+=1
		# A braced windup or idle can still pivot toward the player. It needs
		# the same lifting adjustment as locomotion, rather than locked ankles.
		# Locomotion already schedules its own lift and landing. An extra
		# pivot step would hold an old stance sample past the gait's swing.
		if not moving and steps.is_empty() and turn>.14 and anchors[key].origin.distance_to(desired.origin)>.15:
			steps[key]={"start":anchors[key],"landing":authored,"elapsed":0.0}
		if steps.has(key):
			var step=steps[key];step.elapsed+=dt
			# A running replant must finish within the faster gait's swing;
			# walking timing leaves the old ankle trailing behind the charge.
			var step_duration=.14 if clip in ["run","charge"] else .22
			var fraction=clampf(step.elapsed/step_duration,0,1);var blend=fraction*fraction*(3-2*fraction)
			var landing=world*step.landing;landing.origin.y=step.start.origin.y
			anchors[key]=step.start.interpolate_with(landing,blend)
			anchors[key].origin.y+=.16*sin(PI*fraction)
			if fraction>=1:
				steps.erase(key);completed_steps+=1;landed_feet.append(key)
		var target=inverse*anchors[key]
		var hip=skeleton.get_bone_global_pose(upper).origin
		var knee=skeleton.get_bone_global_pose(lower).origin
		var ankle=skeleton.get_bone_global_pose(foot).origin
		var a=hip.distance_to(knee);var b=knee.distance_to(ankle)
		var delta=world.basis*(hip-target.origin);var reach=a+b-.02
		var horizontal=Vector2(delta.x,delta.z).length_squared()
		if horizontal<reach*reach:drop=maxf(drop,delta.y-sqrt(reach*reach-horizontal))
		held.append({"key":key,"upper":upper,"lower":lower,"foot":foot,"a":a,"b":b,"target":target})
	# Transfer weight toward a stretched support leg before increasing crouch.
	# Project the body into the intersection of the supporting legs' reach
	# discs. Feet remain fixed; only the pelvis/root translates, within .18.
	support_shift*=exp(-8*dt)
	for iteration in range(4):
		for item in held:
			var delta=world.basis*(skeleton.get_bone_global_pose(item.upper).origin-item.target.origin)+support_shift
			var reach=item.a+item.b-.025
			var vertical=maxf(0,delta.y-minf(drop,.35))
			var allowance=sqrt(maxf(0,reach*reach-vertical*vertical))
			var horizontal=Vector3(delta.x,0,delta.z)
			if horizontal.length()>allowance:
				support_shift-=horizontal.normalized()*(horizontal.length()-allowance)
				support_shift=support_shift.limit_length(.18)
	maximum_support_shift=maxf(maximum_support_shift,support_shift.length())
	# A lateral correction for one support can stretch another. Re-evaluate
	# vertical clearance after projection, before applying the root transform.
	# Keep the same reach reserve and crouch cap; do not discard a fixed sole
	# just because the earlier drop calculation predates the weight transfer.
	for item in held:
		var delta=world.basis*(skeleton.get_bone_global_pose(item.upper).origin-item.target.origin)+support_shift
		var reach=item.a+item.b-.025
		var horizontal=Vector2(delta.x,delta.z).length_squared()
		if horizontal<reach*reach:
			drop=maxf(drop,delta.y-sqrt(reach*reach-horizontal))
	if drop>0 or support_shift.length_squared()>.000001:
		if drop>maximum_body_drop and drop>.2 and "--verify-boss-rig" in OS.get_cmdline_user_args():
			print("QUAD BODY DROP / clip=",clip," clock=",clock," requested=",drop," applied=",minf(drop,.35)," stepping=",steps.keys()," held=",held.size())
		maximum_body_drop=maxf(maximum_body_drop,drop)
		var root=skeleton.find_bone("root");var pose=skeleton.get_bone_global_pose(root)
		pose.origin+=world.basis.inverse()*(support_shift-Vector3.UP*minf(drop,.35))
		skeleton.set_bone_global_pose(root,pose);skeleton.force_update_all_bone_transforms()
	for item in held:
		var hip=skeleton.get_bone_global_pose(item.upper).origin
		var old_knee=skeleton.get_bone_global_pose(item.lower).origin
		var ankle:Vector3=item.target.origin
		var delta=ankle-hip;var distance=delta.length()
		if distance>=item.a+item.b-.001:
			print("QUAD OVERREACH / clip=",clip," clock=",clock," foot=",item.key," distance=",distance," reach=",item.a+item.b," drop=",drop," target delta=",delta," stepping=",steps.has(item.key))
			unreachable+=1;anchors.erase(item.key);continue
		var direction=delta.normalized()
		var along=(item.a*item.a-item.b*item.b+distance*distance)/(2*distance)
		var pole=old_knee-hip;pole-=direction*pole.dot(direction)
		if pole.length_squared()<.00001:pole=Vector3.RIGHT-direction*direction.x
		var knee=hip+direction*along+pole.normalized()*sqrt(maxf(0,item.a*item.a-along*along))
		aim(skeleton,item.upper,hip,knee);aim(skeleton,item.lower,knee,ankle)
		skeleton.set_bone_global_pose(item.foot,item.target);skeleton.force_update_all_bone_transforms()
		maximum_length_error=maxf(maximum_length_error,maxf(absf(hip.distance_to(knee)-item.a),absf(knee.distance_to(ankle)-item.b)))
		maximum_contact_error=maxf(maximum_contact_error,(world*skeleton.get_bone_global_pose(item.foot)).origin.distance_to(anchors[item.key].origin))
