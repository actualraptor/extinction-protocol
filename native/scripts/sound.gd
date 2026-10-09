extends Node

# Reversible starter-only sound pass. False restores all three original banks.
const NEW_STARTER_AUDIO = true
var starter_variants = {}
var starter_variant_index = {}

var enabled = true
var music_enabled = true
var bank = {}
var boss_roar_voice:AudioStreamPlayer
var boss_motion_scale=1.0
var boss_foley_voices=[]
var next_boss_foley=0
var ritual_voice:AudioStreamPlayer
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
const SOUNDTRACK = ["menu", "cradle", "frostbreak", "observatory", "thorn", "basalt", "hunt", "aurora", "warden", "bloom", "meteor"]
const BOSS_IDS = ["thorn", "basalt", "hunt", "aurora", "warden", "bloom"]
var encounter_id = ""
var encounter_time = 0.0
var encounter_paused = false
var clock_paused = false
var meteor_started = false
var sync_check = 0.0

func _ready():
	if "--beam-test" in OS.get_cmdline_user_args():
		var beam_audio=preload("res://scripts/beam_audio.gd").new();beam_audio.sound=self;add_child(beam_audio)
	for dinosaur in ["thorn","basalt","hunt","aurora","warden","bloom"]:
		for cue in ["step","windup","attack","impact","roar","death"]:
			var id="dino_"+dinosaur+"_"+cue
			bank[id]=load("res://assets/audio/"+id+".wav")
	if "--painted-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"):
		bank["dino_basalt_roar"]=load("res://assets/audio/trex_roar_heavy.wav")
		bank["trex_bite"]=load("res://assets/audio/trex_bite.wav")
		bank["trex_tail_swoosh"]=load("res://assets/audio/trex_tail_swoosh.wav")
		starter_variants["dino_basalt_step"]=[]
		for suffix in ["","_v1","_v2"]:starter_variants["dino_basalt_step"].append(load("res://assets/audio/trex_step"+suffix+".wav"))
	boss_roar_voice=AudioStreamPlayer.new();boss_roar_voice.bus="SFX";add_child(boss_roar_voice)
	if "--painted-rig-test" in OS.get_cmdline_user_args() or "--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework") or "--meteor-sound-study" in OS.get_cmdline_user_args():
		for index in range(6):
			var foley=AudioStreamPlayer.new();foley.bus="SFX";add_child(foley);boss_foley_voices.append(foley)
	ritual_voice=AudioStreamPlayer.new();ritual_voice.bus="SFX";add_child(ritual_voice)
	ritual_voice.stream=load("res://assets/audio/rite_hum.wav");ritual_voice.volume_db=-19
	for id in ["rite_crunch","rite_finish","rite_pulse","rite_lock"]:bank[id]=load("res://assets/audio/"+id+".wav")
	starter_variants["rite_crunch"]=[load("res://assets/audio/rite_crunch.wav"),load("res://assets/audio/rite_crunch_v1.wav"),load("res://assets/audio/rite_crunch_v2.wav")]
	for i in range(28):
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	var ids = "revolver shotgun frost fire lightning club spear orbital mortar pyre winter miasma dread aegis stasis impact_frost impact_fire impact_metal thermal reel_tick hit kill level evolve boss loot freeze magnet nuke frenzy rarity_0 rarity_1 rarity_2 rarity_3 rarity_4 rarity_5".split(" ")
	ids.append_array(["thunderstorm","thunder_hit","chain_tick","venom_spit","ricochet","return","harpoon","lantern","glacier","sunbow"])
	for id in ids: bank[id] = load("res://assets/audio/"+id+".wav")
	bank.level = load("res://assets/audio/level_0141.wav")
	bank.pumpkin_smash = load("res://assets/audio/pumpkin_smash.wav")
	for id in "revolver shotgun frost fire lightning club spear orbital mortar pyre winter miasma dread aegis stasis thunderstorm thunder_hit chain_tick ricochet return harpoon lantern glacier sunbow thorns breakable impact_frost impact_fire impact_metal".split(" "):
		bank[id]=load("res://assets/audio/"+id+"_08.wav")
	bank.thornking=bank.thorns
	bank.meteor_flare=bank.impact_fire
	bank.meteor_skyfall=bank.mortar
	bank.meteor_collapse=bank.thunder_hit
	bank.meteor_crash=bank.dino_basalt_step
	if OS.has_feature("meteor_rework") or "--meteor-rig-test" in OS.get_cmdline_user_args():
		for cue in ["flare","skyfall","collapse"]:
			var id="meteor_"+cue
			starter_variants[id]=[]
			for variant in range(3):
				var path="res://assets/audio/meteor/%s_%d.wav"%[id,variant]
				var stream=load(path) as AudioStreamWAV
				if stream!=null:starter_variants[id].append(stream)
			if not starter_variants[id].is_empty():bank[id]=starter_variants[id][0]
			else:starter_variants.erase(id)
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
	for id in SOUNDTRACK:
		var player = AudioStreamPlayer.new()
		var stream = load("res://assets/audio/soundtrack/"+id+".ogg").duplicate()
		stream.loop = id != "meteor"
		stream.loop_offset = 0.0
		player.stream = stream
		player.bus = "Music"
		player.volume_db = -80
		add_child(player)
		music_players.append(player)
		# Start only the selected cue; inactive tracks consume no decoder time.

