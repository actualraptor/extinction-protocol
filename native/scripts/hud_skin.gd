extends RefCounted
const ROOT="res://assets/hud-modular/"
const THEMES={1:"kael",0:"voss",2:"vesper",3:"kael",4:"voss",5:"covenant"}
const PARTS=["map","portrait","name","health","weapon","relic","currency","backpack","panel"]
static var images={}
static var regions={}
static var styles={}
static var configurations={}
const HERO_KEYS=["mara-voss","kael","vesper","iona","orin","nagash"]
static func configuration(theme):
 if not configurations.has(theme):configurations[theme]=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"plates/"+theme+"/theme.json"))
 return configurations[theme]
static func asset(path):
 if not images.has(path):images[path]=load(ROOT+path)
 return images[path]
static func nameplate(theme,hero):return asset(configuration(theme).nameplates[HERO_KEYS[hero]])
static func plate_texture(theme,part):return asset(configuration(theme).plates[part].texture)
static func plate_spec(theme,part):return configuration(theme).plates[part]
static func portrait(hero):return asset(configuration(THEMES[hero]).portraits[HERO_KEYS[hero]])
static func format_amount(value):
 var digits=str(maxi(0,int(value)))
 var result=""
 for i in range(digits.length()):
  if i>0 and (digits.length()-i)%3==0:result+=","
  result+=digits[i]
 return result
static func xp_frame(theme):
 var key=theme+"xp"
 if not styles.has(key):
  var style=StyleBoxTexture.new();style.texture=texture(theme,"xp")
  var dimensions=style.texture.get_size()
  for side in [SIDE_LEFT,SIDE_RIGHT]:style.set_texture_margin(side,dimensions.x*.08)
  for side in [SIDE_TOP,SIDE_BOTTOM]:style.set_texture_margin(side,dimensions.y*.25)
  styles[key]=style
 return styles[key]
static func texture(theme,part):
 var key=theme+"-"+part
 if not images.has(key):images[key]=load(ROOT+key+".png")
 return images[key]
static func region(theme,part,rect):
 if not regions.has(theme):regions[theme]=JSON.parse_string(FileAccess.get_file_as_string(ROOT+theme+"-content.json"))
 var r=regions[theme][part]
 return Rect2(rect.position+Vector2(r[0],r[1])*rect.size,Vector2(r[2],r[3])*rect.size)
static func panel(theme,rail=false):
 var key=theme+str(rail)
 if not styles.has(key):
  var style=StyleBoxTexture.new();style.texture=texture(theme,"health" if rail else "panel")
  var dimensions=style.texture.get_size()
  for side in [SIDE_LEFT,SIDE_RIGHT]:style.set_texture_margin(side,dimensions.x*.22)
  for side in [SIDE_TOP,SIDE_BOTTOM]:style.set_texture_margin(side,dimensions.y*.36)
  style.axis_stretch_horizontal=StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
  styles[key]=style
 return styles[key]
