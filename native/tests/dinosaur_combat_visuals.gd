extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=preload("res://scripts/main.gd").new();game.progress_path="res://build/dinosaur-combat-profile.json";root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 root.size=Vector2i(1920,1080);game.save_data.settings.sound=false;game.save_data.settings.music=false;game.apply_settings()
 game.selected=0;game.chosen_mode="expedition";game.start_run();game.paused=true
 var g=game.sim;g.weapons.clear();g.enemies.clear();g.landmarks.clear();g.invul=100
 g.spawn_boss(2);var b=g.boss
 for step in range(420):
  g.time+=1.0/60;g.update_boss(1.0/60);g.update_enemies(1.0/60);g.update_hazards(1.0/60)
  if step%60==0:
   await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://build/dinosaur-trex-action-%03d.png"%step)
 g.boss_time=5;g.kill(b);g.choosing=false;game.clear_menu()
 for frame in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/dinosaur-trex-death.png")
 # Every regular enemy supports the same lightweight death reaction.
 for kind in range(g.Bestiary.DATA.size()):
  var e=g.spawn_enemy(false,g.pos+Vector2((kind%6-3)*90,(kind/6)*50),kind);g.kill(e)
 for frame in range(4):await process_frame
 await RenderingServer.frame_post_draw
 print("T-rex intro/windup/charge/recovery and dinosaur deaths rendered")
 game.sim=null;quit()
