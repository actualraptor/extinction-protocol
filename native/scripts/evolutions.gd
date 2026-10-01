extends RefCounted
## Original unions: two rank-X weapons become one, via the next cache.
const UNIONS = {
	"thornking":{"parts":["thorns","club"],"name":"IRONBRIAR KING","desc":"Armored thorn bursts slam the horde backward. Retaliation releases a stronger shockwave.","base":"thorns","damage":48.0,"cooldown":1.8,"radius":155.0,"color":"baffb0"},
	"whiteout":{"parts":["lightning","frost"],"name":"WHITEOUT","desc":"Frost lightning and three seeking ice lances. Frozen prey detonate in a bounded ice burst.","base":"lightning","damage":66.0,"cooldown":1.05,"count":5,"radius":90.0,"color":"b8efff","secondary":{"count":3,"power":0.95,"velocity":520.0,"lifetime":1.4,"pierce":2},"projectile_homing":3.0,"tags":["SPELL","OFFENSIVE","CHAIN","LIGHTNING","ICE","FREEZE","CROWD_CONTROL","AREA","CRITICAL"]},
	"supernova":{"parts":["fire","mortar"],"name":"SUPERNOVA","desc":"Solar bombardments ignite lingering fields, followed by a final eruption.","base":"mortar","damage":175.0,"cooldown":2.8,"duration":2.4,"color":"ffac65","tags":["SPELL","OFFENSIVE","GROUND_EFFECT","FIRE","DOT","EXPLOSION","AREA"]},
	"lastword":{"parts":["revolver","shotgun"],"name":"THE LAST WORD","desc":"A rapid fan of long-range, piercing execution rounds.","base":"shotgun","damage":36.0,"cooldown":0.75,"velocity":760.0,"lifetime":1.4,"color":"ffe6ab"},
	"earthshaker":{"parts":["club","spear"],"name":"EARTHSHAKER","desc":"Huge circular cleaves repeat and launch piercing shockwaves.","base":"club","damage":108.0,"cooldown":1.05,"radius":185.0,"color":"ffd29a"},
	"bastion":{"parts":["orbital","aegis"],"name":"RIFT BASTION","desc":"A halo of heavy blades carves enemies and recharges a barrier every eight seconds.","base":"orbital","damage":46.0,"cooldown":0.48,"radius":120.0,"color":"8affdf"}
}
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
		if g.weapons.has(id): continue
		var valid = true
		for part in UNIONS[id].parts:
			if not g.weapons.has(part) or g.weapons[part].level<10: valid = false
		if valid: offers.append({"type":"fusion","id":id})
	if not offers.is_empty(): return offers
	for id in g.weapons:
		var w = g.weapons[id]
		if not w.evolved and w.level>=10: offers.append({"type":"evolution","id":id})
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
