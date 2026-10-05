extends SceneTree
var checks = 0
var failures = 0

func check(condition, message):
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize():
	call_deferred("run_checks")

func run_checks():
	var voice = preload("res://scripts/survivor_voice.gd").new()
	voice.seed_value = 1729
	root.add_child(voice)
	for event in voice.COUNTS:
		check(voice.bank[event].size()==voice.COUNTS[event],"Missing voice variants for "+event)
		for clip in voice.bank[event]: check(clip.get_length()>0.1,"Empty voice clip")
	voice.enabled = false
	check(not voice.eligible("death",20,true),"Disabled audio must suppress even forced speech")
	voice.enabled = true
	check(not voice.eligible("unknown",20,true),"Unknown event must be rejected")
	voice.last_event.hurt = 10.0
	check(not voice.eligible("hurt",15.0),"Hurt cooldown must suppress chatter")
	check(voice.eligible("hurt",23.0),"Hurt recovers after cooldown")
	voice.current_event = "level_up"
	check(not voice.eligible("hurt",99.0),"Incidental speech cannot overlap")
	check(voice.eligible("boss_spawn",99.0),"Boss event cannot be rejected by incidental speech")
	voice.current_event = ""
	var previous = -1
	for i in range(60):
		var variant = voice.pick_variant("hurt")
		check(variant>=0 and variant<3,"Variant outside bank")
		check(variant!=previous,"Consecutive duplicate speech variant")
		previous = variant
	check(voice.play_event("boss_spawn",true),"Boss speech must start")
	check(voice.current_event=="boss_spawn","Boss speech not active")
	check(voice.play_event("boss_killed",true),"Boss killed line must queue")
	check(voice.pending=="boss_killed","Queued boss event lost")
	check(voice.play_event("death",true),"Death speech must interrupt")
	check(voice.current_event=="death" and voice.pending.is_empty(),"Death failed to clear prior chatter")
	voice.reset_run()
	check(voice.current_event.is_empty() and voice.pending.is_empty(),"Run reset leaked speech")
	voice.observe_health(.2)
	check(not voice.low_health_armed,"Low health warning did not latch")
	voice.stop()
	voice.observe_health(.19)
	check(voice.current_event.is_empty(),"Low health repeats without recovery")
	voice.observe_health(.5)
	check(voice.low_health_armed,"Healing did not re-arm low health warning")
	voice.stop()
	voice.free()
	voice = null
	await create_timer(0.15).timeout
	print("Survivor voice: %s checks / %s failures"%[checks,failures])
	quit(failures)
