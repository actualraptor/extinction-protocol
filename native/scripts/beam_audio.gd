extends Node
const IDS=["flametorch","plasma_tether"]
var sound
var players={}
func shutdown():
	set_process(false)
	for player in players.values():
		player.stop()
		player.stream=null
func _exit_tree():
	shutdown()
func _ready():
	for id in IDS:
		var player=AudioStreamPlayer.new();player.bus="SFX";player.volume_db=-80
		var stream=load("res://assets/audio/beams/%s.wav"%("flame_pressure" if id=="flametorch" else "plasma_current")).duplicate()
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=roundi(stream.get_length()*stream.mix_rate)
		player.stream=stream;player.pitch_scale=.92 if id=="plasma_tether" else 1.0
		add_child(player);players[id]=player
func _process(dt):
	var game=sound.get_parent()
	update_audio(game.sim,game.paused or not sound.enabled or game.page!="playing",dt)
func update_audio(g,muted,dt):
	var active={}
	if g!=null and g.active and not g.choosing and not muted:
		for beam in g.beams:
			var envelope=minf(1,beam.age/.08)*minf(1,(beam.life-beam.age)/.13)
			active[beam.id]=maxf(active.get(beam.id,0),envelope)
	for id in IDS:
		var player=players[id];var intensity=active.get(id,0.0)
		var target=(-15.5 if id=="flametorch" else -20.0)+linear_to_db(maxf(.001,intensity)) if intensity>.001 else -80.0
		if intensity>.001 and not player.playing:player.play()
		player.volume_db=lerpf(player.volume_db,target,1-exp(-dt*28))
		if intensity<=.001 and player.volume_db<-65:player.stop()
