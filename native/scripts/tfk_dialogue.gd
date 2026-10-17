extends RefCounted
## Original homage lines from the brief, never presented as podcast quotations.
## Optional audio paths are reserved for supplied recordings; no voice synthesis.
const LINES={
	"selected":["Johan","Jaha, då kör vi väl.",60,10.0],
	"run_start":["Mathie","Välkomna till ännu ett avsnitt!",60,60.0],
	"large_wave":["Mathie","Men vad i helvete är det där?!",40,45.0],
	"boss_appears":["Johan","Det där ser ju inte helt optimalt ut.",70,30.0],
	"ring_en_framling":["Mathie","Hallå? Vem är det jag pratar med?",20,20.0],
	"johans_topplista":["Johan","På plats nummer ETT!",20,20.0],
	"mathies_fakta":["Mathie","Visste ni förresten att...",20,20.0],
	"dagens_scenario":["Jimmy","Okej, tänk dig följande scenario...",30,25.0],
	"klipp_bort":["Johannes","Det där klipper vi bort.",65,20.0],
	"meter_full":["Mathie & Johan","Nu spårar det ur!",75,8.0],
	"heavy_damage":["Johan","AJ! Men för helvete!",40,12.0],
	"level_up":["Mathie","Det går ju faktiskt ganska bra det här.",25,20.0],
	"low_health":["Johan","Jag tror fan vi dör snart.",85,30.0],
	"victory":["Mathie & Johan","Tack för kaffet!",100,60.0],
	"defeat":["Mathie","Ja, det där gick ju åt helvete.",100,60.0],
	"reunion":["Jimmy / Johan","Jimmy: Okej, tänk dig följande scenario...\nJohan: Jaha, då kör vi väl.",80,30.0]}
static func record(event):
	var row=LINES[event]
	return {"event_id":event,"speaker":row[0],"text":row[1],"priority":row[2],"cooldown":row[3],"variation_weight":1.0,"audio_path":"","original_homage":true}
static func speak(g,event):
	if not preload("res://scripts/tfk_content.gd").active(g) or not LINES.has(event):return false
	var line=record(event)
	var deadlines=g.tfk_state.get("dialogue_deadlines",{})
	if g.time<deadlines.get(event,-1):return false
	var current=g.tfk_state.get("subtitle",{})
	if not current.is_empty() and g.time<current.until and line.priority<=current.priority:return false
	line.until=g.time+4.0
	g.tfk_state.subtitle=line
	deadlines[event]=g.time+line.cooldown;g.tfk_state.dialogue_deadlines=deadlines
	return true
