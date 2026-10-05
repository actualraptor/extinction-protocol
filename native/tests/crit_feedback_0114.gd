extends SceneTree
const World=preload("res://scripts/world.gd")
const Readable=preload("res://scripts/readability.gd")
class FeedbackCanvas extends "res://scripts/readability.gd":
	var caption="CRITICAL IMPACT / DAMAGE NUMBERS ONLY"
	func _process(_dt): pass
	func _draw():
		draw_rect(Rect2(0,0,1440,930),Color("132326"))
		draw_string(world.font,Vector2(70,70),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("edd6a3"))
		if not caption.contains("SATURATION"):
			for i in range(8):
				draw_string(world.font,Vector2(65+i*170,330),"TIER %s"%(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("bfcbd0"))
		draw_crit_feedback()
var checks=0
var failures=0
func check(ok,message):
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(1440,930)
	var w=World.new()
	var canvas=FeedbackCanvas.new()
	canvas.world=w
	root.add_child(canvas)
	for tier in range(1,9):
		var p=Vector2(-620+(tier-1)*170,-60)
		w.fx("crit_number_%s"%tier,p,Color.WHITE,12345+tier*2000)
		w.clock+=.05
		w.fx("crit",p+Vector2(0,30),Color.WHITE,tier)
		check(w.numbers[-1].text==str(12345+tier*2000),"Crit includes a tier suffix or non-damage text")
		check(w.crit_bursts[-1].tier==tier,"Crit visual tier lost")
		check(Readable.crit_tint(tier,0)!=Readable.crit_tint(tier+1,0),"Adjacent tiers lack distinct color progression")
	for n in w.numbers:n.life-=.07
	for b in w.crit_bursts:b.life-=.035
	canvas.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/crit-tiers-0114.png")
	w.numbers.clear();w.crit_bursts.clear();w.next_crit_flash=0
	for i in range(600):
		var p=Vector2(-600+(i%12)*100,-240+floori(i/12.0)*52)
		w.clock+=.05
		w.fx("crit_number_%s"%(5+i%8),p,Color.WHITE,20000+i*300)
		w.fx("crit",p,Color.WHITE,5+i%8)
	check(w.numbers.size()==World.MAX_DAMAGE_NUMBERS,"Damage text no longer bounded")
	check(w.crit_bursts.size()==World.MAX_CRIT_BURSTS,"Impact crowns no longer bounded")
	check(w.effects.is_empty() and w.particles.is_empty(),"Crit feedback consumes generic effects or particle budgets")
	var count=w.crit_bursts.size()
	w.fx("crit",Vector2.ZERO,Color.WHITE,100)
	check(w.crit_bursts.size()==count,"Burst event throttle bypassed")
	canvas.caption="CRITICAL SATURATION / 600 HITS / BOUNDED FEEDBACK"
	canvas.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/crit-saturation-0114.png")
	w._process(2)
	check(w.numbers.is_empty() and w.crit_bursts.is_empty(),"Crit feedback leaks after expiration")
	canvas.queue_free();w.free()
	await process_frame
	print("Crit feedback: %s checks / %s failures"%[checks,failures])
	quit(failures)
