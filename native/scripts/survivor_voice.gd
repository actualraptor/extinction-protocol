extends Node
## A separate speech channel keeps Kael readable over dense combat sound.
## Call stop() when leaving Kael or starting a new run. Character gating belongs
## to the caller; this bank never changes survivor selection or gameplay RNG.
signal speech_started(duration: float)
signal speech_finished
signal event_started(event: String)

const COUNTS = {"chosen":3,"boss_spawn":3,"boss_killed":2,"death":2,"hurt":3,"level_up":3,"low_hp":2}
const PRIORITY = {"chosen":60,"boss_spawn":70,"boss_killed":80,"death":100,"hurt":10,"level_up":20,"low_hp":40}
const CHANCE = {"hurt":0.25,"level_up":0.65}
const COOLDOWN = {"chosen":2.0,"boss_spawn":1.0,"boss_killed":1.0,"death":0.0,"hurt":12.0,"level_up":18.0,"low_hp":45.0}
const PROFILE_EVENTS = {
	"first_summon":{"chance":1.0,"cooldown":0.0,"priority":60},
	"army_empowered":{"chance":.45,"cooldown":45.0,"priority":30},
	"colossus_summoned":{"chance":.65,"cooldown":60.0,"priority":60},
	"army_losses":{"chance":.60,"cooldown":40.0,"priority":35},
	"resurrection":{"chance":.15,"cooldown":30.0,"priority":20},
	"fatal_prevented":{"chance":1.0,"cooldown":90.0,"priority":85},
	"final_evolution":{"chance":1.0,"cooldown":5.0,"priority":80}
}
const Extension=preload("res://scripts/content_extension.gd")
var last_attempt = {}

func priority(event):return PROFILE_EVENTS[event].priority if PROFILE_EVENTS.has(event) else PRIORITY.get(event,0)
func cooldown(event):return PROFILE_EVENTS[event].cooldown if PROFILE_EVENTS.has(event) else COOLDOWN.get(event,0.0)
func chance(event):return PROFILE_EVENTS[event].chance if PROFILE_EVENTS.has(event) else CHANCE.get(event,1.0)

const GLOBAL_GAP = 3.0
const LOW_HEALTH = 0.25
const HEALTH_REARM = 0.40
const HERO_KEYS=["voss","kael","vesper","iona","orin"]
var hero_key="kael"
var hero_registry={}
var enabled = true
var seed_value = -1
var rng = RandomNumberGenerator.new()
var bank: Dictionary = {}
var last_event: Dictionary = {}
var last_variant: Dictionary = {}
var last_started = -1000.0
var low_health_armed = true
var pending = ""
var current_event = ""
var player: AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if seed_value >= 0: rng.seed = seed_value
	else: rng.randomize()
	player = AudioStreamPlayer.new()
	player.volume_db = -5.0
	add_child(player)
	player.finished.connect(_finished)
	hero_registry=JSON.parse_string(FileAccess.get_file_as_string("res://assets/voices/manifest.json"))
	_load_bank()

func set_hero(index):
	var key=HERO_KEYS[index] if index>=0 and index<HERO_KEYS.size() else Extension.PROFILE if index==5 else ""
	if key==hero_key:return
	reset_run()
	hero_key=key
	_load_bank()

func _load_bank():
	bank.clear()
	if hero_key==Extension.PROFILE:
		for event in Extension.data.get("voices",{}):
			bank[event]=[]
			for index in range(int(Extension.data.voices[event])):
				var clip=Extension.voice(event,index+1)
				if clip!=null:bank[event].append(clip)
		return
	for event in hero_registry.get(hero_key,{}):
		bank[event] = []
		for index in range(hero_registry[hero_key][event]):
			var clip = load("res://assets/voices/%s/%s_%s_%s.mp3"%[hero_key,hero_key,event,index+1])
			if clip != null: bank[event].append(clip)

func now():
	return Time.get_ticks_msec()/1000.0

func eligible(event: String, at: float, force = false):
	if not enabled or (not COUNTS.has(event) and not (hero_key==Extension.PROFILE and PROFILE_EVENTS.has(event))): return false
	if force: return true
	if at-float(last_event.get(event,-1000.0)) < cooldown(event): return false
	if PROFILE_EVENTS.has(event) and at-float(last_attempt.get(event,-1000.0)) < cooldown(event):return false
	# Major announcements have no random/global-gap rejection. A single priority
	# queue guarantees they get heard without several simultaneous voice lines.
	if priority(event) >= 60: return true
	return current_event.is_empty() and pending.is_empty() and at-last_started >= GLOBAL_GAP

func pick_variant(event: String):
	var count = bank.get(event,[]).size()
	if count == 0: return -1
	var pick = rng.randi_range(0,count-1)
	if count > 1 and pick == last_variant.get(event,-1):
		pick = (pick+1+rng.randi_range(0,count-2))%count
	last_variant[event] = pick
	return pick

func play_event(event: String, force = false):
	var at = now()
	if not eligible(event,at,force) or bank.get(event,[]).is_empty(): return false
	if PROFILE_EVENTS.has(event):last_attempt[event]=at
	if not force and rng.randf() >= chance(event): return false
	if current_event == "death" and event != "chosen": return false
	if event == "death":
		pending = ""
		if player.playing:
			player.stop()
			speech_finished.emit()
		current_event = ""
	elif player.playing:
		if priority(event) < 60: return false
		if pending.is_empty() or priority(event) >= priority(pending): pending = event
		else: return false
		last_event[event] = at
		return true
	last_event[event] = at
	_start(event)
	return true

func _start(event: String):
	var index = pick_variant(event)
	if index < 0: return
	current_event = event
	last_started = now()
	player.stream = bank[event][index]
	player.pitch_scale = 1.0
	player.play()
	speech_started.emit(player.stream.get_length())
	event_started.emit(event)

func _finished():
	current_event = ""
	speech_finished.emit()
	if not pending.is_empty():
		var event = pending
		pending = ""
		_start(event)

func observe_health(ratio: float):
	if ratio >= HEALTH_REARM: low_health_armed = true
	if ratio > 0.0 and ratio <= LOW_HEALTH and low_health_armed:
		# Retain the armed state if a higher-priority line is active. The warning
		# may play on a later health observation; it never repeats until recovery.
		if play_event("low_hp"): low_health_armed = false

func stop():
	pending = ""
	var was_speaking = not current_event.is_empty()
	current_event = ""
	if player != null:
		player.stop()
		player.stream = null
	if was_speaking: speech_finished.emit()

func reset_run():
	stop()
	last_event.clear()
	last_attempt.clear()
	last_started = -1000.0
	low_health_armed = true
