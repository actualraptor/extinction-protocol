extends SceneTree

var game
var failures = 0

class WalkBoard extends Node2D:
	var animation = preload("res://scripts/survivor_animation.gd").new()
	func _draw():
		draw_rect(Rect2(0,0,1440,900),Color("16232c"))
		var font = ThemeDB.fallback_font
		draw_string(font,Vector2(30,40),"DIRECTIONAL WALK SHEETS / SOUTH, EAST, NORTH, WEST",HORIZONTAL_ALIGNMENT_LEFT,-1,24)
		for hero in range(3):
			for row in range(4):
				animation.direction = [Vector2.DOWN,Vector2.RIGHT,Vector2.UP,Vector2.LEFT][row]
				for frame in range(4):
					animation.phase = float(frame)
					animation.moving = true
					animation.draw(self,{"hero":hero,"time":0.0},Vector2(65+hero*475+frame*108,190+row*215),Color.WHITE)

func check(ok,message):
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures += 1

func _initialize(): call_deferred("run")

func capture(name):
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-031.png")

func run():
	game = preload("res://scenes/main.tscn").instantiate()
	game.progress_path = "res://build/test-visual-progress.json"
	root.add_child(game)
	game.selected = 0
	game.start_run()
	game.paused = true
	game.toast_time = 0
	game.sim.xp = game.sim.xp_goal*0.57
	game.sim.pos = Vector2(700,280)
	for i in range(5):
		var enemy = game.sim.spawn_enemy(false,game.sim.pos+Vector2(-350+i*170,100),i)
		enemy.size = 28
		enemy.mutated = false
		enemy.elite = false
	await capture("upright-mobs-blue-xp")
	var animation = preload("res://scripts/survivor_animation.gd").new()
	animation.update(game.sim)
	for direction in [Vector2.UP,Vector2.LEFT,Vector2.DOWN,Vector2.RIGHT]:
		game.sim.time += 0.1
		game.sim.pos += direction*30
		animation.update(game.sim)
		check(animation.direction.dot(direction)>0.99,"Movement faces "+str(direction))
	var phase = animation.phase
	animation.update(game.sim)
	check(animation.phase==phase,"Pause freezes animation phase")
	game.sim.time += 0.1
	animation.update(game.sim)
	check(not animation.moving and animation.direction==Vector2.RIGHT,"Idle keeps last facing and stops walking")
	for hero in range(3):
		check(animation.regions[hero].size()==12,"Twelve atlas frames for hero "+str(hero))
		for region in animation.regions[hero]:
			check(region.size.x>20 and region.size.y>100,"Nonempty walk frame")
	var bar = game.xp_bar
	bar.set_progress(0,100,2,1.0)
	check(bar.displayed==0,"Level rollover clears old XP fill")
	bar.set_progress(50,100,2,1.0)
	check(absf(bar.displayed-0.5)<0.001,"XP fill converges to correct ratio")
	game.queue_free()
	await process_frame
	var board = WalkBoard.new()
	root.add_child(board)
	await capture("directional-walks")
	board.queue_free()
	await process_frame
	print("VISUAL PATCH RESULT / ",failures," failures")
	quit(failures)
