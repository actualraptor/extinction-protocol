extends SceneTree
const Sound=preload("res://scripts/sound.gd")
var failures=0
var checks=0
func check(ok,message):
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize(): call_deferred("run")
func run():
	var sound=Sound.new()
	root.add_child(sound)
	for id in ["revolver","lightning","chain_tick"]:
		var paths=[]
		for i in range(4):
			var stream=sound.sound_stream(id)
			check(stream!=null,"Missing starter audio stream")
			check(stream.get_length()>.08 and stream.get_length()<.4,"Starter sample too long for rapid repeat attacks")
			if i<3:paths.append(stream.resource_path)
			else:check(stream.resource_path==paths[0],"Starter variation cycle failed")
		check(paths[0]!=paths[1] and paths[1]!=paths[2],"Repeated waveform paths instead of variations")
	check(sound.bank.whiteout.resource_path.ends_with("lightning_08.wav"),"Evolution bank changed unintentionally")
	check(sound.bank.shotgun.resource_path.ends_with("shotgun_08.wav"),"Other gun bank changed")
	check(sound.bank.thunder_hit.resource_path.ends_with("thunder_hit_08.wav"),"Thunderstorm bank changed")
	check(sound.bank.gun==sound.bank.revolver,"Voss gun alias did not follow starter bank")
	sound.shutdown()
	sound.queue_free()
	await create_timer(.15).timeout
	print("Starter audio: %s checks / %s failures"%[checks,failures])
	quit(failures)
