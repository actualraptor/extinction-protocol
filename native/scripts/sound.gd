extends Node

# Reversible starter-only sound pass. False restores all three original banks.
const NEW_STARTER_AUDIO = true
var starter_variants = {}
var starter_variant_index = {}

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
var halloween = false
var voice_duck = false
var seasonal_music_start = 11

func _ready():
	for i in range(28):
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	var ids = "revolver shotgun frost fire lightning club spear orbital mortar pyre winter miasma dread aegis stasis impact_frost impact_fire impact_metal thermal reel_tick hit kill level evolve boss loot freeze magnet nuke frenzy rarity_0 rarity_1 rarity_2 rarity_3 rarity_4 rarity_5".split(" ")
	ids.append_array(["thunderstorm","thunder_hit","chain_tick","venom_spit","ricochet","return","harpoon","lantern","glacier","sunbow"])
	for id in ids: bank[id] = load("res://assets/audio/"+id+".wav")
	bank.pumpkin_smash = load("res://assets/audio/pumpkin_smash.wav")
	for id in "revolver shotgun frost fire lightning club spear orbital mortar pyre winter miasma dread aegis stasis thunderstorm thunder_hit chain_tick ricochet return harpoon lantern glacier sunbow thorns breakable impact_frost impact_fire impact_metal".split(" "):
		bank[id]=load("res://assets/audio/"+id+"_08.wav")
	bank.thornking=bank.thorns
	bank.gun = bank.revolver
	for pair in [["whiteout","lightning"],["supernova","mortar"],["lastword","shotgun"],["earthshaker","club"],["bastion","orbital"]]: bank[pair[0]] = bank[pair[1]]
	# Apply after evolution aliases so other weapon sounds remain unchanged.
	if NEW_STARTER_AUDIO:
		for id in ["revolver","lightning","chain_tick"]:
			starter_variants[id]=[]
			for suffix in ["","_v1","_v2"]:
				starter_variants[id].append(load("res://assets/audio/"+id+"_0113"+suffix+".wav"))
			bank[id]=starter_variants[id][0]
		bank.gun=bank.revolver
	for role in ["blade","guard","bow","wraith","heavy"]:
		var id="unit_"+role
		starter_variants[id]=[]
		for suffix in ["","_v1","_v2"]:
			starter_variants[id].append(load("res://assets/audio/"+id+suffix+".wav"))
		bank[id]=starter_variants[id][0]
	var tracks=["music_cradle","music_extinction_layer"]
	for map in range(3):
		for depth in range(3): tracks.append("frontier_%s_%s"%[map,depth])
	seasonal_music_start = tracks.size()
	for map in range(3):
		for depth in range(3): tracks.append("hollow_%s_%s"%[map,depth])
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
	if halloween and id in ["club","earthshaker"]: id = "pumpkin_smash"
	if not enabled or not bank.has(id): return
	var now = Time.get_ticks_msec()
	var interval = 110 if id.begins_with("impact_") else 300 if id in ["pyre","winter","miasma","dread","orbital"] else 45
	if id.begins_with("unit_"):interval=150 if id!="unit_heavy" else 300
	if now-last_played.get(id,-10000)<interval: return
	last_played[id] = now
	if id in ["lightning","thunder_hit","shotgun","mortar","frost"]: music_duck = 0.14
	var voice = voices[next_voice]
	next_voice = (next_voice+1)%voices.size()
	voice.stream = sound_stream(id)
	voice.volume_db = volume-5 if id.begins_with("impact_") else volume-4 if id in ["pyre","winter","miasma","dread","orbital"] else volume
	if id.begins_with("unit_"):voice.volume_db=volume-3 if id!="unit_heavy" else volume
	if id not in ["boss","hit","level","evolve","loot","reel_tick","venom_spit"] and not id.begins_with("rarity_"): voice.volume_db -= 2
	var active_voices=0
	for other in voices:
		if other.playing: active_voices+=1
	voice.volume_db-=minf(7,active_voices*0.45)
	voice.pitch_scale = pitch
	voice.play()

func sound_stream(id):
	var variant_id="revolver" if id=="gun" else id
	if starter_variants.has(variant_id):
		var index=starter_variant_index.get(variant_id,0)
		starter_variant_index[variant_id]=(index+1)%starter_variants[variant_id].size()
		return starter_variants[variant_id][index]
	return bank.get(id)

func _process(dt):
	music_duck = maxf(0,music_duck-dt)
	for i in range(music_players.size()):
		var audible = i==(seasonal_music_start if halloween else 0) if biome<0 else i==(seasonal_music_start if halloween else 2)+map_index*3+biome
		var target = (-16.0 if biome<0 else -15.0+tension) if music_enabled and audible else -80.0
		if music_duck>0: target -= 22.0 if music_duck>0.2 else 2.5
		if voice_duck: target -= 5.0
		music_players[i].volume_db = lerpf(music_players[i].volume_db,target,1-exp(-dt*3))

func shutdown():
	set_process(false)
	for voice in voices+music_players:
		voice.stop()
		voice.stream=null
	bank.clear()
	starter_variants.clear()
	starter_variant_index.clear()

func _exit_tree():
	shutdown()
