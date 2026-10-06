extends SceneTree
# Spoiler-free publicity captures. All setup uses an isolated fixture profile.
func _initialize():call_deferred("run")
func run():
 var game=preload("res://scripts/main.gd").new()
 game.progress_path="res://build/publicity-0130-profile.json"
 root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 root.size=Vector2i(1920,1080)
 game.save_data.unlocks=["mara","vesper"]
 game.save_data.settings.hud_skin=-1
 game.save_data.settings.sound=false
 game.save_data.settings.music=false
 game.apply_settings()
 for hero in [0,1,2]:
  game.selected=hero;game.chosen_mode="expedition";game.start_run();game.paused=true
  var g=game.sim
  # Advance an ordinary early encounter; never enter boss or story content.
  for tick in range(1200):
   if g.choosing:g.choose(0)
   g.tick(1.0/30.0,Vector2(sin(tick*.007),cos(tick*.007)).normalized())
  game.toast_time=0
  for frame in range(12):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/hud-concepts/public-0130-%s.png"%hero)
 game.selected=0;game.chosen_mode="expedition";game.start_run();game.paused=true
 var choices=[]
 for pair in [["weapon","revolver","RARE"],["weapon","lightning","EPIC"],["passive","crit","ARTIFACT"]]:
  choices.append(game.sim.BuffRewards.decorate(game.sim,{"type":pair[0],"id":pair[1]},pair[2]))
 game.sim.options=choices;game.sim.choosing=true
 game.upgrade_menu(choices,false)
 await create_timer(2.0).timeout
 for frame in range(30):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/hud-concepts/public-0130-cards.png")
 game.sim=null
 print("0.13.0 publicity: three early-game characters and upgrade cards; isolated profile")
 quit()
