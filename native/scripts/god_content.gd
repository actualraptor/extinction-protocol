extends RefCounted
## GOD is a shared equipment family, independent of character names or indices.
const WEAPONS = {
 "mjolnir":{"name":"Mjölnir","desc":"A heavy hammer strikes outward and returns. Choose ricochet or a permanent orbit at rank 5.","color":"a9dfff","damage":43.0,"cooldown":1.35,"radius":100.0,"range":260.0,"count":1,"velocity":480.0,"lifetime":4.0,"tags":["GOD","WEAPON","PROJECTILE","PHYSICAL","LIGHTNING","RETURNING","AREA","CRITICAL"],"delivery":"god","god_kind":"hammer","evolution":"THE WORLDCOIL","requires":"count"},
 "gungnir":{"name":"Gungnir","desc":"Oath-piercing spears pursue a chosen enemy or pin a damaging spear line into the ground.","color":"ead28b","damage":36.0,"cooldown":1.55,"radius":90.0,"range":330.0,"count":1,"velocity":760.0,"lifetime":1.1,"base_pierce":4,"tags":["GOD","WEAPON","PROJECTILE","PHYSICAL","CRITICAL"],"delivery":"god","god_kind":"spear","evolution":"OATHPIERCER","requires":"pierce"},
 "cloudbreaker":{"name":"Cloudbreaker","desc":"Iron gauntlets drive a thunder front away from Torr. A full Stormload reserve can empower the blow.","color":"b7eaff","damage":85.0,"cooldown":2.8,"radius":165.0,"range":220.0,"tags":["GOD","WEAPON","MELEE","LIGHTNING","KNOCKBACK","AREA","CRITICAL"],"delivery":"god","god_kind":"gauntlet","evolution":"JÁRNGREIPR","requires":"area"},
 "ninefold":{"name":"Ninefold Rebuke","desc":"Record enemy positions, then punish those exact places with staggered thunder after a short warning.","color":"d1dfff","damage":49.0,"cooldown":3.8,"radius":65.0,"range":420.0,"count":3,"tags":["GOD","SPELL","OFFENSIVE","LIGHTNING","GROUND_EFFECT","AREA","CRITICAL"],"delivery":"god","god_kind":"rebuke","evolution":"NINE WORLDS ANSWER","requires":"haste"},
 "summer_edge":{"name":"Summer’s Edge","desc":"Freyr’s living sword sweeps independently through a selected group. It never becomes another orbit ring.","color":"ffe6a2","damage":64.0,"cooldown":2.35,"radius":95.0,"range":320.0,"tags":["GOD","WEAPON","MELEE","FIRE","AREA","CRITICAL"],"delivery":"god","god_kind":"sword","evolution":"FREYR’S PROCESSION","requires":"damage"},
 "winter_claim":{"name":"Winter’s Claim","desc":"Skaði marks a quarry and sends a pursuing volley of frost arrows after it.","color":"b4f1ff","damage":24.0,"cooldown":1.75,"radius":65.0,"range":430.0,"count":2,"velocity":680.0,"lifetime":1.5,"base_pierce":1,"projectile_homing":5.0,"tags":["GOD","WEAPON","PROJECTILE","ICE","FREEZE","CRITICAL"],"delivery":"god","god_kind":"bow","evolution":"SKAÐI’S VERDICT","requires":"count"},
 "worldwake":{"name":"Worldwake","desc":"Heimdall’s expanding horn wave marks enemies. One divine projectile consumes each mark for a single payoff.","color":"e7d7ab","damage":28.0,"cooldown":4.3,"radius":230.0,"range":320.0,"tags":["GOD","SPELL","OFFENSIVE","AREA","KNOCKBACK","CRITICAL"],"delivery":"god","god_kind":"horn","evolution":"GJALLARHORN","requires":"area"},
 "oathsplitter":{"name":"Oathsplitter","desc":"Týr cuts a sworn line, then crosses it. The intersection receives one concentrated finishing hit.","color":"e4cbb8","damage":78.0,"cooldown":2.9,"radius":125.0,"range":290.0,"tags":["GOD","WEAPON","MELEE","PHYSICAL","AREA","CRITICAL"],"delivery":"god","god_kind":"cross","evolution":"TÝR’S LAST OATH","requires":"damage"}
}
const UNIONS = {
 "storm_pact":{"parts":["mjolnir","gungnir"],"name":"STORM PACT","desc":"Mjölnir keeps its chosen route; every third hammer contact launches an oath-piercing spear.","base":"mjolnir","damage":56.0,"god_combo":"spear"},
 "sky_sentence":{"parts":["cloudbreaker","ninefold"],"name":"SKY SENTENCE","desc":"The gauntlet front records its victims for a delayed thunder verdict.","base":"cloudbreaker","damage":125.0,"god_combo":"rebuke"},
 "winter_sun":{"parts":["summer_edge","winter_claim"],"name":"WINTER SUN","desc":"Freyr’s sweeping sword releases Skaði’s pursuing frost arrows from its destination.","base":"summer_edge","damage":96.0,"god_combo":"frost","tags":["GOD","WEAPON","MELEE","PROJECTILE","FIRE","ICE","FREEZE","AREA","CRITICAL"]},
 "last_oath":{"parts":["worldwake","oathsplitter"],"name":"THE LAST OATH","desc":"Gjallarhorn’s wave calls crossing oath cuts around three marked enemies.","base":"worldwake","damage":62.0,"god_combo":"cross"}
}
const PATHS = {
 "mjolnir":{"5":[{"id":"bounce","name":"Stone to Stone","desc":"The hammer ricochets between enemies before returning. More bounces arrive as it ranks up.","stats":{}},{"id":"orbit","name":"The Hammer Ring","desc":"Permanent hammers gain 65% damage and follow you. Throw only at setup or added projectile capacity.","stats":{"power":.65}}]},
 "gungnir":{"5":[{"id":"hunt","name":"The Oath Finds You","desc":"Spears pursue their chosen target and pierce three more enemies.","stats":{"homing":4.0,"pierce":3}},{"id":"anchor","name":"The Spear Line","desc":"Spears remain as short-lived lines, striking each crossing enemy once.","stats":{}}],"10":[{"id":"fan","name":"Three Sworn Paths","desc":"Throw two more spears in each cast.","stats":{"count":2}},{"id":"recall","name":"No Oath Unanswered","desc":"The spear line strikes a second, narrower returning pass.","stats":{}}]},
 "cloudbreaker":{"5":[{"id":"wide","name":"Open the Sky","desc":"The thunder front spreads over a wider cone.","stats":{"radius":.35}},{"id":"double","name":"Both Gauntlets","desc":"A second narrower front follows the first.","stats":{}}],"10":[{"id":"reserve","name":"Storm in the Fist","desc":"Full Stormload empowers the front without consuming the reserve.","stats":{}},{"id":"aftershock","name":"The Earth Answers","desc":"A delayed thunder strike follows at the end of the front.","stats":{}}]},
 "ninefold":{"5":[{"id":"count","name":"More Witnesses","desc":"Record three additional impact positions.","stats":{"count":3}},{"id":"fast","name":"Sentence Served","desc":"The first thunder verdict arrives much sooner.","stats":{}}],"10":[{"id":"echo","name":"Nine Worlds Answer","desc":"Recorded positions receive a second, weaker thunder verdict.","stats":{}},{"id":"converge","name":"One Final Word","desc":"The last recorded position receives a larger finishing strike.","stats":{}}]},
 "summer_edge":{"5":[{"id":"long","name":"Summer’s Procession","desc":"The living sword sweeps a longer path through the selected group.","stats":{"radius":.4}},{"id":"twin","name":"Two Days of Summer","desc":"A second sword crosses the group from the other side.","stats":{}}],"10":[{"id":"return","name":"The Long Summer","desc":"The sword makes a second return sweep.","stats":{}},{"id":"sun","name":"Daybreak at the Edge","desc":"The sweep ends in one concentrated solar strike.","stats":{}}]},
 "winter_claim":{"5":[{"id":"quarry","name":"One Chosen Quarry","desc":"The selected quarry takes an additional focused frost hit.","stats":{}},{"id":"volley","name":"The Hunt Widens","desc":"Two extra arrows seek nearby prey.","stats":{"count":2}}],"10":[{"id":"freeze","name":"Winter Has Your Name","desc":"Marked quarry freezes more quickly; bosses keep their resistance.","stats":{"status":2.0}},{"id":"shatter","name":"The Last Arrow","desc":"The volley ends with a localized ice burst at the quarry’s recorded position.","stats":{}}]},
 "worldwake":{"5":[{"id":"long","name":"Across the Nine Worlds","desc":"The horn wave reaches 40% farther.","stats":{"radius":.4}},{"id":"echo","name":"A Second Warning","desc":"A second wave follows the first.","stats":{}}],"10":[{"id":"call","name":"Answer the Horn","desc":"Consumed horn marks deal more damage.","stats":{}},{"id":"grip","name":"Stand and Listen","desc":"The wave slows ordinary enemies; bosses retain resistance.","stats":{}}]},
 "oathsplitter":{"5":[{"id":"wide","name":"The Broad Oath","desc":"Both sworn cuts cover a wider area.","stats":{"radius":.35}},{"id":"swift","name":"A Promise Kept","desc":"The crossing cut follows sooner.","stats":{}}],"10":[{"id":"cross","name":"Witness the Crossing","desc":"The intersection receives an extra finishing strike.","stats":{}},{"id":"three","name":"Threefold Oath","desc":"A third diagonal cut crosses the first two.","stats":{}}]}
}
static func with_unions(recipes):
 recipes.merge(UNIONS,true)
 return recipes
