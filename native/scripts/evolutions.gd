extends RefCounted
## Original unions: two rank-X weapons become one, via the next cache.
static var UNIONS = preload("res://scripts/god_content.gd").with_unions({
 "plague_furnace":{"parts":["flametorch","miasma"],"name":"PLAGUE FURNACE","desc":"Rotating plague jets poison prey. Poisoned victims release bounded death bursts.","base":"flametorch","beam_base":"flametorch","damage":46.0,"range":175.0,"duration":2.3,"cooldown":2.2,"width":38.0,"color":"a9ef66","tags":["SPELL","OFFENSIVE","BEAM","FIRE","POISON","DOT","AREA","CRITICAL"]},
 "event_lock":{"parts":["plasma_tether","stasis"],"name":"EVENT LOCK","desc":"Plasma connections pulse time fractures before a terminal arc.","base":"plasma_tether","beam_base":"plasma_tether","damage":44.0,"color":"cbb7ff","tags":["SPELL","OFFENSIVE","BEAM","ARCANE","PLASMA","AREA","CROWD_CONTROL","CRITICAL"]},
 "solar_procession":{"parts":["pyre","sunbow"],"name":"SOLAR PROCESSION","desc":"A burning corona releases a radial procession of piercing sun bolts every fourth pulse.","base":"pyre","damage":19.0,"cooldown":.65,"velocity":850.0,"lifetime":.9,"base_pierce":3,"color":"ffe4a0","tags":["SPELL","OFFENSIVE","AURA","PROJECTILE","FIRE","DOT","AREA","CRITICAL"]},
 "polar_crown":{"parts":["winter","glacier"],"name":"POLAR CROWN","desc":"Chilling pulses surround orbiting chakrams before they launch, ricochet and return.","base":"glacier","damage":30.0,"radius":115.0,"cooldown":2.4,"count":2,"lifetime":2.8,"return_after":1.1,"bounce":3,"color":"b7f6ff","terrain_blocks":false},
 "funeral_procession":{"parts":["dread","lantern"],"name":"FUNERAL PROCESSION","desc":"Seeking spirits release expanding spectral pressure waves on impact.","base":"lantern","damage":42.0,"impact_radius":0.0,"cooldown":1.8,"color":"d0b2ff","tags":["SPELL","OFFENSIVE","PROJECTILE","ARCANE","AREA","KNOCKBACK","CRITICAL"]},
 "tempest_anchor":{"parts":["harpoon","thunderstorm"],"name":"TEMPEST ANCHOR","desc":"Piercing harpoons pin prey beneath delayed, localized lightning storms.","base":"harpoon","damage":50.0,"cooldown":1.9,"radius":85.0,"color":"a2d9ff","tags":["WEAPON","PROJECTILE","PHYSICAL","LIGHTNING","GROUND_EFFECT","KNOCKBACK","AREA","CRITICAL"]},
 "prismatic_ouroboros":{"parts":["ricochet","return"],"name":"PRISMATIC OUROBOROS","desc":"Returning crescents ricochet outward and shed short crystal fans on their homeward pass.","base":"return","damage":42.0,"cooldown":2.0,"count":2,"bounce":5,"falloff":.88,"lifetime":4.0,"return_after":1.3,"color":"a2ffe4","terrain_blocks":true,"tags":["SPELL","OFFENSIVE","PROJECTILE","ARCANE","RETURNING","RICOCHET","AREA","CRITICAL"]},

	"thornking":{"parts":["thorns","club"],"name":"IRONBRIAR KING","desc":"Armored thorn bursts slam the horde backward. Retaliation releases a stronger shockwave.","base":"thorns","damage":48.0,"cooldown":1.8,"radius":155.0,"color":"baffb0"},
	"whiteout":{"parts":["lightning","frost"],"name":"WHITEOUT","desc":"Frost lightning and three seeking ice lances. Frozen prey detonate in a bounded ice burst.","base":"lightning","damage":66.0,"cooldown":1.05,"count":5,"radius":90.0,"color":"b8efff","secondary":{"count":3,"power":0.95,"velocity":520.0,"lifetime":1.4,"pierce":2},"projectile_homing":3.0,"tags":["SPELL","OFFENSIVE","CHAIN","LIGHTNING","ICE","FREEZE","CROWD_CONTROL","AREA","CRITICAL"]},
	"supernova":{"parts":["fire","mortar"],"name":"SUPERNOVA","desc":"Solar bombardments ignite lingering fields, followed by a final eruption.","base":"mortar","damage":175.0,"cooldown":2.8,"duration":2.4,"color":"ffac65","tags":["SPELL","OFFENSIVE","GROUND_EFFECT","FIRE","DOT","EXPLOSION","AREA"]},
	"lastword":{"parts":["revolver","shotgun"],"name":"THE LAST WORD","desc":"A rapid fan of long-range, piercing execution rounds.","base":"shotgun","damage":36.0,"cooldown":0.75,"velocity":760.0,"lifetime":1.4,"color":"ffe6ab"},
	"earthshaker":{"parts":["club","spear"],"name":"EARTHSHAKER","desc":"Huge circular cleaves repeat and launch piercing shockwaves.","base":"club","damage":108.0,"cooldown":1.05,"radius":185.0,"color":"ffd29a"},
	"bastion":{"parts":["orbital","aegis"],"name":"RIFT BASTION","desc":"A halo of heavy blades carves enemies and recharges a barrier every eight seconds.","base":"orbital","damage":46.0,"cooldown":0.48,"radius":120.0,"color":"8affdf"}
})
const SOLO = {
	"revolver":"Piercing execution volleys with more rounds and faster reloads.",
	"shotgun":"A dense fan of piercing pellets with faster reloads.",
	"club":"Full-circle cleaves with echo strikes and shockwaves.",
	"spear":"Long-reaching thrusts with repeated piercing shockwaves.",
	"frost":"Seeking ice lances freeze faster and pierce deeper.",
	"fire":"Larger explosive fireballs with stronger lingering burns.",
	"lightning":"Longer chains with branching arcs and reduced damage falloff.",
	"orbital":"More blades orbit farther out and cut through a wider area.",
	"mortar":"Wider bombardments leave burning craters.",
	"thunderstorm":"Wider storm fields strike twice as often for three seconds.",
	"pyre":"A larger burning corona erupts outward every fourth pulse.",
	"winter":"A wider blizzard freezes sooner and holds enemies longer.",
	"miasma":"A spreading toxic halo with stronger, longer-lasting poison.",
	"dread":"Wider spectral eruptions push the horde back harder.",
	"aegis":"A larger, faster-recharging barrier retaliates when broken.",
	"stasis":"Longer time fractures stop lesser enemies and their projectiles."
}
static func enrich(out):
	for id in UNIONS:
		var recipe = UNIONS[id]
		out[id] = out[recipe.base].duplicate(true)
		out[id].merge(recipe,true)
		out[id].fusion = true
		out[id].evolution = recipe.name
	for id in SOLO: out[id].evolution_desc = SOLO[id]
	return out
