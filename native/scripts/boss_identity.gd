extends RefCounted
# Stable encounter keys remain independent of player-facing names and saves.
const DATA={
 "thorn":{"name":"GORATH","title":"THE THORN CROWN","frame":0,"color":"a6d96a"},
 "basalt":{"name":"BASALT","title":"THE BEHEMOTH","frame":1,"color":"ff8c38"},
 "hunt":{"name":"SKARN","title":"THE PALE HUNT","frame":2,"color":"a4eaff"},
 "aurora":{"name":"VAELITH","title":"THE AURORA MAW","frame":3,"color":"b9a0ff"},
 "warden":{"name":"ORRAX","title":"THE MERIDIAN WARDEN","frame":4,"color":"e6c875"},
 "bloom":{"name":"MYRKHUL","title":"THE BLOOM BELOW","frame":5,"color":"bbd665"},
 "meteor":{"name":"EXTINCTION ENGINE","title":"","frame":6,"color":"ff6942"}
}
static func short_name(identity):return DATA.get(identity,DATA.meteor).name
static func full_name(identity):
 var entry=DATA.get(identity,DATA.meteor)
 return entry.name+", "+entry.title if not entry.title.is_empty() else "THE "+entry.name
