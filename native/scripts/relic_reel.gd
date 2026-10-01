extends Control
## A deterministic result from the run RNG, decorated with a separate UI reel.
signal awarded
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
var landed = false
var claimed = false
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
		if odds.size()==6:
			var ticket = decoration_rng.randf()*100
			for tier in range(6):
				ticket -= odds[tier]
				if ticket<=0:
					candidates = ids.filter(func(id):return C.RELICS[id].rarity==R.TIERS[tier])
					break
		strip.append(candidates[decoration_rng.randi_range(0,candidates.size()-1)])
	strip[28] = "__reward"

func data_for(id):
	if id=="__reward": return reward_data
	if id.begins_with("offer:"):return offered_data[int(id.split(":")[1])]
	var d = C.RELICS[id].duplicate()
	d.art_id = id
	d.art_type = "relic"
	return d

func _process(dt):
	elapsed += dt
	var t = minf(1,elapsed/duration)
	var position_value = 28*(1-pow(1-t,3))
	if int(position_value)!=tick_index and not landed:
		tick_index = int(position_value)
		audio.play("reel_tick",-15,0.85+t*0.25)
	if t>=1 and not landed:
		landed = true
		audio.play("rarity_"+str(R.TIERS.find(reward_data.rarity)),-7)
	queue_redraw()

func _unhandled_key_input(event):
	# A held movement key must not skip the reveal. Require a new press.
	if claimed or not landed or elapsed<duration+0.3: return
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

func _draw():
	draw_rect(Rect2(-global_position,get_viewport_rect().size),Color(0.015,0.025,0.04,0.38))
	var data = reward_data
	var color = Color(R.tier_color(data.rarity))
	var rank = R.TIERS.find(data.rarity)
	text_center("NEW COMBINATION DISCOVERED" if landed and new_combination else "MERGING" if not ingredients.is_empty() else "THE RIFT REMEMBERS",105 if not ingredients.is_empty() else 210,28,Color("f4e4c8"))
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
		var fade = clampf(1-absf(x-size.x/2)/650,0,1)
		if landed and index!=28: fade *= 0.25
		if index==28 and landed:
			for ring in range(10,0,-1):
				draw_circle(Vector2(x,379),44+ring*8,Color(color,0.012+rank*0.003))
			draw_line(Vector2(x-35,449),Vector2(x+35,449),Color(color,0.85),2,true)
		draw_texture_rect(Icons.get_icon(d.get("art_id",reward),d.get("art_type","relic")),Rect2(x-58,321,116,116),false,Color(1,1,1,fade))
		draw_string(font,Vector2(x-72,465),d.rarity,HORIZONTAL_ALIGNMENT_CENTER,144,14,Color(Color(R.tier_color(d.rarity)),fade))
	draw_colored_polygon(PackedVector2Array([Vector2(size.x/2-12,274),Vector2(size.x/2+12,274),Vector2(size.x/2,293)]),Color("ffe2a5"))
	if landed:
		var reveal = minf(1,(elapsed-duration)*4)
		for i in range(12+rank*8):
			var a = i*TAU/(12+rank*8)+elapsed*0.16
			var origin = Vector2(size.x/2,390)
			draw_line(origin+Vector2.from_angle(a)*(105+reveal*20),origin+Vector2.from_angle(a)*(145+rank*7+reveal*10),Color(color,0.25*(1-reveal*0.4)),1+rank*0.25,true)
		text_center(data.rarity+" / "+data.name,550,26,color)
		var desc_size = mini(18,int(1250/maxf(1,font.get_string_size(data.desc,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x)*18))
		text_center(data.desc,593,maxi(12,desc_size),Color("dfedf1"))
		if not ingredients.is_empty(): text_center("ONE BACKPACK SLOT FREED / RECIPE RECORDED IN THE ARCHIVE",651,16,Color("ffd795"))
		if not replacement_data.is_empty():
			text_center("CURRENT: "+replacement_data.name+" / "+replacement_data.desc,650,14,Color("b6c4c9"))
		text_center("E: REPLACE CURRENT RELIC   /   SPACE OR MOVEMENT: KEEP IT & SALVAGE FOR 25 AMBER" if not replacement_data.is_empty() else "WASD / ARROWS / SPACE TO CONTINUE",689,15,Color("b6c4c9"))
	else: text_center("Uncovering what survived...",580,20,Color("b6c4c9"))
	if odds.size()==6:
		text_center(odds_caption,755,14,Color("a6b8c5"))
		for tier in range(6):
			var x = 155+tier*190
			draw_string(font,Vector2(x,790),R.TIERS[tier],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(R.COLORS[tier]))
			draw_string(font,Vector2(x,819),"%.2f%%"%odds[tier],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
	elif daily_level: text_center("FATE CHOOSES / NORMAL UPGRADE POOL / NO REROLLS",790,16,Color("ffd795"))
	else: text_center("GUARANTEED TRANSFORMATION / REQUIREMENTS MET",790,16,Color("ffd795"))
