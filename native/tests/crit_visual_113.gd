extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/crit113-profile.json";root.add_child(game);await create_timer(.3).timeout
 game.chosen_mode="safari";game.start_run();game.paused=true;root.size=Vector2i(1280,800)
 for tier in range(1,7):
  game.world.fx("crit_number_%s"%tier,game.sim.pos+Vector2((tier-3.5)*145,-80),game.sim.crit_color(tier),12345*tier)
  game.world.numbers[-1].life=2.0
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/crit-tiers113.png")
 game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free();await create_timer(.3).timeout;await process_frame;quit()
