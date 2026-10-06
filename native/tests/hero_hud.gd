extends SceneTree
func _initialize():call_deferred("run")
func run():
 var H=preload("res://scripts/hero_hud.gd")
 assert(3 not in H.available({"unlocks":["iona","orin"],"settings":{}}))
 assert(4 not in H.available({"unlocks":["iona","orin"],"settings":{}}))
 assert(5 not in H.available({"unlocks":[],"settings":{}}))
 assert(H.selected({"unlocks":[],"settings":{"hud_skin":5}},1)==1)
 assert(5 in H.available({"campaign":{"route_07":true},"unlocks":[],"settings":{}}))
 var main=preload("res://scripts/main.gd").new()
 main.progress_path="res://build/hero-hud-fixture.json"
 root.add_child(main)
 await process_frame
 for child in main.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 main.chosen_mode="safari";main.selected=1;main.start_run();main.paused=true;main.world.hide()
 main.sim.relic_chests.append(main.sim.pos+Vector2(100,0))
 main.sim.pickups.append({"id":"magnet","p":main.sim.pos+Vector2(0,100),"life":65.0,"magnet":false})
 var markers=preload("res://scripts/map_markers.gd").collect(main.sim)
 assert(markers.any(func(item):return item.name=="RELIC CHEST"))
 assert(markers.any(func(item):return item.name=="GRAVITY WELL"))
 for dimensions in [Vector2i(1024,640),Vector2i(1920,1080),Vector2i(3440,1440)]:
  root.size=dimensions
  for hero in [1,0,2,5]:
   main.sim.hero=hero
   main.save_data.settings.hud_skin=-1
   main.update_hud_scale()
   for frame in range(6):await process_frame
   await RenderingServer.frame_post_draw
   for slot in main.hero_dock.slots:
    assert(slot.rect.position.x>=0 and slot.rect.end.x<=main.hero_dock.size.x)
    assert(slot.rect.position.y>=0 and slot.rect.end.y<=main.hero_dock.size.y)
   assert(abs(main.hero_dock.position.x)<.1)
   assert(main.hero_dock.item_pages>=1)
   var areas=main.hero_dock.regions
   assert(not areas.level.intersects(areas.portrait))
   assert(areas.level.size.x>=52)
   assert(areas.map.end.y==main.hero_dock.size.y)
   for slot in main.hero_dock.slots:assert(not slot.rect.intersects(areas.xp))
   var bottom=main.hero_dock.get_global_transform()*Vector2(0,main.hero_dock.size.y)
   assert(abs(bottom.y-root.get_visible_rect().end.y)<1.0)
   assert(abs(main.hero_dock.size.x*main.hero_dock.scale.x-main.get_viewport_rect().size.x)<1)
   root.get_texture().get_image().save_png("res://build/hud-concepts/hud-%s-%s.png"%[hero,dimensions.x])
 assert(main.hero_dock.item_pages>1)
 var click=InputEventMouseButton.new();click.pressed=true;click.button_index=MOUSE_BUTTON_LEFT
 click.position=Vector2(main.hero_dock.regions.inventory.get_center().x+12,199)
 main.hero_dock._gui_input(click)
 assert(main.hero_dock.item_page==1)
 for frame in range(2):await process_frame
 assert(main.hero_dock.slots.size()>5)
 print("HUD unlock guards and 12 resolution/hero renders passed")
 main.save_data.campaign.route_07=true
 main.selected=5;main.chosen_mode="expedition";main.start_run();main.world.show();main.paused=true
 root.size=Vector2i(3440,1392)
 for frame in range(8):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/hud-concepts/hud-live-ultrawide.png")
 main.save_data.unlocks.append("mara")
 main.selected=0;main.chosen_mode="expedition";main.start_run();main.paused=true;main.world.show()
 root.size=Vector2i(1920,1080)
 main.show_toast("RELIC ACQUIRED","A new power joins your expedition.")
 main.sim.xp=4
 for frame in range(12):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/hud-concepts/mara-master-live.png")
 main.toast_time=0
 main.sim.max_hp=100;main.sim.xp_goal=1000
 for fraction in [0.0,0.25,0.5,1.0]:
  main.sim.hp=100*fraction;main.sim.xp=int(1000*fraction)
  main.hero_dock.xp_display=fraction
  for frame in range(4):await process_frame
  await RenderingServer.frame_post_draw
  assert(is_equal_approx(main.hero_dock.health_node.fraction,fraction))
  assert(is_equal_approx(main.hero_dock.xp_node.material_fill.get_shader_parameter("fraction"),fraction))
  root.get_texture().get_image().save_png("res://build/hud-concepts/bars-%s.png"%int(fraction*100))
 print("HP and XP empty/quarter/half/full rendered and ratios verified")
 main.sim.options=[{"type":"weapon","id":"u00","rarity":"COMMON","rank_gain":1},{"type":"weapon","id":"u01","rarity":"RARE","rank_gain":1},{"type":"weapon","id":"u02","rarity":"EPIC","rank_gain":1}]
 main.sim.choosing=true
 main.upgrade_menu(main.sim.options,false)
 for frame in range(20):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/hud-concepts/reroll-review.png")
 main.save_data.unlocks.append("vesper")
 main.save_data.settings.hud_skin=-1
 root.size=Vector2i(1920,1080)
 for hero in [1,0,2,5]:
  main.selected=hero;main.chosen_mode="expedition";main.start_run();main.paused=true;main.world.show()
  main.show_toast("RELIC ACQUIRED","A new power joins your expedition.")
  for frame in range(12):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/hud-concepts/ship-live-%s.png"%hero)
  assert(main.hero_dock.health_node.active_skin==main.hero_dock.active_theme)
 print("Four scoped live character skins and event banners verified")
 main.sim=null
 quit()
