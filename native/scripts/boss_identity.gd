extends RefCounted
# Stable encounter keys remain independent of player-facing names and saves.
const DATA={
 "thorn":{"name":"TRICERATOPS","species":"Triceratops","title":"THE HORN CROWN","frame":0,"color":"a6d96a"},
 "basalt":{"name":"TYRANNOSAURUS REX","species":"Tyrannosaurus rex","title":"THE APEX TYRANT","frame":1,"color":"ff8c38"},
 "hunt":{"name":"CRYOLOPHOSAURUS","species":"Cryolophosaurus","title":"THE FROZEN CREST","frame":2,"color":"a4eaff"},
 "aurora":{"name":"YUTYRANNUS","species":"Yutyrannus","title":"THE FEATHERED KING","frame":3,"color":"b9a0ff"},
 "warden":{"name":"THERIZINOSAURUS","species":"Therizinosaurus","title":"THE SCYTHE CLAW","frame":4,"color":"e6c875"},
 "bloom":{"name":"SPINOSAURUS","species":"Spinosaurus","title":"THE SAILBACK","frame":5,"color":"bbd665"},
 "meteor":{"name":"EXTINCTION ENGINE","title":"","frame":6,"color":"ff6942"}
}
static func short_name(identity):return DATA.get(identity,DATA.meteor).name
static func full_name(identity):
 var entry=DATA.get(identity,DATA.meteor)
 return entry.name+", "+entry.title if not entry.title.is_empty() else "THE "+entry.name
