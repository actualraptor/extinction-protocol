extends Control
var game
var border = frame()
func _ready():
	size = Vector2(56,12)
	mouse_filter = Control.MOUSE_FILTER_PASS
func _process(_dt):
	visible = game.sim!=null and game.sim.active
	if not visible: return
	position = game.world.position+game.world.screen(game.sim.pos)+Vector2(-28,31)
	tooltip_text = "%s / %s health"%[ceili(maxf(0,game.sim.hp)),int(game.sim.max_hp)]
	queue_redraw()
func _draw():
	if game.sim==null: return
	var ratio = clampf(game.sim.hp/game.sim.max_hp,0,1)
	draw_style_box(border,Rect2(0,0,56,8))
	var color = Color("ed7168") if ratio<0.35 else Color("86dbac")
	draw_rect(Rect2(2,2,52*ratio,4),color)
	if game.sim.shield>0:
		draw_rect(Rect2(2,10,52,2),Color("98dfff"))
func frame():
	var style = StyleBoxFlat.new()
	style.bg_color = Color("141d24")
	style.border_color = Color("c1d2bf")
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style
