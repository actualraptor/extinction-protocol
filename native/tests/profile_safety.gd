extends SceneTree
const Store=preload("res://scripts/profile_store.gd")
var checks=0
var errors=0
var dir="res://build/profile-fixtures-"+str(Time.get_ticks_usec())
var path=""
func check(ok,message):
	checks+=1
	if not ok: errors+=1;push_error(message)
func write(where,text):
	var f=FileAccess.open(where,FileAccess.WRITE);f.store_string(text);f.close()
func _initialize():
	DirAccess.make_dir_recursive_absolute(dir)
	path=dir+"/progress.json"
	var result=Store.load_profile(path)
	check(not result.blocked and result.data.amber==0,"Fresh profile")
	var legacy={"version":1,"amber":523,"runs":3,"research":{"future_track":9},"records":[{"hero":"KAEL","score":50}],"future_feature":{"keep":true}}
	write(path,JSON.stringify(legacy))
	result=Store.load_profile(path)
	check(result.data.version==2 and result.data.amber==523,"Legacy migration preserves balance")
	check("kael" in result.data.unlocks and "ballistics" in result.data.unlocks,"Legacy equipment retained")
	check(result.data.future_feature.keep and result.data.research.future_track==9,"Unknown fields retained")
	var profile=result.data
	profile.unlocks.append("future_unlock")
	profile.recipes.append("whiteout")
	check(Store.save_profile(path,profile)=="","Save migrated profile")
	profile.amber=700
	check(Store.save_profile(path,profile)=="","Overwrite primary atomically")
	check(Store.read_file(path).data.amber==700,"New primary committed")
	check(Store.read_file(dir+"/progress.backup.json").data.amber==523,"Previous valid primary backed up")
	write(path,'{"version":2,"amber":')
	result=Store.load_profile(path)
	check(not result.blocked and result.data.amber==523,"Truncated primary recovered")
	check("future_unlock" in result.data.unlocks and "whiteout" in result.data.recipes,"Recovered unlocks and recipes preserved")
	check(Store.save_profile(path,result.data)=="","Recovery can be committed")
	for i in range(3):
		write(path,"garbage")
		result=Store.load_profile(path)
		check(not result.blocked and result.data.amber==523,"Repeated corruption retains known good backup")
		check(Store.save_profile(path,result.data)=="","Repeated recovery saves")
	DirAccess.remove_absolute(path)
	result=Store.load_profile(path)
	check(not result.blocked and result.data.amber==523,"Missing primary recovered from backup")
	var pending=result.data.duplicate(true);pending.amber=888
	write(dir+"/progress.tmp",JSON.stringify(pending))
	result=Store.load_profile(path)
	check(result.data.amber==888,"Interrupted commit recovered from complete pending write")
	check(Store.save_profile(path,result.data)=="","Pending recovery committed")
	check(Store.read_file(dir+"/progress.backup.json").data.amber==888,"Pending source backed up before rewrite")
	write(dir+"/progress.tmp","truncated")
	check(Store.load_profile(path).data.amber==888,"Valid primary wins over incomplete pending")
	write(path,JSON.stringify({"version":99,"amber":999}))
	result=Store.load_profile(path)
	check(result.blocked,"Future schema protected rather than rolling back")
	check(Store.save_profile(path,profile)!="" and Store.read_file(path).state=="future","Future primary not overwritten")
	for bad in [{"version":2,"research":[]},{"version":2,"unlocks":[17]},{"version":2,"campaign":{"kills":"lots"}},{"version":2,"settings":{"music":"yes"}},{"version":2,"records":[{"score":"oops"}]}]:
		var malformed=profile.duplicate(true)
		malformed.merge(bad,true)
		check(not Store.validate(malformed),"Malformed nested values rejected")
	write(path,"broken");write(dir+"/progress.tmp","broken");write(dir+"/progress.backup.json","broken")
	check(Store.load_profile(path).blocked,"All invalid sources block destructive reset")
	check(not Store.validate({"version":2}),"Incomplete current schema is not silently reset")
	check(not Store.validate({"version":1.5}),"Fractional schema rejected")
	var app=preload("res://scripts/main.gd").new()
	app.progress_path=path
	app.load_progress()
	check(app.save_blocked and not app.save_error.is_empty(),"Application blocks saving when recovery fails")
	app.save_data.amber=99999
	app.persist()
	check(FileAccess.get_file_as_string(path)=="broken","Application never overwrites failed recovery")
	app.progress_path=dir+"/integration.json"
	app.load_progress()
	app.save_data.amber=78
	app.save_data.unlocks.append("iona")
	app.persist()
	app.load_progress()
	check(not app.save_blocked and app.save_data.amber==78 and "iona" in app.save_data.unlocks,"Application save/reload integration")
	app.free()
	print("PROFILE SAFETY: %s checks, %s failures; fixtures: %s"%[checks,errors,dir])
	quit(errors)
