extends SceneTree

const Sound = preload("res://scripts/sound.gd")

func _initialize():
	call_deferred("run")

func run():
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count-1,"Music")
	var audio=Sound.new()
	root.add_child(audio)
	audio.set_process(false)
	assert(audio.music_players.size()==11)
	for i in range(11):
		var stream=audio.music_players[i].stream
		assert(stream is AudioStreamOggVorbis and stream.loop==(i!=10) and stream.loop_offset==0)
		var playback=stream.instantiate_playback()
		playback.start(stream.get_length()-0.04)
		var frames=playback.mix_audio(1.0,8192)
		assert(frames.size()==8192 if i!=10 else frames.size()>=1500 and frames.size()<8192)
		assert(playback.get_loop_count()>0 if i!=10 else playback.get_loop_count()==0)
		var energy=0.0
		var jump=0.0
		for j in range(frames.size()):
			energy+=frames[j].length_squared()
			if j>0:jump=maxf(jump,(frames[j]-frames[j-1]).length())
		assert(energy>0.01 and jump<0.3)
		print("PASS decoded loop / ",Sound.SOUNDTRACK[i]," / seconds ",stream.get_length()," / max adjacent jump ",jump)
		playback.stop()
		playback=null
	for map in range(3):
		for depth in range(3):
			for seasonal in [false,true]:
				audio.biome=depth;audio.map_index=map;audio.halloween=seasonal
				assert(audio.selected_music_index()==map+1)
				for j in range(16):audio._process(0.25)
				for i in range(11):assert(audio.music_players[i].playing==(i==map+1))
	print("PASS correct map selection at every depth and seasonal setting / inactive decoders stopped")
	audio.biome=-1
	for j in range(16):audio._process(0.25)
	assert(audio.music_players[0].playing)
	for i in range(1,11):assert(not audio.music_players[i].playing)
	audio.music_players[0].stream_paused=true
	audio._process(0.25)
	assert(audio.music_players[0].stream_paused)
	audio.music_players[0].stream_paused=false
	audio.music_enabled=false
	for j in range(16):audio._process(0.25)
	assert(audio.music_players[0].volume_db < -65)
	audio.music_enabled=true;audio._process(0.25)
	assert(audio.music_players[0].playing)
	print("PASS menu return / cinematic pause / music mute and restore")
	audio.shutdown();audio.queue_free()
	# Allow the audio thread to retire stopped decoders before process teardown.
	await create_timer(0.25).timeout
	quit()
