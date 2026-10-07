extends RefCounted
## Shared, deterministic blood treatment for world and cinematic corpses.
static func pools(canvas,rect,opacity=1.0):
 for i in range(12):
  var centre=rect.position+rect.size*Vector2(.27+.055*i,.77+.07*sin(i*2.399))
  var points=PackedVector2Array()
  for j in range(14):
   var angle=TAU*j/14
   var radius=.75+.2*sin(j*2.31+i*1.7)
   points.append(centre+Vector2(cos(angle)*rect.size.x*.052,sin(angle)*rect.size.y*.09)*radius)
  canvas.draw_colored_polygon(points,Color(.24+.025*(i%3),.025,.02,.65*opacity))
 for i in range(20):
  var at=rect.position+rect.size*Vector2(.22+.032*i,.85+.1*sin(i*2.399))
  canvas.draw_circle(at,maxf(1,rect.size.x*(.0015+.001*(i%3))),Color(.36,.035,.022,.7*opacity))