static func base_id(id): return UNIONS.get(id,{}).get("base",id)
static func owns(id): return WEAPONS.has(base_id(id))
static func god_hero(data): return data.get("weapon_set","")=="god"
static func allowed(hero,definition): return god_hero(hero)==("GOD" in definition.get("tags",[]))
static func supports_augment(g,weapon,key):
 if owns(weapon) and key=="linger":return false
 return not (g.C.WEAPONS[weapon].get("god_kind","")=="hammer" and g.weapons.get(weapon,{}).get("branches",{}).get("5","")=="orbit" and key in ["homing","pierce","bounce"])
static func eligible_augment(g,key):
 var filter=g.C.AUGMENTS[key].filter
 if filter.is_empty():return true
 for weapon in g.weapons:
  if g.Rules.matches(g.C.WEAPONS[weapon].tags,filter) and supports_augment(g,weapon,key):return true
 return false
static func install(catalog):
 for i in catalog.HEROES.size():
  if catalog.HEROES[i].get("voice_key","")=="torr":return i
 catalog.HEROES.append({"name":"TORR STORMBUK","title":"THE STORMFORGED · [God]","voice_key":"torr","weapon_set":"god","unlock_id":"torr","weapon":"mjolnir","hp":200.0,"speed":215.0,"armor":5.0,"crit":.08,"color":"b5dcf2","desc":"Too strong for mortal weapons. [God] arsenal only.\nStormload: catches and completed hammer revolutions build 8 charges, then release one thunder discharge."})
 return catalog.HEROES.size()-1
