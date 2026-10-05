extends SceneTree
const Icons=preload("res://scripts/atlas_icons.gd")
var checks=0
var failures=0
func check(ok,message):
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize():
	for category in ["weapon","passive","relic","boss"]:
		var list=Icons.WEAPONS if category=="weapon" else Icons.UPGRADES if category=="passive" else Icons.RELICS if category=="relic" else Icons.BOSSES
		for id in list:
			check(Icons.has_icon(id,category),"Unmapped registry entry "+category+":"+id)
			var texture=Icons.get_icon(id,category)
			check(texture!=null,"Missing extracted icon "+id)
			if texture==null:continue
			var image=texture.get_image()
			var used=image.get_used_rect()
			check(used.position.x>=10 and used.position.y>=10,"Insufficient safe icon padding "+id)
			check(used.end.x<=image.get_width()-10 and used.end.y<=image.get_height()-10,"Clipped icon border "+id)
	for id in Icons.BOSSES:
		check(Icons.has_icon(id,"boss",true),"Missing seasonal boss mapping "+id)
		check(Icons.get_icon(id,"boss",true)!=null,"Missing seasonal boss asset "+id)
	check(Icons.get_icon("map","relic")==Icons.get_icon("compass","weapon"),"Historic map entry must explicitly use map compass artwork")
	check(not Icons.has_icon("not-a-boss","boss"),"Unknown boss must not silently map to weapon art")
	for category in ["fusion","evolution"]:
		for id in ["whiteout","lastword","supernova","earthshaker","bastion"]:
			check(Icons.has_icon(id,category) and Icons.get_icon(id,category)==Icons.get_icon(id,"weapon"),"Invalid weapon transformation icon "+category+":"+id)
	check(Icons.get_icon("supplies","supplies")==Icons.get_icon("lens","relic"),"Supplies must intentionally use clean lens artwork")
	check(Icons.get_icon("spines","augment")==Icons.field(0),"Thorn augment must resolve explicitly")
	for release in preload("res://scripts/patch_notes.gd").releases():
		for entry in release.entries:
			check(Icons.has_icon(entry.icon,entry.get("category","weapon")),"Historic icon missing: "+release.version+" "+entry.icon)
	var catalog=load("res://scripts/catalog.gd")
	for id in catalog.WEAPONS:check(Icons.has_icon(id,"weapon"),"Missing gameplay weapon "+id)
	for id in catalog.PASSIVES:check(Icons.has_icon(id,"passive"),"Missing gameplay passive "+id)
	for id in catalog.AUGMENTS:check(Icons.has_icon(id,"augment"),"Missing gameplay augment "+id)
	for id in catalog.RESEARCH:check(Icons.has_icon(id,"research"),"Missing archive icon "+id)
	for id in catalog.RELICS:check(Icons.has_icon(id,"relic"),"Missing gameplay relic "+id)
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/clean-icons/manifest.json"))
	for record in manifest:
		check(ResourceLoader.exists("res://assets/clean-icons/"+record.file),"Extracted icon resource missing "+record.file)
		if record.file=="boss-thorn.png":check(record.source=="characters-v2.png" and record.grid_index==4,"Thorn icon must depict actual triceratops")
		if record.file=="boss-basalt.png":check(record.source=="monsters-04.png" and record.grid_index==6,"Basalt icon must depict actual golem")
		if record.file=="boss-meteor.png":check(record.source=="characters-v2.png" and record.grid_index==8,"Meteor icon must match final boss")
	print("Clean icon assets: %s checks / %s failures"%[checks,failures])
	quit(failures)
