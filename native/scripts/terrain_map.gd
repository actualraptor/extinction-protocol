extends RefCounted
## Repeating designed districts with seeded variants. Two-cell roads connect
## every district. One shared breadth-first flow field guides the whole horde.
const CELL = 64.0
const DIRS = [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
const FLOW_DIRS = [Vector2i(1,1),Vector2i(-1,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]
var seed_value = 1
var layout = 0
var flow = {}
var cached = {}
var goal = Vector2i(99999,99999)
var arena = Vector2.INF
var refresh = 0.0
var clearance = {}
var sight = {}

func cell(p): return Vector2i(floori(p.x/CELL),floori(p.y/CELL))
func center(c): return Vector2(c)*CELL+Vector2.ONE*CELL*0.5
func kind(c):
	if arena!=Vector2.INF and center(c).distance_squared_to(arena)<810*810: return 0
	if cached.has(c): return cached[c]
	var x = posmod(c.x,16)
	var y = posmod(c.y,16)
	var district = Vector2i(floori(c.x/16.0),floori(c.y/16.0))
	var h = absi(district.x*73856093 ^ district.y*19349663 ^ seed_value)
	var variant=h%3
	if variant==1:
		var swapped=x;x=y;y=swapped
	elif variant==2:
		x=15-x
	var result = 0
	# Crossroads and central clearing are always open. Broken L-shaped ridges
	# make funnels without ever enclosing a walkable tile.
	if center(c).length()>240 and x>1 and y>1:
		if (x==5 and y>=4 and y<=10 and y!=7) or (y==10 and x>=5 and x<=11 and x!=8): result = 1
		elif x>=10 and x<=13 and y>=4 and y<=6: result = 2 if h%2==0 else 3
	if layout==1:
		result=0
		# Long shelves with wide, regularly spaced north/south passages.
		if center(c).length()>260 and y in [5,6,12] and x>2 and x<13 and x not in [7,8]: result=1
	elif layout==2:
		result=0
		# Open courtyards; four three-cell gates prevent sealed rooms.
		if center(c).length()>520 and ((x in [3,12] and y>=3 and y<=12 and y not in [6,7,8]) or (y in [3,12] and x>=3 and x<=12 and x not in [6,7,8])): result=1
	if variant==2 and center(c).length()>520 and x>2 and y>2:
		if layout==0: result=1 if (x in [5,6,11] and y in [4,5,10,11]) else 0
		elif layout==1: result=1 if (x in [4,5,11,12] and y in [4,5,11,12]) else 0
		elif layout==2: result=1 if (y in [4,11] and x in [4,5,6,10,11,12]) else 0
	cached[c] = result
	return result

func walkable(p,radius = 14.0):
	var a = Vector2i(floori((p.x-radius)/CELL),floori((p.y-radius)/CELL))
	var b = Vector2i(floori((p.x+radius)/CELL),floori((p.y+radius)/CELL))
	if kind(a)==1: return false
	if a==b: return true
	return kind(b)!=1 and kind(Vector2i(a.x,b.y))!=1 and kind(Vector2i(b.x,a.y))!=1

func move(p,delta,radius = 14.0):
	var end = p+delta
	if delta.length_squared()<400 and walkable(end,radius): return end
	# Substeps prevent tunnelling when a test or a slow frame supplies a large dt.
	var steps = maxi(1,ceili(delta.length()/20.0))
	var step = delta/steps
	for i in range(steps):
		var next = p+Vector2(step.x,0)
		if walkable(next,radius): p.x = next.x
		next = p+Vector2(0,step.y)
		if walkable(next,radius): p.y = next.y
	return p

func open_position(p):
	if walkable(p,22): return p
	for r in range(1,10):
		for d in DIRS:
			var candidate = center(cell(p)+d*r)
			if walkable(candidate,22): return candidate
	return Vector2.ZERO

func update(dt,p):
	refresh -= dt
	var c = cell(p)
	if c==goal and refresh>0: return
	goal = c
	refresh = 0.5
	flow.clear()
	sight.clear()
	flow[c] = Vector2.ZERO
	var queue = [c]
	var cursor = 0
	while cursor<queue.size():
		var at = queue[cursor]
		cursor += 1
		for d in FLOW_DIRS:
			var next = at+d
			if absi(next.x-c.x)>20 or absi(next.y-c.y)>20 or flow.has(next) or kind(next)==1: continue
			if d.x!=0 and d.y!=0 and (kind(at+Vector2i(d.x,0))==1 or kind(at+Vector2i(0,d.y))==1): continue
			flow[next] = -Vector2(d)
			queue.append(next)
	if cached.size()>16000: cached.clear()

func direction(p,target,identity = 0):
	var c = cell(p)
	if c==goal: return (target-p).normalized()
	if not sight.has(c): sight[c] = line_clear(center(c),center(goal))
	if sight[c] and walkable(p+(target-p).normalized()*24,10): return (target-p).normalized()
	if flow.has(c):
		var next = center(c)+flow[c]*CELL
		if identity!=0: next += Vector2(posmod(identity*13,37)-18,posmod(identity*29,37)-18)
		return (next-p).normalized()
	return (target-p).normalized()

func line_clear(a,b):
	var steps = maxi(1,ceili(a.distance_to(b)/32))
	for i in range(1,steps+1):
		if not walkable(a.lerp(b,float(i)/steps),10): return false
	return true
