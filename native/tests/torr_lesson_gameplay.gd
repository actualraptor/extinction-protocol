extends SceneTree
var game
var capture_dir="res://build"
var checks=0
var failures=0
func check(ok,why):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",why)
func _initialize():call_deferred("run")
func capture(name):
 await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(capture_dir.path_join("torr-lesson-"+name+".png"))==OK,"Captured "+name)
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--torr-capture-dir="):capture_dir=arg.trim_prefix("--torr-capture-dir=")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
 create_timer(45).timeout.connect(func():printerr("FAIL / lesson UI timeout");quit(1))
 game=preload("res://scenes/main.tscn").instantiate();game.progress_path=capture_dir.path_join("torr-lesson-ui-profile.json");root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()!=null and child.get_script().resource_path=="res://scripts/opening_story.gd":child.queue_free()
 game.save_data.settings.sound=false;game.save_data.settings.music=false;game.save_data.settings.torr_mortal_seen=false
 if "torr" not in game.save_data.unlocks:game.save_data.unlocks.append("torr")
 game.selected=preload("res://scripts/god_content.gd").install(game.C);game.chosen_mode="expedition";game.start_run();game.paused=true
 var g=game.sim
 g.weapons.mjolnir.level=4;g.request_beam_path();g.choosing=false
 g.open_choices(false)
 await create_timer(.4).timeout
 await capture("offer")
 var index=-1
 for i in g.options.size():
  if g.options[i].get("torr_lesson",false):index=i
 check(index>=0,"Real level-up offers the first mortal lesson")
 if index<0:quit(1);return
 game.finish_upgrade(index)
 await process_frame
 check(game.page=="torr-story" and game.paused and g.god_state.lesson_pending,"Real reward button opens story and freezes the run")
 var story
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/torr_story_player.gd"):story=child
 check(story!=null,"Existing illustrated story player is used")
 story.external_clock=true;story.clock=13.2;story.update_frame()
 await capture("break")
 story.finish();story.finish()
 await process_frame
 check(g.weapons.mjolnir.level==5 and not g.weapons.has("club"),"Finish/skip grants one divine rank and never equips the club")
 check(g.choosing and g.options[0].type=="beam_path" and game.page=="upgrade","Rank-5 branch remains available after the story")
 var loaded=preload("res://scripts/profile_store.gd").load_profile(game.progress_path)
 check(not loaded.blocked and loaded.data.settings.torr_mortal_seen,"Actual story completion persists to disk")
 await create_timer(.4).timeout
 await capture("branch")
 g.choose(0)
 game.release_run();game.replay_cinematic("torr_mortal")
 await process_frame
 check(game.page=="cinematic-gallery","Settings gallery opens Torr's completed story")
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/torr_story_player.gd"):child.finish()
 await process_frame
 check(game.sim==null and g.weapons.mjolnir.level==5,"Replay cannot grant another reward")
 game.audio.shutdown();game.survivor_voice.stop();game.queue_free();game=null
 await create_timer(.2).timeout
 print("TORR LESSON RENDERED / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
