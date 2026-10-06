extends RefCounted
## Transactional local profile storage. Unknown fields and unlock IDs survive updates.
const VERSION = 2
const Discoveries = preload("res://scripts/discoveries.gd")

static func defaults():
	return {"version":VERSION,"starter_rules":2,"amber":0,"wins":0,"runs":0,"research":{},"records":[],"daily_records":[],"settings":{"sound":true,"music":true,"shake":true,"hud_scale":1.0,"halloween":true},"campaign":{"kills":0,"bosses":0,"map_kills":{},"map_wins":{}}}

static func numeric(value):
	return (value is int or value is float) and is_finite(float(value)) and value >= 0

static func validate(data):
	if not data is Dictionary: return false
	if not numeric(data.get("version",0)) or (float(data.get("version",0)) != floor(float(data.get("version",0))) or int(data.get("version",0)) not in [1,VERSION]): return false
	if data.version==VERSION:
		for key in ["amber","wins","runs","research","records","settings","campaign","unlocks","discoveries","recipes"]:
			if not data.has(key): return false
	for key in ["amber","wins","runs"]:
		if data.has(key) and not numeric(data[key]): return false
	for key in ["research","settings","campaign"]:
		if data.has(key) and not data[key] is Dictionary: return false
	for key in ["discoveries","unlocks","recipes"]:
		if data.has(key):
			if not data[key] is Array: return false
			for id in data[key]:
				if not id is String: return false
	for value in data.get("research",{}).values():
		if not numeric(value): return false
	var settings=data.get("settings",{})
	for key in ["sound","music","shake","halloween","intro_seen","opening_0120_seen","noncanon_roster"]:
		if settings.has(key) and not settings[key] is bool: return false
	if settings.has("hud_scale") and not numeric(settings.hud_scale): return false
	for key in ["sfx_volume","music_volume","voice_volume","cinematic_volume"]:
		if settings.has(key) and (not numeric(settings[key]) or settings[key]>1):return false
	var campaign=data.get("campaign",{})
	for key in ["kills","bosses"]:
		if campaign.has(key) and not numeric(campaign[key]): return false
	for key in ["map_kills","map_wins","weapon_damage","survivor_runs"]:
		if campaign.has(key):
			if not campaign[key] is Dictionary: return false
			for value in campaign[key].values():
				if not numeric(value): return false
	for key in ["records","daily_records"]:
		if not data.has(key): continue
		if not data[key] is Array: return false
		for record in data[key]:
			if not record is Dictionary: return false
			for field in (["score"] if key=="records" else ["seconds","kills","score","bosses","circuit"]):
				if not numeric(record.get(field,0)): return false
			for field in ["date","hero","map","mode","ruleset"]:
				if record.has(field) and not record[field] is String: return false
	return true

static func migrate(data):
	var result=data.duplicate(true)
	var preserve_vesper=not data.has("starter_rules")
	var base=defaults()
	for key in base:
		if not result.has(key): result[key]=base[key]
	for key in ["settings","campaign"]:
		for field in base[key]:
			if not result[key].has(field): result[key][field]=base[key][field]
	result.settings.hud_scale=clampf(result.settings.hud_scale,0.65,1.35)
	for record in result.records:
		for field in {"date":"Unknown","hero":"Unknown","score":0,"mode":"expedition"}:
			if not record.has(field): record[field]={"date":"Unknown","hero":"Unknown","score":0,"mode":"expedition"}[field]
	for record in result.daily_records:
		for field in {"date":"Unknown","seconds":0,"kills":0,"score":0,"bosses":0,"circuit":1}:
			if not record.has(field): record[field]={"date":"Unknown","seconds":0,"kills":0,"score":0,"bosses":0,"circuit":1}[field]
	Discoveries.migrate(result)
	if preserve_vesper:
		if "vesper" not in result.unlocks:result.unlocks.append("vesper")
		if "vesper" not in result.discoveries:result.discoveries.append("vesper")
	result.starter_rules=2
	result.version=VERSION
	return result

static func read_file(path):
	if not FileAccess.file_exists(path): return {"state":"missing"}
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"state":"invalid"}
	var parser=JSON.new()
	var error=parser.parse(file.get_as_text())
	file.close()
	if error!=OK: return {"state":"invalid"}
	var data=parser.data
	if data is Dictionary and numeric(data.get("version",0)) and data.version>VERSION:
		return {"state":"future"}
	if not validate(data): return {"state":"invalid"}
	return {"state":"valid","data":migrate(data)}

static func load_profile(path):
	var paths=[path,path.get_basename()+".tmp",path.get_basename()+".backup.json"]
	var found=false
	for candidate in paths:
		var result=read_file(candidate)
		if result.state=="missing": continue
		found=true
		if result.state=="future":
			return {"data":migrate(defaults()),"blocked":true,"message":"This progress belongs to a newer game version. Update the game to continue saving.","source":candidate}
		if result.state=="valid":
			return {"data":result.data,"blocked":false,"message":"Recovered progress from a safety copy." if candidate!=path else "","source":candidate}
	return {"data":migrate(defaults()),"blocked":found,"message":"Progress could not be recovered. Existing files are protected; saving is disabled." if found else "","source":""}

static func save_profile(path,data):
	if not validate(data): return "Progress was not saved because its format is invalid. Existing progress is protected."
	var current=read_file(path)
	if current.state=="future": return "A newer game version saved this progress. Update before saving."
	var temporary=path.get_basename()+".tmp"
	var backup=path.get_basename()+".backup.json"
	# Keep a recovery source safe before replacing a pending transaction.
	if current.state!="valid" and read_file(temporary).state=="valid":
		if DirAccess.copy_absolute(temporary,backup)!=OK: return "Could not protect recovered progress. Saving was cancelled."
	var file=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return "Progress could not be saved on this device."
	file.store_string(JSON.stringify(migrate(data),"\t"))
	file.flush()
	var write_error=file.get_error()
	file.close()
	if write_error!=OK or read_file(temporary).state!="valid": return "Progress could not be verified. Previous progress is protected."
	if current.state=="valid":
		if DirAccess.copy_absolute(path,backup)!=OK: return "Could not create a safety copy. Previous progress is protected."
	elif current.state=="invalid":
		# Retain the damaged original for manual recovery instead of silently deleting it.
		var damaged=path+".damaged-"+str(Time.get_unix_time_from_system()).replace(".","-")
		if DirAccess.copy_absolute(path,damaged)!=OK: return "Could not preserve the damaged save. Saving was cancelled."
	if DirAccess.rename_absolute(temporary,path)!=OK: return "Progress could not be committed. A recovery copy is available."
	return ""
