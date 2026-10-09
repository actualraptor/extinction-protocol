extends Node
var game
var caption
var id="flametorch"
var immortal=true
func _ready():
	launch(id)
	if "--record-beams" in OS.get_cmdline_user_args():call_deferred("record_preview")
	if "--verify-beam-test" in OS.get_cmdline_user_args():call_deferred("verify")
func launch(weapon):
	id=weapon;game.selected=0;game.chosen_mode="expedition";game.selected_map="cradle";game.start_run()
	var g=game.sim;g.weapons={id:{"level":1,"evolved":false,"timer":0.0,"casts":0}};g.next_boss=300
	g.enemies.clear();g.beams.clear();g.hp=g.max_hp
	g.xp_goal=1000000
	for i in range(24):g.spawn_enemy(false,g.pos+Vector2.from_angle(i*TAU/24)*(140+i%3*65),0,false)
	g.build_grid();game.clear_menu()
	caption=game.label(game.menu_root,"BEAM LAB / %s\nF1 Flame · F2 Conduit · F3 Conduit · F5 rank 5 · F6 rank 10 · F7 reset · F8 extra beams / area\nWASD move · 1 / 2 select path · F9 invulnerability"%g.C.WEAPONS[id].name,17,"e7e0c6")
	caption.position=Vector2(25,185)
func _process(_dt):
	if game.sim!=null and immortal:game.sim.hp=game.sim.max_hp;game.sim.invul=maxf(game.sim.invul,.1)
func _unhandled_input(event):
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_F1:launch("flametorch")
		KEY_F2:launch("plasma_tether")
		KEY_F3:launch("plasma_tether")
		KEY_F5,KEY_F6:
			if game.sim.choosing:return
			game.sim.weapons[id].level=5 if event.keycode==KEY_F5 else 10;game.sim.modifier_cache.clear();game.sim.request_beam_path()
		KEY_F7:launch(id)
		KEY_F8:
			game.sim.passives.area=3;game.sim.passives.count=2;game.sim.modifier_cache.clear()
		KEY_F9:immortal=not immortal
func verify():
	for weapon in ["flametorch","plasma_tether"]:
		launch(weapon)
		await get_tree().create_timer(.65).timeout
		if "--capture-beams" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/beam-review/%s.png"%weapon)
		await get_tree().create_timer(1.35).timeout
		assert(game.sim.damage_by_weapon.get(weapon,0)>0)
		game.sim.weapons[weapon].level=10;game.sim.request_beam_path()
		assert(game.sim.options[0].milestone==5)
		game.finish_upgrade(0)
		assert(game.sim.choosing and game.page=="upgrade" and game.sim.options[0].milestone==10)
		await get_tree().process_frame
		await get_tree().create_timer(.4).timeout
		if "--capture-beams" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/beam-review/%s-cards.png"%weapon)
		game.finish_upgrade(0)
		assert(not game.sim.choosing and game.page=="playing")
	print("PASS: packaged beams deal damage; mandatory cards survive rank skips and UI transitions")
	get_tree().quit()

func record_preview():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/beam-review/video-v21"))
	var frame=0
	for weapon in ["flametorch","plasma_tether","plasma_tether"]:
		launch(weapon);game.paused=true
		if frame>=100:game.sim.passives.count=2;game.sim.modifier_cache.clear()
		for i in range(50):
			game.sim.tick(.025,Vector2(0,sin(i*.08)*.8) if weapon=="flametorch" else Vector2.ZERO)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/beam-review/video-v21/frame%04d.png"%frame)
			frame+=1
	print("CAPTURED shader beam preview / ",frame," frames")
	get_tree().quit()
