extends RefCounted
## Player-facing changes only; unrevealed content stays out of public notes.
const VERSION="0.13.0"
const TITLE="Hollow Harvest: Fieldwork"
const ENTRIES=[
 {
  "icon": "map",
  "category": "relic",
  "title": "A NEW HUD — FIRST ITERATION",
  "body": "The bottom HUD has a new illustrated layout, character-themed frames, portraits, health and experience displays, and integrated backpack, amber and re-roll panels. This is the first iteration: expect layout, scaling and visual issues while we refine it. The experience bar still needs further polish."
 },
 {
  "icon": "compass",
  "category": "weapon",
  "title": "READ THE FIELD",
  "body": "The minimap shows a wider view of explored ground. Both maps show terrain, locations, chests and pickups, including magnets, so useful supplies are easier to find. Carried items use pages when the HUD runs out of room; your backpack still holds them."
 },
 {
  "icon": "tablet",
  "category": "weapon",
  "title": "CLEARER UPGRADE CHOICES",
  "body": "Upgrade cards, Take buttons and re-roll controls have a new art pass. Reward previews and evolution reveals show more useful information about the upgrade you are choosing."
 },
 {
  "icon": "club",
  "category": "weapon",
  "title": "ENCOUNTER AND PRESENTATION POLISH",
  "body": "Boss names and health-bar frames better match each encounter. Large enemies can move through crowds more reliably, and charging allies can no longer shove the meteor. Animation, transitions and effects have received another polish pass."
 },
 {
  "icon": "clock",
  "category": "relic",
  "title": "CONTROL YOUR SOUND",
  "body": "Settings now includes separate volume controls for effects, music, voices and cinematics. Existing progression is retained when you update."
 }
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all
