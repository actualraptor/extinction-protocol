extends RefCounted
## Player-facing changes only.
const VERSION="0.11.8"
const TITLE="Hollow Harvest: Fortune and Fury"
const ENTRIES=[
 {
  "icon": "prism",
  "category": "relic",
  "title": "CRITICAL COMMITMENT",
  "body": "Critical chance returns to its original diminishing curve: the first 100 points count fully, the next 100 at 65%, the next 200 at 40%, and further gains at 25%. Crit damage remains multiplicative at 1.9x per tier. Card previews show effective chance."
 },
 {
  "icon": "lens",
  "category": "relic",
  "title": "FORTUNE REBALANCED",
  "body": "Luck returns to its original rarity-weight curve. Artifact base odds remain 0.3%; higher Luck improves rare tiers gradually. Chest and upgrade odds use the same curve, with chest bad-luck protection retained."
 },
 {
  "icon": "map",
  "category": "relic",
  "title": "LET THE EARTH BREAK",
  "body": "Kael, World Breaker and Earth Shaker no longer have a 300-unit Area radius cap. Ground fractures follow the actual damage radius while their geometry remains bounded. Main hits leave stationary cracks and a small crater; echoes keep their damage without extra stamps."
 }
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all
