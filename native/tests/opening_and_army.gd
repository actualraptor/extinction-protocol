extends SceneTree
const Opening=preload("res://scripts/opening_story.gd")
const Store=preload("res://scripts/profile_store.gd")
const Meter=preload("res://scripts/companion_meter.gd")
const Extension=preload("res://scripts/content_extension.gd")
const Expedition=preload("res://scripts/expedition.gd")
var checks=0
func check(condition,message):
	checks+=1
	if not condition:
		push_error(message)
		quit(1)
		assert(condition,message)
func _initialize():call_deferred("run")
func run():
	check(Opening.available(),"Intro assets are packaged")
	var profile=Store.migrate(Store.defaults())
	check(Opening.first_play(profile,[]),"Fresh profiles play opening")
	check(not Opening.first_play(profile,["--verify-package"]),"Verification never starts opening")
	check(not Opening.first_play(profile,["--capture"]),"Capture keeps existing behavior")
	profile.settings.intro_seen=true
	check(not Opening.first_play(profile,[]),"Seen intro does not repeat")
	check(Store.migrate(profile).settings.intro_seen,"Migration preserves seen state")
	check(Store.validate(profile),"Seen state is a valid profile")
	profile.settings.intro_seen="true"
	check(not Store.validate(profile),"Malformed seen state cannot corrupt progression")
	for pair in [[0,0],[12.01,1],[26.25,2],[38.52,3],[47.16,4],[63.9,4]]:
		check(Opening.shot_at(pair[0])==pair[1],"Scene follows narration cues")
	var counts=Meter.census([
		{"hp":10,"role":"warrior","temporary":0},
		{"hp":0,"role":"warrior","temporary":0},
		{"hp":10,"role":"guard","temporary":2,"expires":5},
		{"hp":10,"role":"archer","temporary":2,"expires":20},
		{"hp":10,"role":"colossus","temporary":0}],10)
	check(counts.total==3 and counts.warrior==1 and counts.guard==0 and counts.archer==1 and counts.colossus==1,"Counter only includes live, unexpired summons")
	Extension.install(preload("res://scripts/catalog.gd"))
	var clips=0
	for event in Extension.data.voices:
		for index in range(Extension.data.voices[event]):
			var clip=Extension.voice(event,index+1)
			check(clip!=null and clip.get_length()>.1,"Recorded event clip loads")
			clips+=1
	check(clips==27,"All supplied event recordings packaged")
	var g=Expedition.new();g.setup(5,"expedition",{},101)
	var army=g.companions
	var tracked_unit={"uid":123,"source":"u00","role":"warrior","champion":false}
	army.credit(tracked_unit,120,true)
	army.credit(tracked_unit,80,false)
	var other={"uid":124,"source":"u02","role":"archer","champion":false}
	army.credit(other,250,true)
	check(army.army_report().strongest_summon.uid==124,"Actual damage selects strongest individual")
	army.credit(tracked_unit,100,true)
	check(army.army_report().strongest_summon.uid==123 and army.army_report().strongest_summon.kills==2,"Cumulative damage can reclaim strongest slot")
	army.raised_by_ability={"u00":1928391823,"u02":4}
	var snapshot=army.army_report()
	check(snapshot.total_summoned==1928391827,"Summon totals preserve large integer counts")
	army.raised_by_ability.u02=5
	check(snapshot.summoned_by_ability.u02==4,"Exported army stats are independent snapshots")
	check(g.report().army.total_summoned==1928391828,"Run report exports army telemetry")
	var sounds=[]
	g.sound.connect(func(id):sounds.append(id))
	var unit={"p":g.pos,"role":"warrior"}
	g.companions.attack_sound(g,unit)
	g.companions.attack_sound(g,unit)
	check(sounds==["unit_blade"],"Army sound burst is bounded")
	g.time+=.2;unit.role="archer";g.companions.attack_sound(g,unit)
	check(sounds.back()=="unit_bow","Archers release bow sounds")
	unit.role="colossus";g.companions.attack_sound(g,unit)
	check(sounds.back()=="unit_heavy","Heavy impacts retain their distinct sound")
	unit.p=g.pos+Vector2(2000,0);g.time+=1;var before=sounds.size();g.companions.attack_sound(g,unit)
	check(sounds.size()==before,"Distant army attacks do not clutter sound mix")
	var opening=Opening.new();opening.external_clock=true;root.add_child(opening)
	check(opening.pages.size()==5,"Five storybook pages load")
	for at in [0.0,13.0,27.0,39.0,48.0,61.5,63.5]:
		opening.clock=at;opening.update_frame()
		check(opening.pages[Opening.shot_at(at)].visible,"Correct painting renders at cue")
	opening.free()
	print("Opening and army: %s checks passed; %s recorded clips"%[checks,clips])
	quit()
