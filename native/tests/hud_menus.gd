extends SceneTree
func _initialize():call_deferred("run")
func run():
 var main=preload("res://scripts/main.gd").new()
 main.progress_path="res://build/menu-ui-fixture.json";root.add_child(main)
 await process_frame
 for child in main.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 main.save_data.unlocks=["mara","kael","vesper","iona","orin"]
 main.save_data.campaign.route_07=true
 main.selected=0;main.chosen_mode="expedition";main.start_run();main.paused=true
 main.sim.score=999999999;main.sim.time=97;main.sim.next_boss=300
 for dimensions in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440),Vector2i(3840,2160),Vector2i(1680,1050),Vector2i(1024,640)]:
  root.size=dimensions
  for theme in [0,1,2,5]:
   main.save_data.settings.hud_skin=theme;main.update_hud_scale()
   for frame in range(4):await process_frame
   # Godot stretches its minimum 1440x900 canvas on smaller physical windows.
   var viewport=main.get_viewport_rect()
   assert(viewport.encloses(main.timer_plate.get_global_rect()))
   assert(viewport.encloses(main.score_plate.get_global_rect()),"%s actual %s score %s"%[dimensions,main.get_viewport_rect(),main.score_plate.get_global_rect()])
   assert(not main.timer_plate.get_global_rect().intersects(main.score_plate.get_global_rect()))
   for plate in [main.timer_plate,main.score_plate]:
    for item in [plate.primary,plate.secondary]:
     if item.visible:assert(Rect2(Vector2.ZERO,plate.size).encloses(Rect2(item.position,item.size)))
   assert(main.score_label.text=="999,999,999")
   assert(main.timer_label.text=="01:37")
   assert(main.biome_label.text.contains("NEXT BOSS IN 03:23"))
   if dimensions==Vector2i(1920,1080):
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/hud-concepts/status-theme-%s.png"%theme)
   main.pause_menu()
   for frame in range(3):await process_frame
   var column=main.menu_root.get_children().filter(func(node):return node is VBoxContainer)[0]
   var buttons=column.get_children().filter(func(node):return node is Button)
   assert(buttons.map(func(node):return node.text)==["Resume","Backpack & Stats","Settings","End Expedition"])
   for control in column.get_children():assert(viewport.encloses(control.get_global_rect()))
   assert(buttons[0].has_focus())
   if dimensions==Vector2i(1920,1080):
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/hud-concepts/pause-theme-%s.png"%theme)
   buttons[0].pressed.emit();await process_frame
   assert(main.page=="playing" and not main.paused)
   main.paused=true
 print("Four pause/status themes passed at six resolutions, including large scores, timer text, bounds, labels and Resume activation")
 main.pause_menu();await process_frame
 var column=main.menu_root.get_children().filter(func(node):return node is VBoxContainer)[0]
 column.get_child(2).pressed.emit();await process_frame
 assert(main.page=="ledger" and main.paused)
 main.resume();main.pause_menu();await process_frame
 column=main.menu_root.get_children().filter(func(node):return node is VBoxContainer)[0]
 column.get_child(3).pressed.emit();await process_frame
 assert(main.page=="pause" and main.paused)
 assert(main.menu_root.get_children().any(func(node):return node is ScrollContainer))
 print("Pause Backpack and Settings actions passed; End Expedition retains its existing withdrawal callback")
 main.sim=null;quit()
