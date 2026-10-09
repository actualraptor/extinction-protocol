extends RefCounted
## Identical 128px terrain sampling with local cell reuse and packed pixels.
static func render(g,origin:Vector2,world_size:Vector2)->Image:
 var terrain=g.terrain
 var explored:Dictionary=g.explored[g.depth]
 var shades:PackedColorArray=PackedColorArray([Color("40534b"),Color("838078"),Color("2e6775"),Color("a85c37")])
 # Use Image's own float-to-byte conversion to preserve existing colours.
 var palette:=Image.create(8,1,false,Image.FORMAT_RGBA8)
 for index in range(4):
  palette.set_pixel(index,0,shades[index]);palette.set_pixel(index+4,0,shades[index].darkened(.68))
 var colors:PackedByteArray=palette.get_data()
 var terrain_x:PackedInt32Array=PackedInt32Array()
 var known_x:PackedInt32Array=PackedInt32Array()
 for x in range(128):
  var px:float=origin.x+((x+.5)/128.0-.5)*world_size.x
  terrain_x.append(floori(px/terrain.CELL));known_x.append(floori(px/160))
 var pixels:PackedByteArray=PackedByteArray();pixels.resize(128*128*4)
 var kinds:Dictionary={}
 for y in range(128):
  var py:float=origin.y+((y+.5)/128.0-.5)*world_size.y
  var cy:int=floori(py/terrain.CELL)
  var ey:int=floori(py/160)
  for x in range(128):
   var cell:=Vector2i(terrain_x[x],cy)
   if not kinds.has(cell):kinds[cell]=clampi(terrain.kind(cell),0,3)
   var color:int=(int(kinds[cell])+(0 if explored.has(Vector2i(known_x[x],ey)) else 4))*4
   var offset:int=(y*128+x)*4
   pixels[offset]=colors[color];pixels[offset+1]=colors[color+1]
   pixels[offset+2]=colors[color+2];pixels[offset+3]=colors[color+3]
 return Image.create_from_data(128,128,false,Image.FORMAT_RGBA8,pixels)
