extends RefCounted
## One boundary definition shared by the visible fire and damage check.
const DEADLINE=210.0
const INITIAL_RADIUS=1400.0
const LAST_REFUGE_RADIUS=180.0

static func remaining_at(elapsed:float)->float:
	return 1.0-pow(clampf(elapsed/DEADLINE,0,1),2)

static func base_radius_at(elapsed:float)->float:
	# The core occupies ground too. Keep a narrow last refuge around it
	# until the deadline, when the remaining ground ignites together.
	if elapsed>=DEADLINE:return 0.0
	return LAST_REFUGE_RADIUS+(INITIAL_RADIUS-LAST_REFUGE_RADIUS)*remaining_at(elapsed)

static func radius_at(elapsed:float,angle:float)->float:
	var remaining=remaining_at(elapsed)
	var weathering=sin(angle*7+1.2)*18+sin(angle*13-.7)*11
	return maxf(0.0,base_radius_at(elapsed)+weathering*remaining)

static func burning(point:Vector2,center:Vector2,elapsed:float)->bool:
	var delta=point-center
	return elapsed>=DEADLINE or delta.length()>radius_at(elapsed,delta.angle())

static func damage_fraction(elapsed:float)->float:
	# Brief contact is recoverable. Once the world is consumed, each
	# successive second becomes substantially harder to survive.
	var overtime=maxf(0,elapsed-DEADLINE)
	return minf(1.0,.08+.025*pow(overtime,1.35))
