extends RefCounted
# Fixed consoles connected by flexible rails. Widgets never stretch on ultrawide.
static func arrange(size,configuration={}):
 var unit=size.y/210.0
 var map_width=150*unit
 var center_start=float(configuration.get("left_console_width",570))*unit
 var right_start=size.x-float(configuration.get("right_console_width",570))*unit
 var center_width=right_start-center_start
 var inventory_width=232*unit
 # Reserve space for the right shell's crescent/bone/crest ornament. The item
 # grid stops before this decoration rather than sliding underneath it.
 var weapon_width=minf(680*unit,2*minf(size.x/2-center_start-12*unit,right_start-size.x/2-12*unit))
 var edge_padding=float(configuration.get("edge_padding",70))*unit
 var utility_start=size.x-edge_padding-186*unit
 var weapon_region=Rect2(size.x/2-weapon_width/2,90*unit,weapon_width,108*unit)
 var xp_width=minf(760*unit,weapon_region.size.x*.96)
 return {
  "left_zone":Rect2(12*unit,30*unit,center_start-12*unit,168*unit),
  "right_zone":Rect2(right_start,30*unit,size.x-right_start-12*unit,180*unit),
  "map":Rect2(20*unit,46*unit,map_width-28*unit,152*unit),
  "portrait":Rect2(map_width+6*unit,46*unit,132*unit,152*unit),
  "level":Rect2(map_width+146*unit,127*unit,52*unit,52*unit),
  "name":Rect2(map_width+145*unit,43*unit,270*unit,68*unit),
  "health":Rect2(map_width+194*unit,115*unit,226*unit,78*unit),
  "center":Rect2(center_start,30*unit,center_width,180*unit),
  "weapons":weapon_region,
  "inventory":Rect2(right_start+12*unit,60*unit,inventory_width,126*unit),
  "inventory_pages":Rect2(right_start+12*unit,190*unit,inventory_width,18*unit),
  "summary":Rect2(weapon_region.position.x,75*unit,weapon_width,14*unit),
  "xp":Rect2(weapon_region.get_center().x-xp_width/2,30*unit,xp_width,43*unit),
  "currency":Rect2(utility_start,42*unit,186*unit,35*unit),
  "backpack":Rect2(utility_start,82*unit,186*unit,35*unit),
  "relics":Rect2(utility_start,122*unit,186*unit,35*unit),
  "reroll":Rect2(utility_start,162*unit,186*unit,35*unit)}
