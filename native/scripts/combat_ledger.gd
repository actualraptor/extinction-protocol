extends RefCounted
## One-second buckets keep telemetry bounded, even during thousand-enemy waves.
var totals = {}
var buckets = {}
var started = {}
var casts = {}
var retired = {}

func record(id,amount,now):
	totals[id] = totals.get(id,0.0)+amount
	if not buckets.has(id): buckets[id] = {}
	var second = int(now)
	var new_second = not buckets[id].has(second)
	buckets[id][second] = buckets[id].get(second,0.0)+amount
	if new_second:
		for key in buckets[id].keys():
			if key<second-5: buckets[id].erase(key)

func cast(id,now):
	if not started.has(id): started[id] = now
	casts[id] = casts.get(id,0)+1

func recent(id,now):
	var total = 0.0
	for key in buckets.get(id,{}):
		if key>=int(now)-4: total += buckets[id][key]
	return total/5.0

func average(id,now): return totals.get(id,0.0)/maxf(1,retired.get(id,now)-started.get(id,0))
