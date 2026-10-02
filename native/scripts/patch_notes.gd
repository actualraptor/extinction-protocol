extends RefCounted
## Player-facing changes only. Preserve older releases in assets/patch-history.json.
const VERSION="0.9.2"
const TITLE="The World Opens Up"
const ENTRIES=[
 {
  "icon": "map", "category": "relic",
  "title": "THREE AUTHORED STAGES",
  "body": "Lost Cradle, Frostbreak Expanse and the Sunken Observatory now use large continuous maps with distinct terrain, landmarks, routes and escalating stage modifiers."
 },
 {
  "icon": "camp", "category": "relic",
  "title": "FAR OBJECTIVES",
  "body": "World caches, build passives and discovery signals are placed across the stage. The atlas projects major objectives and lets you pin a route."
 },
 {
  "icon": "meteor", "category": "relic",
  "title": "STAGE PRESSURE",
  "body": "Each map now has its own horde density, XP, luck or movement identity. Distant ordinary enemies recycle safely while bosses and discoveries stay readable."
 },
 {
  "icon": "camp", "category": "relic",
  "title": "KAEL LEADS THE EXPEDITION",
  "body": "Kael is the guaranteed starting survivor. Other survivors remain unlockable through discoveries and milestones."
 },
 {
  "icon": "frost", "category": "relic",
  "title": "VESPER RECAST",
  "body": "Vesper now uses a new directional female mage walk cycle in-game, with readable front, side and back poses."
 },
 {
  "icon": "lightning",
  "title": "WEAPON UNIONS",
  "body": "Both weapons must now reach rank 10 before they can merge. A qualifying chest creates the union and frees one weapon slot."
 },
 {
  "icon": "thorns",
  "title": "BUILD COMMITMENT",
  "body": "Passive and augment upgrades share eight type slots. Owned upgrades can still reach maximum rank. Relics keep their separate eight slots; a full satchel no longer replaces your chosen relics. Full builds receive amber supplies."
 },
 {
  "icon": "magnet", "category": "relic",
  "title": "MAGNET PICKUPS",
  "body": "Magnets collect experience only. Amber, healing and other pickups stay on the ground until you collect them."
 },
 {
  "icon": "mortar",
  "title": "SCORCHED EARTH",
  "body": "Mortar and Supernova shell impacts can no longer be blocked by weaker burn ticks. Each shell leaves a visible ember crater lasting as long as its damage. Ordinary mortar loses its extra expiry explosion; Supernova keeps its final eruption."
 },
 {
  "icon": "chest", "category": "relic",
  "title": "THE ARCHIVE",
  "body": "Reset permanent research to reclaim the amber you spent. Paid discovery unlocks can also be refunded without losing discoveries found during runs. Research and discoveries now use recognizable painted icons."
 },
 {
  "icon": "chronicle", "category": "relic",
  "title": "RUN RESULTS",
  "body": "Weapon damage rows fit inside the fossil frame. Large totals stay within their columns, and the gameplay HUD stays hidden behind the final scoreboard."
 }
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all