static func choices(id,milestone,weapon={}):
 id=base_id(id)
 if id=="mjolnir" and milestone==10:
  if weapon.get("branches",{}).get("5","")=="orbit":
   return [{"id":"oath","name":"Worldcoil","desc":"The permanent hammer ring breathes outward and inward, preserving every hammer.","stats":{}},{"id":"thunder","name":"Hammerfall","desc":"One bounded thunder strike falls after each completed revolution.","stats":{}}]
  return [{"id":"oath","name":"Unbroken Oath","desc":"With no other enemy nearby, spend remaining bounces to strike that target again, up to half the original bounce budget.","stats":{}},{"id":"thunder","name":"Hammerfall","desc":"A returning catch calls one bounded thunder strike at nearby prey.","stats":{}}]
 return PATHS.get(id,{}).get(str(milestone),[])
static func modifiers(id,weapon):
 var out={}
 for milestone in [5,10]:
  for option in choices(id,milestone,weapon):
   if option.id!=weapon.get("branches",{}).get(str(milestone),""):continue
   for key in option.stats:out[key]=out.get(key,0.0)+option.stats[key]
 return out
static var portrait_texture: AtlasTexture
static func portrait():
 if portrait_texture==null:
  portrait_texture=AtlasTexture.new()
  portrait_texture.atlas=preload("res://assets/torr-story/catch.png")
  portrait_texture.region=Rect2(1020,25,300,330)
 return portrait_texture
