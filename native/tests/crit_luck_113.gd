extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=preload("res://scripts/expedition.gd").new();g.setup(1,"expedition",{},55)
 assert(is_equal_approx(g.crit_curve(2.5),1.85) and is_equal_approx(g.crit_curve(100),26.45))
 var counts={2:0,3:0}
 for i in range(10000):counts[g.roll_crit_tier(2.5)]+=1
 assert(counts[2]>4700 and counts[3]>4700)
 var previous=g.Relics.odds(g,false)[5]
 for luck in [.1,.84,2.0,10.0,100.0]:
  g.permanent_luck=luck
  var odds=g.Relics.odds(g,false);var total=0.0
  for i in range(6):
   total+=odds[i]
   assert(odds[i]>=0)
  assert(odds[5]>=previous)
  assert(absf(total-100)<.001);previous=odds[5]
  if luck==.84:print("84% Luck odds / ",odds)
 print("DIMINISHING CRIT / 250% double/triple distribution ",counts," / original Luck Artifact odds and normalization passed")
 quit()

