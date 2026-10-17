extends Control
## A deterministic result from the run RNG, decorated with a separate UI reel.
signal awarded
signal revealed
const C = preload("res://scripts/catalog.gd")
const R = preload("res://scripts/relic_system.gd")
const Icons = preload("res://scripts/atlas_icons.gd")
var reward = ""
var offered_data=[]
var daily_level=false
var reward_data = {}
var odds = []
var reveal_title = "RELIC CACHE"
var ingredients = []
var new_combination = false
var replacement_data = {}
var keep_existing = false
var odds_caption = "THIS CHEST'S ODDS / INCLUDES LUCK, AVAILABLE RELICS & BAD-LUCK PROTECTION"
var audio
var elapsed = 0.0
var duration = 2.6
var strip = []
var reduced_effects=false
var shake_enabled=true
var name_revealed=false
var landed = false
var claimed = false
var card_followup=false
var tick_index = -1
var sheet = preload("res://assets/pickups.png")
var font = preload("res://scripts/ui_art.gd").body_font()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	var ids = C.RELICS.keys()
	if reward_data.is_empty(): reward_data = C.RELICS[reward]
	var decoration_rng = RandomNumberGenerator.new()
	decoration_rng.randomize()
	for i in range(34):
		if not offered_data.is_empty():
			strip.append("offer:"+str(decoration_rng.randi_range(0,offered_data.size()-1)))
			continue
		var candidates = ids
		var rolled_tier="COMMON"
		if odds.size()==6:
			var ticket = decoration_rng.randf()*100
			for tier in range(6):
				ticket -= odds[tier]
				if ticket<=0:
					rolled_tier=R.TIERS[tier]
					break
		strip.append(candidates[decoration_rng.randi_range(0,candidates.size()-1)]+":"+rolled_tier)
	strip[28] = "__reward"

func data_for(id):
	if id=="__reward": return reward_data
	if id.begins_with("offer:"):return offered_data[int(id.split(":")[1])]
	var parts=id.split(":")
	var d = C.RELICS[parts[0]].duplicate()
	d.rarity=parts[1] if parts.size()>1 else d.rarity
	d.art_id = parts[0]
	d.art_type = "relic"
	return d

func reveal_delay():
	if reduced_effects:return .2 if reward_data.rarity=="ARTIFACT" else 0.0
	return .85 if reward_data.rarity=="ARTIFACT" else .3 if reward_data.rarity=="LEGENDARY" else 0.0
func celebration_duration():
	if reduced_effects:return .45
	return 2.7 if reward_data.rarity=="ARTIFACT" else 1.65 if reward_data.rarity=="LEGENDARY" else .65 if reward_data.rarity=="EPIC" else .3
func ready_to_claim():return landed and elapsed>=duration+celebration_duration()
func _process(dt):
	elapsed += dt
	var t = minf(1,elapsed/duration)
	var position_value = 28*(1-pow(1-t,3))
	if int(position_value)!=tick_index and not landed:
		tick_index = int(position_value)
		audio.play("reel_tick",-15,0.85+t*0.25)
	if t>=1 and not landed:
		landed = true
		if R.TIERS.find(reward_data.rarity)>=4:audio.play("reveal_charge",-14)
	if landed and not name_revealed and elapsed>=duration+reveal_delay():
		name_revealed=true
		var cue="reveal_artifact" if reward_data.rarity=="ARTIFACT" else "reveal_legendary" if reward_data.rarity=="LEGENDARY" else "rarity_"+str(R.TIERS.find(reward_data.rarity))
		audio.play(cue,-9)
	if card_followup and ready_to_claim() and not claimed:
		claimed=true;set_process(false);revealed.emit()
	queue_redraw()

func _unhandled_key_input(event):
	# A held movement key must not skip the reveal. Require a new press.
	if card_followup or claimed or not ready_to_claim(): return
	if event.pressed and not event.echo and event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_LEFT,KEY_DOWN,KEY_RIGHT,KEY_SPACE,KEY_ENTER,KEY_E]:
		keep_existing = not replacement_data.is_empty() and event.keycode!=KEY_E
		claimed = true
		get_viewport().set_input_as_handled()
		set_process(false)
		awarded.emit()

