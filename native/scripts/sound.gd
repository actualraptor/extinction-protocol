extends Node

var enabled = true
var music_enabled = true
var bank = {}
var voices = []
var next_voice = 0
var tension = 0.0
var music_players = []
var last_played = {}
var music_duck = 0.0
var biome = -1
var map_index = 0

func _ready():
	for i in range(28):
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	var ids = "revolver shotgun frost fire lightning club spear orbital mortar pyre winter miasma dread aegis stasis impact_frost impact_fire impact_metal thermal reel_tick hit kill level evolve boss loot freeze magnet nuke frenzy rarity_0 rarity_1 rarity_2 rarity_3 rarity_4 rarity_5".split(" ")
	ids.append_array(["thunderstorm","thunder_hit","chain_tick","venom_spit","ricochet","return","harpoon","lantern","glacier","sunbow"])
	for id in ids: bank[id] = load("res://assets/audio/"+id+".wav")
	for id in "revolver shotgun frost fire lightning club spear orbital mortar pyre winter miasma dread aegis stasis thunderstorm thunder_hit chain_tick ricochet return harpoon lantern glacier sunbow thorns breakable impact_frost impact_fire impact_metal".split(" "):
		bank[id]=load("res://assets/audio/"+id+"_08.wav")
	bank.thornking=bank.thorns
	bank.gun = bank.revolver
	for pair in [["whiteout","lightning"],["supernova","mortar"],["lastword","shotgun"],["earthshaker","club"],["bastion","orbital"]]: bank[pair[0]] = bank[pair[1]]
	var tracks=["music_cradle","music_extinction_layer"]
	for map in range(3):
		for depth in range(3): tracks.append("frontier_%s_%s"%[map,depth])
	for id in tracks:
		var player = AudioStreamPlayer.new()
		var stream = load("res://assets/audio/"+id+".wav").duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(round(stream.get_length()*stream.mix_rate))
		player.stream = stream
		player.volume_db = -80
		add_child(player)
		music_players.append(player)
		player.play()

func play(id,volume = -12.0,pitch = 1.0,_music = false):
	if not enabled or not bank.has(id): return
	var now = Time.get_ticks_msec()
	var interval = 110 if id.begins_with("impact_") else 300 if id in ["pyre","winter","miasma","dread","orbital"] else 45
	if now-last_played.get(id,-10000)<interval: return
	last_played[id] = now
	if id in ["lightning","thunder_hit","shotgun","mortar","frost"]: music_duck = 0.14
	var voice = voices[next_voice]
	next_voice = (next_voice+1)%voices.size()
	voice.stream = bank[id]
	voice.volume_db = volume-5 if id.begins_with("impact_") else volume-4 if id in ["pyre","winter","miasma","dread","orbital"] else volume
	if id not in ["boss","hit","level","evolve","loot","reel_tick","venom_spit"] and not id.begins_with("rarity_"): voice.volume_db -= 2
	var active_voices=0
	for other in voices:
		if other.playing: active_voices+=1
	voice.volume_db-=minf(7,active_voices*0.45)
	voice.pitch_scale = pitch
	voice.play()

func _process(dt):
	music_duck = maxf(0,music_duck-dt)
	for i in range(music_players.size()):
		var audible = i==0 if biome<0 else i==2+map_index*3+biome
		var target = (-16.0 if biome<0 else -15.0+tension) if music_enabled and audible else -80.0
		if music_duck>0: target -= 22.0 if music_duck>0.2 else 2.5
		music_players[i].volume_db = lerpf(music_players[i].volume_db,target,1-exp(-dt*3))
