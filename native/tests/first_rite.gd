extends SceneTree
const Rite=preload("res://scripts/first_rite.gd")
const E=preload("res://scripts/expedition.gd")
func _initialize():
	var g=E.new();g.setup(5,"expedition",{},42)
	var boss={"boss":true,"dead":true}
	g.boss_stage=1
	for pair in [["cradle","thorn"],["frostbreak","hunt"],["observatory","warden"]]:assert(Rite.variant(pair[0])==pair[1])
	assert(Rite.eligible(g,boss,{}))
	assert(not Rite.eligible(g,{"boss":true,"dead":false},{}))
	assert(not Rite.eligible(g,boss,{"settings":{Rite.SEEN_FLAG:true}}))
	g.boss_stage=3;assert(not Rite.eligible(g,boss,{}))
	g.boss_stage=1;g.hero=1;assert(not Rite.eligible(g,boss,{}))
	print("FIRST RITE / 8 checks passed");quit()
