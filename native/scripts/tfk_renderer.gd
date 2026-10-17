extends Node2D
## Temporary code-drawn cues expose each prototype's timing and identity.
var world
const CAMEOS=preload("res://assets/tfk-cameos-v1.png")
var cameo_regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/tfk-cameo-regions.json"))
func _process(_dt):queue_redraw()
func _draw():
	var g=world.sim
	if g==null:return
	var font=preload("res://scripts/ui_art.gd").body_font()
	if g.tfk_state.has("portal"):
		var at=world.screen(g.tfk_state.portal)
		draw_arc(at,42+sin(g.time*3)*3,0,TAU,48,Color("c9a3ff"),5,true)
		draw_arc(at,32,0,TAU,48,Color("83ddff"),2,true)
		draw_string(font,at+Vector2(-60,65),"E / STUDION",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
	if not preload("res://scripts/tfk_content.gd").active(g):return
	preload("res://scripts/tfk_weapon_animation.gd").draw(self,world,g)
	var subtitle=g.tfk_state.get("subtitle",{})
	if not subtitle.is_empty() and g.time<subtitle.until:
		var speech=preload("res://scripts/tfk_speech.gd")
		var utterances=speech.utterances(subtitle)
		for i in range(utterances.size()):
			var utterance=utterances[i]
			if utterances.size()>1 and ((subtitle.until-g.time>2.0)!=(i==0)):continue
			var head=world.screen(g.pos)+Vector2(0,-62)
			match utterance.speaker:
				"Mathie","Johan":
					var host=0 if utterance.speaker=="Mathie" else 1
					for layer in world.get_children():
						if layer.get_script()==preload("res://scripts/readability.gd"):
							head+=layer.survivor.tfk_offset(g,host)
				"Jimmy","Johannes":
					if g.tfk_state.get("cameo_until",0)<=g.time:continue
					var expected="Johannes Lindh" if utterance.speaker=="Johannes" else "Jimmy Woolke"
					if g.tfk_state.get("cameo","")!=expected:continue
					head=world.screen(g.pos)+Vector2(65,-50)
			speech.draw(self,font,utterance.text,head)
	for missile in g.tfk_state.get("missiles",[]):
		var at=world.screen(missile.p)
		if missile.get("id","")=="tfk_meltdown":
			draw_set_transform(at,sin(g.time*8+missile.effect)*.3)
			draw_rect(Rect2(-9,-12,18,24),Color("e8ded0"))
			draw_rect(Rect2(-9,-12,18,24),Color("c9a3ff"),false,2)
			for y in [-6,0,6]:draw_line(Vector2(-5,y),Vector2(5,y),Color("796885"),1)
			draw_set_transform(Vector2.ZERO)
		else:
			var color=Color("a0e8da")
			for i in range(3):
				var orbit=Vector2.from_angle(g.time*8+i*TAU/3)*11
				draw_circle(at+orbit,2,Color(color,.6))
			draw_set_transform(at,sin(g.time*9)*.2)
			draw_string_outline(font,Vector2(-8,8),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,26,3,Color("15101d"))
			draw_string(font,Vector2(-8,8),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,26,color)
			draw_set_transform(Vector2.ZERO)
	var list_shown=false
	var broadcast=g.tfk_state.get("broadcast_visual",{})
	if not broadcast.is_empty() and g.time-broadcast.at<broadcast.duration:
		var age=g.time-broadcast.at
		var at=world.screen(broadcast.p)+Vector2(-75,-12)
		var alpha=clampf((broadcast.duration-age)*3,0,1)
		draw_texture_rect(preload("res://scripts/atlas_icons.gd").get_icon("tfk_disaster"),Rect2(at-Vector2(36,60),Vector2(72,72)),false,Color(1,1,1,alpha))
		for i in range(3):
			var ray=Vector2.from_angle(age*4+i*TAU/3)
			draw_polyline(PackedVector2Array([at+ray*24,at+ray*34+ray.orthogonal()*7,at+ray*47]),Color(.7,.85,1,alpha),2,true)
	var eyes=g.tfk_state.get("eyes_visual",{})
	if not eyes.is_empty() and g.time-eyes.at<eyes.duration:
		var at=world.screen(eyes.p)+Vector2(0,-42)
		var fade=1-(g.time-eyes.at)/eyes.duration
		for side in [-1,1]:
			var center=at+Vector2(side*32,0)
			draw_colored_polygon(PackedVector2Array([center+Vector2(-26,0),center+Vector2(0,-13),center+Vector2(26,0),center+Vector2(0,13)]),Color(.55,.9,1,.5*fade))
			draw_line(center+Vector2(0,-10),center+Vector2(0,10),Color(.02,.08,.12,fade),6,true)
	var mac=g.tfk_state.get("mac_visual",{})
	if not mac.is_empty() and g.time-mac.at<mac.duration:
		var at=world.screen(mac.p)+Vector2(0,-55)
		draw_texture_rect(preload("res://scripts/atlas_icons.gd").get_icon("tfk_mac"),Rect2(at-Vector2(22,22),Vector2(44,44)),false,Color(1,1,1,1-(g.time-mac.at)/mac.duration))
	var finale=g.tfk_state.get("list_impact",{})
	if not finale.is_empty() and g.time-finale.at<.7:
		var age=(g.time-finale.at)/.7;var at=world.screen(finale.p)
		var color=Color(1,.84,.42,1-age)
		draw_string(font,at+Vector2(-26,-30-age*45),"1",HORIZONTAL_ALIGNMENT_LEFT,-1,100,color)
		draw_arc(at,finale.radius*clampf(age,.05,1),0,TAU,64,color,4,true)
		for i in range(8):
			var ray=Vector2.from_angle(i*TAU/8)
			draw_polyline(PackedVector2Array([at+ray*25,at+ray*70+ray.orthogonal()*12,at+ray*110]),color,2,true)
	for visual in g.tfk_state.get("scenario_visuals",[]):
		if visual.age<0:continue
		var progress=clampf((visual.age-.15)/1.0,0,1)
		var at=world.screen(visual.p+Vector2(-240+450*progress,0))
		var frame=1+int(visual.age*10)%2
		var source=Rect2(frame*512,768,512,384)
		var fade=minf(1,visual.age*8)*clampf((visual.duration-visual.age)*6,0,1)
		draw_texture_rect_region(preload("res://scripts/dinosaur_boss_art.gd").SHEET,Rect2(at+Vector2(-100,-140),Vector2(200,150)),source,Color(.55,.9,1,.65*fade))
	for event in g.tfk_state.get("events",[]):
		if event.id=="tfk_list":
			if list_shown:continue
			list_shown=true
		var at=world.screen(event.p)
		var color=Color(g.C.WEAPONS[event.id].color)
		if event.get("label","")=="MIKROFON":
			draw_microphone(at+Vector2(0,-minf(220,event.wait*275)),color)
		if event.get("visual","")=="coin":
			if event.wait<=.6:draw_coin(at+Vector2(0,-event.wait*260),g.time)
		if event.get("visual","")=="trex":continue
		draw_arc(at,event.get("radius",80.0),0,TAU,36,Color(color,.3),2,true)
		var label=str(event.number) if event.has("number") else "%.1f"%event.wait if event.get("label","")=="5 SEKUNDER" else event.get("label","")
		if not label.is_empty():draw_string(font,at+Vector2(-14,10),label,HORIZONTAL_ALIGNMENT_LEFT,-1,32,color)
	var impact=g.tfk_state.get("microphone_impact",{})
	if not impact.is_empty() and g.time-impact.at<.65:
		var age=g.time-impact.at
		var at=world.screen(impact.p)
		draw_microphone(at,Color("ffd76c"))
		draw_arc(at,impact.radius*clampf(age/.65,.05,1),0,TAU,64,Color(1,.84,.42,1-age/.65),5,true)
	if g.tfk_state.get("cameo_until",0)>g.time:
		var at=world.screen(g.pos)+Vector2(65,-8)
		if g.tfk_state.get("empowered",0.0)>0:at.y-=sin(g.time*10)*2
		var host=1 if g.tfk_state.get("cameo","")=="Johannes Lindh" else 0
		var b=cameo_regions[host];var region=Rect2(b[0],b[1],b[2],b[3])
		var dimensions=region.size*(42.0/region.size.y)
		var alpha=clampf((g.tfk_state.cameo_until-g.time)*3,0,1)
		draw_texture_rect_region(CAMEOS,Rect2(at-Vector2(dimensions.x*.5,dimensions.y),dimensions),region,Color(1,1,1,alpha))
		if host==1 and g.tfk_state.get("editing_until",0)>g.time:
			draw_editing_desk(at,alpha)
	var p=world.screen(g.pos)+Vector2(-40,30)
	draw_rect(Rect2(p,Vector2(80,5)),Color(.08,.04,.1,.85))
	var empowered=g.tfk_state.get("empowered",0.0)
	var fraction=empowered/8.0 if empowered>0 else g.tfk_state.get("charge",0.0)/100.0
	draw_rect(Rect2(p,Vector2(80*clampf(fraction,0,1),5)),Color("ffd76c") if empowered>0 else Color("c9a3ff"))

func draw_microphone(at,color):
	draw_line(at+Vector2(0,-48),at+Vector2(0,6),Color("332719"),24,true)
	draw_line(at+Vector2(0,-48),at+Vector2(0,6),color,16,true)
	draw_circle(at+Vector2(0,-65),25,Color("332719"))
	draw_circle(at+Vector2(0,-65),21,color)
	for y in [-76,-68,-60]:draw_line(at+Vector2(-14,y),at+Vector2(14,y),Color("6d512c"),3,true)

func draw_coin(at,clock):
	var width=4+8*absf(cos(clock*9))
	draw_set_transform(at,0,Vector2(width/12,1))
	draw_circle(Vector2.ZERO,14,Color("654416"))
	draw_circle(Vector2.ZERO,12,Color("ffcf56"))
	draw_arc(Vector2.ZERO,9,0,TAU,20,Color("fff0a3"),2,true)
	draw_line(Vector2(0,-6),Vector2(0,6),Color("99601e"),3,true)
	draw_set_transform(Vector2.ZERO)

func draw_editing_desk(at,alpha):
	draw_rect(Rect2(at+Vector2(-27,-19),Vector2(54,15)),Color(.15,.12,.10,alpha))
	draw_line(at+Vector2(-24,-4),at+Vector2(-24,10),Color(.35,.25,.17,alpha),4)
	draw_line(at+Vector2(24,-4),at+Vector2(24,10),Color(.35,.25,.17,alpha),4)
	for i in range(5):
		var p=at+Vector2(-18+i*9,-16)
		draw_line(p,p+Vector2(0,9),Color(.65,.58,.48,alpha),1)
		draw_circle(p+Vector2(0,3+i%3),2,Color(.7,.9,1,alpha))
