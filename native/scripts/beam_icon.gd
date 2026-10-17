extends Control
## Branch art for beam path cards: painted icon when assets/clean-icons/beam-<weapon>-<branch>.png exists, otherwise
## the simple vector mark. The painted file is cropped to its own alpha box so the card's medallion centres it.
var flame=false
var branch="reach"
var painted=null
func _ready():
	var path="res://assets/clean-icons/beam-%s-%s.png"%["flame" if flame else "conduit",branch]
	if ResourceLoader.exists(path):painted=load(path)
func _draw():
	if painted!=null:
		var side=minf(size.x,size.y)
		draw_texture_rect(painted,Rect2((size-Vector2.ONE*side)*.5,Vector2.ONE*side),false)
		return
	var c=Color("ffac48") if flame else Color("75eedc")
	var center=size*.5
	var r=minf(size.x,size.y)*.35
	draw_circle(center,r,Color(.05,.06,.08))
	var count=(2 if flame else 3) if branch=="split" else 1
	for i in range(count):
		var y=center.y+(i-(count-1)*.5)*r*.6 if branch=="split" else center.y
		draw_line(Vector2(center.x-r,y),Vector2(center.x+r,y),c,5)
		draw_circle(Vector2(center.x+r,y),r*.25,c)
	if branch=="sustain":draw_arc(center,r,0,TAU,24,c,3)
	if branch=="power":draw_circle(center,r*.48,Color("fff1b6"))
	if branch=="reach":draw_line(center+Vector2(r,0),center+Vector2(r*.5,-r*.45),c,3)