func text_center(text,y,size_value,color):
	var width = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x
	draw_string_outline(font,Vector2((size.x-width)/2,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,5,Color(0.015,0.025,0.035,0.8))
	draw_string(font,Vector2((size.x-width)/2,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func text_block(value,y):
	var lines=[];var line=""
	for paragraph in value.split("\n"):
		for word in paragraph.split(" "):
			var next=(line+" "+word).strip_edges()
			if font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x>1180 and line!="":lines.append(line);line=word
			else:line=next
		if line!="":lines.append(line);line=""
	for i in range(mini(4,lines.size())):text_center(lines[i],y+i*20,16,Color("dfedf1"))

func _draw():
	draw_rect(Rect2(-global_position,get_viewport_rect().size),Color(0.015,0.025,0.04,0.72))
	var data = reward_data
	var color = Color(R.tier_color(data.rarity))
	var rank = R.TIERS.find(data.rarity)
	if landed:draw_celebration(rank,color)
	text_center("NEW COMBINATION DISCOVERED" if name_revealed and new_combination else "MERGING" if not ingredients.is_empty() else "THE RIFT REMEMBERS",105 if not ingredients.is_empty() else 210,28,Color("f4e4c8"))
	text_center(reveal_title,243,14,Color("9ebbc5"))
	if ingredients.size()==2:
		for i in range(2):
			var x = size.x/2-170+i*340
			draw_texture_rect(Icons.get_icon(ingredients[i]),Rect2(x-31,130,62,62),false)
			draw_string(font,Vector2(x-110,210),C.WEAPONS[ingredients[i]].name,HORIZONTAL_ALIGNMENT_CENTER,220,15,Color("bfdeed"))
		text_center("+",178,32,Color("ffda8c"))
	var t = minf(1,elapsed/duration)
	var at = 28*(1-pow(1-t,3))
	for offset in range(-2,3):
		var index = int(at)+offset
		if index<0 or index>=strip.size(): continue
		var d = data_for(strip[index])
		var x = size.x/2+(index-at)*190
		if landed and not reduced_effects and rank>=4:
			var age=maxf(0,elapsed-duration-reveal_delay())
			var kick=exp(-age*7) if name_revealed else 0.0
			var center=Vector2(size.x/2,379)
			var jitter=Vector2(sin(age*77),cos(age*61))*kick*(5 if rank==5 else 3) if shake_enabled else Vector2.ZERO
			draw_set_transform_matrix(Transform2D(0,Vector2.ONE*(1+kick*.16),0,center*(-kick*.16)+jitter))
		var fade = clampf(1-absf(x-size.x/2)/650,0,1)
		if landed and index!=28: fade *= 0.25
		if index==28 and landed:
			for ring in range(10,0,-1):
				draw_circle(Vector2(x,379),44+ring*8,Color(color,0.012+rank*0.003))
			draw_line(Vector2(x-35,449),Vector2(x+35,449),Color(color,0.85),2,true)
		draw_texture_rect(Icons.get_icon(d.get("art_id",reward),d.get("art_type","relic")),Rect2(x-58,321,116,116),false,Color(1,1,1,fade))
		draw_string(font,Vector2(x-72,465),d.rarity,HORIZONTAL_ALIGNMENT_CENTER,144,14,Color(Color(R.tier_color(d.rarity)),fade))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([Vector2(size.x/2-12,274),Vector2(size.x/2+12,274),Vector2(size.x/2,293)]),Color("ffe2a5"))
	if name_revealed:
		text_center(data.rarity+" / "+data.name,550,26,color)
		text_block(data.desc,584)
		if not ingredients.is_empty(): text_center("ONE BACKPACK SLOT FREED / RECIPE RECORDED IN THE ARCHIVE",651,16,Color("ffd795"))
		if not replacement_data.is_empty():
			text_center("CURRENT: "+replacement_data.name+" / "+replacement_data.desc,650,14,Color("b6c4c9"))
		if ready_to_claim():text_center("E: REPLACE CURRENT RELIC   /   SPACE OR MOVEMENT: KEEP IT & SALVAGE FOR 25 AMBER" if not replacement_data.is_empty() else "WASD / ARROWS / SPACE TO CONTINUE",689,15,Color("b6c4c9"))
	elif landed:text_center("THE RIFT HOLDS ITS BREATH",580,20,Color("f6d879"))
	else: text_center("Uncovering what survived...",580,20,Color("b6c4c9"))
	if odds.size()==6:
		text_center(odds_caption,755,14,Color("a6b8c5"))
		for tier in range(6):
			var x = 155+tier*190
			draw_string(font,Vector2(x,790),R.TIERS[tier],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(R.COLORS[tier]))
			draw_string(font,Vector2(x,819),"%.2f%%"%odds[tier],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
	elif daily_level: text_center("FATE CHOOSES / NORMAL UPGRADE POOL / NO REROLLS",790,16,Color("ffd795"))
	else: text_center("GUARANTEED TRANSFORMATION / REQUIREMENTS MET",790,16,Color("ffd795"))

func draw_celebration(rank:int,color:Color):
	if rank<3:return
	var age=maxf(0,elapsed-duration);var center=Vector2(size.x/2,379)
	if reduced_effects:
		draw_arc(center,143,0,TAU,96,Color(color,.32),2,true)
		return
	var burst_age=age-reveal_delay()
	if burst_age<0:
		var charge=age/maxf(.01,reveal_delay())
		for ring in 6:draw_arc(center,180-charge*45+ring*7,-PI*.5,TAU-PI*.5,96,Color(color,.025+charge*.02),2,true)
		return
	var fade=clampf(1-burst_age/celebration_duration(),0,1)
	var flash=exp(-burst_age*9)*(.14 if rank==5 else .10 if rank==4 else .055)
	draw_rect(Rect2(-global_position,get_viewport_rect().size),Color(color,flash))
	for ring in 10:draw_circle(center,95+ring*18+burst_age*40,Color(color,fade*.012))
	draw_arc(center,125+burst_age*(150 if rank>=4 else 95),0,TAU,128,Color(color,fade*.6),2.5,true)
	if rank<4:return
	var count=56 if rank==5 else 32
	for i in count:
		var angle=i*TAU/count+sin(i*7.31)*.12
		var direction=Vector2.from_angle(angle)
		var distance=140+burst_age*(85+fposmod(i*71,190))
		var p=center+direction*distance+Vector2(0,burst_age*burst_age*45)
		if p.y>500:continue
		var half=2+fposmod(i*3.7,4)
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-half*2),p+Vector2(half,0),p+Vector2(0,half*2),p-Vector2(half,0)]),Color(color,fade*.85))
		if i%3==0:draw_line(center+direction*(125+burst_age*80),p,Color(color,fade*.1),1,true)
	text_center("ARTIFACT UNEARTHED" if rank==5 else "LEGENDARY DISCOVERY",170,34,Color(color,fade))