func play(id,volume = -12.0,pitch = 1.0,_music = false):
	if id=="dino_basalt_death" and boss_roar_voice!=null:
		boss_roar_voice.stop()
		boss_roar_voice.stream=null
	if id=="rite_stop":ritual_voice.stop();return
	if id=="rite_hum":
		if enabled:ritual_voice.stream_paused=false;ritual_voice.play()
		return
	if halloween and id in ["club","earthshaker"]: id = "pumpkin_smash"
	if not enabled or not bank.has(id): return
	# The long roar must survive the rapid weapon voices instead of being stolen.
	if id=="dino_basalt_roar" and ("--painted-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")):
		boss_roar_voice.stream=bank[id];boss_roar_voice.volume_db=-2.0
		boss_roar_voice.stream_paused=false
		boss_roar_voice.pitch_scale=boss_motion_scale;boss_roar_voice.play();music_duck=.7
		return
	var now = Time.get_ticks_msec()
	var interval = 110 if id.begins_with("impact_") else 300 if id in ["pyre","winter","miasma","dread","orbital"] else 45
	if id.begins_with("unit_"):interval=150 if id!="unit_heavy" else 300
	if id.begins_with("meteor_"):interval=180
	if now-last_played.get(id,-10000)<interval: return
	last_played[id] = now
	if id in ["lightning","thunder_hit","shotgun","mortar","frost"]: music_duck = maxf(music_duck,0.14)
	var protected_foley=not boss_foley_voices.is_empty() and (id in ["trex_bite","trex_tail_swoosh"] or id.begins_with("dino_basalt_") or id.begins_with("dino_thorn_") or ("--meteor-sound-study" in OS.get_cmdline_user_args() and id in ["meteor_flare","meteor_skyfall","meteor_collapse"]))
	var voice = boss_foley_voices[next_boss_foley] if protected_foley else voices[next_voice]
	if protected_foley:next_boss_foley=(next_boss_foley+1)%boss_foley_voices.size()
	else:next_voice = (next_voice+1)%voices.size()
	voice.stream = sound_stream(id)
	if id=="meteor_crash":volume=-3.0
	voice.volume_db = volume-5 if id.begins_with("impact_") else volume-4 if id in ["pyre","winter","miasma","dread","orbital"] else volume
	if id.begins_with("unit_"):voice.volume_db=volume-3 if id!="unit_heavy" else volume
	if protected_foley and id.begins_with("meteor_"):voice.volume_db+=4.0
	if ("--painted-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")) and id=="dino_basalt_step":voice.volume_db+=6.0
	if ("--painted-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")) and id=="trex_tail_swoosh":voice.volume_db+=3.0
	if id not in ["boss","hit","level","evolve","loot","reel_tick","venom_spit"] and not id.begins_with("rarity_"): voice.volume_db -= 2
	var active_voices=0
	for other in voices:
		if other.playing: active_voices+=1
	voice.volume_db-=minf(2.0 if protected_foley else 7.0,active_voices*0.45)
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
	if not enabled:ritual_voice.stop()
	for foley in boss_foley_voices:
		if not enabled:foley.stop()
		foley.stream_paused=encounter_paused
	if boss_roar_voice!=null:
		if not enabled:boss_roar_voice.stop()
		boss_roar_voice.stream_paused=encounter_paused
	music_duck = maxf(0,music_duck-dt)
	if encounter_id != "meteor":meteor_started=false
	if encounter_paused != clock_paused:
		clock_paused=encounter_paused
		for player in music_players:player.stream_paused=clock_paused
	for i in range(music_players.size()):
		var audible = i==selected_music_index()
		var target = (-3.0 if biome<0 else -5.0+tension) if music_enabled and audible else -80.0
		if music_enabled and audible and not music_players[i].playing and not music_players[i].stream_paused:
			if i != 10:
				music_players[i].play()
			elif not meteor_started and encounter_time < 210.0:
				music_players[i].play(maxf(0,encounter_time))
				meteor_started=true
		var duck_db=22.0 if music_duck>.2 else 2.5 if music_duck>0 else 0.0
		if boss_roar_voice!=null and boss_roar_voice.playing:duck_db=maxf(duck_db,8.0)
		target-=duck_db
		if voice_duck: target -= 5.0
		music_players[i].volume_db = lerpf(music_players[i].volume_db,target,1-exp(-dt*3))
		if not audible and music_players[i].volume_db < -65.0:
			music_players[i].stop()
	sync_check+=dt
	if sync_check>=1.0:
		sync_check=0.0
		if encounter_id=="meteor" and not encounter_paused and music_players[10].playing:
			var offset=music_players[10].get_playback_position()+AudioServer.get_time_since_last_mix()
			if absf(offset-encounter_time)>0.35:music_players[10].seek(clampf(encounter_time,0,209.99))

func set_encounter(identity:String, elapsed:float, is_paused:bool, motion_scale:float=1.0):
	encounter_id=identity;encounter_time=elapsed;encounter_paused=is_paused
	boss_motion_scale=clampf(motion_scale,.7,1.0)
	if boss_roar_voice!=null and boss_roar_voice.playing:
		boss_roar_voice.pitch_scale=boss_motion_scale

func selected_music_index() -> int:
	# Depth and seasonal presentation retain the same approved map theme.
	if biome < 0:return 0
	if encounter_id=="meteor":return 10
	var boss_index=BOSS_IDS.find(encounter_id)
	if boss_index>=0:return 4+boss_index
	return 1+clampi(map_index,0,2)

func shutdown():
	set_process(false)
	var all_players=voices+music_players+boss_foley_voices
	if ritual_voice!=null:all_players.append(ritual_voice)
	if boss_roar_voice!=null:all_players.append(boss_roar_voice)
	for child in get_children():
		if child.has_method("shutdown"):child.shutdown()
	for voice in all_players:
		voice.stop()
		voice.stream=null
	bank.clear()
	starter_variants.clear()
	starter_variant_index.clear()

func _exit_tree():
	shutdown()
