extends RefCounted
## Player-facing changes only.
const VERSION="0.11.7"
const TITLE="Hollow Harvest: Scars of the Earth"
const ENTRIES=[
 {
  "icon": "map",
  "category": "relic",
  "title": "LEAVE YOUR MARK",
  "body": "Kael leaves a small crater and branching ground fractures at the main impact point. World Breaker glows yellow; Earth Shaker glows red. Scars stay on the ground and fade. The visible footprint grows with the actual damage radius."
 },
 {
  "icon": "map",
  "category": "relic",
  "title": "MORE HITS. LESS OVERHEAD.",
  "body": "Echoes and aftershocks retain their damage without creating extra crater or crack stamps. Cached, bounded fracture geometry replaces the costly rising debris and moving glow fronts."
 },
 {
  "icon": "lens",
  "category": "relic",
  "title": "FORTUNE FINDS ITS BALANCE",
  "body": "Luck now adds one fifth of its previous rarity-roll bonus. +10% Luck adds two roll points instead of ten. The displayed Luck stat is unchanged; chest odds and upgrade rolls use the tuned bonus."
 },
 {
  "icon": "prism",
  "category": "relic",
  "title": "A CRIT ON YOUR CRIT",
  "body": "Critical damage multiplies again at each tier: 1.9x, 3.61x, 6.859x and beyond. Ordinary enemies show the full hit value, including overkill, while damage statistics still count only health removed. Boss resistance and phase gates remain intact."
 }
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all
