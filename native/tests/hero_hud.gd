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
 for dimensions in [Vector2i(1024,640),Vector2i(1920,1080),Vector2i(3440,1392),Vector2i(3840,2160)]:
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
   assert(is_equal_approx(areas.xp.get_center().x,areas.weapons.get_center().x))
   assert(areas.center.encloses(areas.xp))
   assert(not main.buffs_hud.visible)
   assert(areas.inventory.end.x<=areas.currency.position.x-40)
   for slot in main.hero_dock.slots:
    assert((areas.weapons if slot.rect.position.x<areas.inventory.position.x else areas.inventory).encloses(slot.rect))
   assert(not areas.level.intersects(areas.portrait))
   assert(areas.level.size.x>=52)
   assert(areas.map.end.y<=main.hero_dock.size.y-12)
   for region in [areas.map,areas.portrait,areas.currency,areas.backpack,areas.reroll]:
    assert(Rect2(12,30,main.hero_dock.size.x-24,168).encloses(region))
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
 for factor in [.65,1.0,1.35]:
  main.save_data.settings.hud_scale=factor
  main.update_hud_scale()
  for frame in range(4):await process_frame
  var areas=main.hero_dock.regions
  assert(is_equal_approx(areas.xp.get_center().x,areas.weapons.get_center().x))
  for slot in main.hero_dock.slots:
   assert((areas.weapons if slot.rect.position.x<areas.inventory.position.x else areas.inventory).encloses(slot.rect))
 main.save_data.settings.hud_scale=1.0
 print("HUD unlock guards, 16 resolution/hero renders, XP integration and inventory scale checks passed")
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
 # Cross-theme names/portraits, fixed numeric apertures, and real zone bounds.
 var Skin=preload("res://scripts/hud_skin.gd")
 main.save_data.unlocks=["mara","kael","vesper","iona","orin"]
 main.save_data.campaign.route_07=true
 main.sim.companions=null
 main.world.hide() # HUD permutations do not mutate the live survivor animation rig.
 main.toast_time=0
 for dimensions in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440),Vector2i(3840,2160),Vector2i(1680,1050),Vector2i(1024,768)]:
  root.size=dimensions;main.update_hud_scale()
  for theme in [1,0,2,5]:
   main.save_data.settings.hud_skin=theme
   for hero in range(6):
    main.sim.hero=hero;main.sim.amber=99999;main.sim.rerolls=99
    for frame in range(3):await process_frame
    var dock=main.hero_dock;var areas=dock.regions
    assert(is_equal_approx(areas.xp.get_center().x,dock.size.x/2))
    assert(is_equal_approx(areas.weapons.get_center().x,dock.size.x/2))
    for key in ["map","portrait","name","level","health"]:assert(areas.left_zone.encloses(areas[key]))
    for key in ["inventory","inventory_pages","currency","backpack","relics","reroll"]:assert(areas.right_zone.encloses(areas[key]))
    assert(areas.currency.end.x<=dock.size.x-60)
    assert(dock.portrait_node.texture==Skin.portrait(hero))
    assert(dock.plates.name.artwork.texture==Skin.nameplate(Skin.THEMES[theme],hero))
    assert(dock.plates.name.mouse_filter==Control.MOUSE_FILTER_IGNORE)
    for key in ["currency","reroll"]:
     var plate=dock.plates[key];var num=plate.number
     assert(Rect2(Vector2.ZERO,plate.size).encloses(Rect2(num.position,num.size)))
     var fs=num.get_theme_font_size("font_size")
     assert(num.get_theme_font("font").get_string_size(num.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x<=num.size.x-3)
    if dimensions==Vector2i(1920,1080):
     await RenderingServer.frame_post_draw
     root.get_texture().get_image().save_png("res://build/hud-concepts/matrix-%s-%s.png"%[theme,hero])
 print("All 24 hero/theme combinations passed at six resolutions; 99,999 Amber and 99 rerolls remain inside their plates")
 for theme in [1,0,2,5]:
  main.save_data.settings.hud_skin=theme
  for amount in [0,1,9,25,120,999,1000,5250,9999,10000,25000,99999,9999999]:
   main.sim.amber=amount
   await process_frame
   assert(main.hero_dock.plates.currency.number.text==Skin.format_amount(amount))
  for count in [0,1,3,9,10,25,99]:
   main.sim.rerolls=count;await process_frame
   assert(main.hero_dock.plates.reroll.number.text==str(count))
 main.sim.hero=2
 var plate_click=InputEventMouseButton.new();plate_click.pressed=true;plate_click.button_index=MOUSE_BUTTON_LEFT
 main.hero_dock.plates.relics._gui_input(plate_click)
 await process_frame
 assert(main.page=="ledger" and main.paused)
 assert(main.menu_root.get_children().any(func(node):return node.get_script()==preload("res://scripts/backpack_panel.gd") and node.focus_relics))
 root.get_texture().get_image().save_png("res://build/hud-concepts/relics-panel.png")
 main.resume()
 main.hero_dock.plates.backpack._gui_input(plate_click)
 await process_frame
 assert(main.page=="ledger" and main.paused)
 assert(main.menu_root.get_children().any(func(node):return node.get_script()==preload("res://scripts/backpack_panel.gd") and not node.focus_relics))
 main.resume()
 var previous_count=main.sim.rerolls
 main.hero_dock.plates.reroll._gui_input(plate_click)
 assert(main.sim.rerolls==previous_count and main.toast_time>0)
 print("All numeric cases and Backpack/Relics/Reroll interactions passed")
 main.sim=null
 quit()
