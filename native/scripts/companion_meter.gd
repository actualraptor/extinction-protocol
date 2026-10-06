extends Control
var game
var last_threshold=-1
var pulse=0.0
var font=preload("res://scripts/ui_art.gd").body_font()
const X=preload("res://scripts/content_extension.gd")
const REWARDS=["EXTRA WARRIOR","HEAL THE ARMY","EMPOWER THE ARMY","BONE COLOSSUS"]
const ROLES=["warrior","guard","archer","wraith","colossus","boss"]
const IDS=["u00","u01","u02","u03","u09","u10"]
static func census(units,at):
	var counts={"total":0,"warrior":0,"guard":0,"archer":0,"wraith":0,"colossus":0,"boss":0}
	for unit in units:
		if unit.hp<=0 or (unit.get("temporary",0)>0 and unit.get("expires",0)<=at):continue
		counts.total+=1
		if counts.has(unit.role):counts[unit.role]+=1
	return counts
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(dt):
	visible=game!=null and game.sim!=null and game.sim.companions!=null and (game.get("hero_dock")==null or not game.hero_dock.visible)
	if not visible:return
	var index=game.sim.companions.threshold_index
	if last_threshold>=0 and index>last_threshold:pulse=.8
	last_threshold=index
	pulse=maxf(0,pulse-dt)
	queue_redraw()
func _draw():
	if not visible or game==null or game.sim==null or game.sim.companions==null:return
	var army=game.sim.companions
	var counts=census(army.units,game.sim.time)
	var index=army.threshold_index
	var lower=float(int(index/4)*250+[0,25,50,100][index%4])
	var progress=clampf((army.souls-lower)/(army.next_threshold-lower),0,1)
	var restoring=not army.fallen_remnant.is_empty()
	if restoring:progress=clampf(army.remnant_souls/army.REMNANT_SOUL_COST,0,1)
	var accent=Color("88cbb4").lerp(Color("e0fff0"),pulse)
	draw_style_box(panel(),Rect2(Vector2.ZERO,size))
	draw_string(font,Vector2(14,25),"SOULS  %s"%int(army.souls),HORIZONTAL_ALIGNMENT_LEFT,-1,19,accent)
	draw_string(font,Vector2(190,25),"%s MINIONS"%counts.total,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("b0b9b3"))
	var icon=X.milestone_icon(index%4)
	if icon!=null:draw_texture_rect(icon,Rect2(14,36,34,34),false)
	draw_string(font,Vector2(57,49),"RESTORE FALLEN BOSS" if restoring else REWARDS[index%4],HORIZONTAL_ALIGNMENT_LEFT,-1,13,accent)
	draw_string(font,Vector2(57,68),"SOUL COST: 2000" if restoring else "NEXT MILESTONE: %s"%int(army.next_threshold),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c7c8b5"))
	draw_rect(Rect2(14,82,size.x-28,7),Color("23312d"))
	draw_rect(Rect2(14,82,(size.x-28)*progress,7),accent)
	draw_string(font,Vector2(14,106),"%s / 2000 toward restoration"%int(army.remnant_souls) if restoring else "%s / %s toward next reward"%[int(army.souls-lower),int(army.next_threshold-lower)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("afbeb6"))
	draw_line(Vector2(14,115),Vector2(size.x-14,115),Color("324b40"))
	for i in range(ROLES.size()):
		var x=12+i*46
		var count=counts[ROLES[i]]
		var tone=Color("c4e5d5") if count>0 else Color("67766f")
		var unit_icon=X.icon(IDS[i])
		if unit_icon!=null:draw_texture_rect(unit_icon,Rect2(x,121,20,20),false,tone)
		draw_string(font,Vector2(x+22,140),str(count),HORIZONTAL_ALIGNMENT_LEFT,-1,14,tone)
func panel():
	var style=StyleBoxFlat.new()
	style.bg_color=Color(.025,.045,.04,.9)
	style.border_color=Color("4d7565")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style
