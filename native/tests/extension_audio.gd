extends SceneTree
const V=preload("res://scripts/survivor_voice.gd")
const E=preload("res://scripts/expedition.gd")
var events=[]
func _initialize():
	var voice=V.new()
	assert(not voice.eligible("resurrection",100))
	voice.hero_key="07"
	assert(voice.eligible("resurrection",100))
	voice.last_attempt.resurrection=100
	assert(not voice.eligible("resurrection",129))
	assert(voice.eligible("resurrection",130))
	assert(voice.chance("resurrection")<voice.chance("colossus_summoned"))
	assert(voice.chance("hurt")==.25 and voice.chance("level_up")==.65)
	voice.reset_run();assert(voice.last_attempt.is_empty())
	var g=E.new();g.setup(5,"expedition",{},17)
	g.voice_event.connect(func(event):events.append(event))
	for j in range(4):g.companions.summon(g,"u00")
	assert(events.count("first_summon")==1)
	for j in range(3):g.companions.units[j].hp=0
	g.companions.update(g,.1)
	assert(events.count("army_losses")==1)
	g.companions.souls=99
	var enemy=g.spawn_enemy(false,g.pos+Vector2(200,0),0,false)
	g.companions.on_kill(g,enemy)
	assert(events.has("army_empowered"))
	assert(not preload("res://scripts/content_extension.gd").data.voices.is_empty())
	voice.free()
	print("Extension audio policy and event hooks passed")
	quit()
