extends Control
var flame=false
var branch="reach"
func _draw():
	var c=Color("ffac48") if flame else Color("75eedc")
	var center=size*.5
	var r=minf(size.x,size.y)*.35
	draw_circle(center,r,Color(.05,.06,.08))
	for i in range(2 if branch=="split" else 1):
		var y=center.y+(i-.5)*r*.6 if branch=="split" else center.y
		draw_line(Vector2(center.x-r,y),Vector2(center.x+r,y),c,5)
		draw_circle(Vector2(center.x+r,y),r*.25,c)
	if branch=="sustain":draw_arc(center,r,0,TAU,24,c,3)
	if branch=="power":draw_circle(center,r*.48,Color("fff1b6"))
	if branch=="reach":draw_line(center+Vector2(r,0),center+Vector2(r*.5,-r*.45),c,3)
