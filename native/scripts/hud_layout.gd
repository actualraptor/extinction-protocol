extends RefCounted
# All skins share these sections. Extra width belongs to the loadout, not margins.
static func arrange(size):
 var unit=size.y/210.0
 var map_width=150*unit
 var character_width=420*unit
 var utility_width=190*unit
 var center_start=map_width+character_width
 var center_width=size.x-center_start-utility_width
 var inventory_width=clampf(center_width*.30,160*unit,310*unit)
 var weapon_width=center_width-inventory_width
 var utility_start=size.x-utility_width
 return {
  "map":Rect2(0,30*unit,map_width,180*unit),
  "portrait":Rect2(map_width,34*unit,140*unit,168*unit),
  "level":Rect2(map_width+146*unit,127*unit,52*unit,52*unit),
  "name":Rect2(map_width+145*unit,43*unit,270*unit,68*unit),
  "health":Rect2(map_width+194*unit,115*unit,226*unit,78*unit),
  "center":Rect2(center_start,30*unit,center_width,180*unit),
  "weapons":Rect2(center_start+8*unit,54*unit,weapon_width-16*unit,140*unit),
  "inventory":Rect2(center_start+weapon_width,60*unit,inventory_width,132*unit),
  "summary":Rect2(center_start+8*unit,33*unit,weapon_width-16*unit,20*unit),
  "xp":Rect2(center_start,0,center_width,36*unit),
  "currency":Rect2(utility_start,33*unit,utility_width,55*unit),
  "backpack":Rect2(utility_start,91*unit,utility_width,55*unit),
  "reroll":Rect2(utility_start,149*unit,utility_width,55*unit)}