static func ready(g):
	var offers = []
	for id in UNIONS:
		if g.weapons.has(id) or not preload("res://scripts/god_content.gd").allowed(g.C.HEROES[g.hero],g.C.WEAPONS[id]): continue
		var valid = true
		for part in UNIONS[id].parts:
			if not g.weapons.has(part) or g.weapons[part].level<10: valid = false
		if valid: offers.append({"type":"fusion","id":id})
	if not offers.is_empty(): return offers
	for id in g.weapons:
		var w = g.weapons[id]
		if g.C.WEAPONS[id].delivery=="beam":continue
		if preload("res://scripts/god_content.gd").allowed(g.C.HEROES[g.hero],g.C.WEAPONS[id]) and not w.evolved and w.level>=10: offers.append({"type":"evolution","id":id})
	return offers
static func consumed(g,id):
	for owned in g.weapons:
		if UNIONS.has(owned) and id in UNIONS[owned].parts: return true
	return false
static func hint(id,catalog):
	var lines = []
	for result in UNIONS:
		if id not in UNIONS[result].parts: continue
		var parts = UNIONS[result].parts
		var other = parts[1] if parts[0]==id else parts[0]
		lines.append("Union: + "+catalog[other].name+" (both weapons rank 10) → "+UNIONS[result].name+" (chest)")
	return "\n".join(lines)
