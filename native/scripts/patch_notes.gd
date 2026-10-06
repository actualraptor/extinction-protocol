extends RefCounted
## Player-facing changes only; unrevealed content stays out of public notes.
const VERSION="0.13.1"
const TITLE="Hollow Harvest: Framed"
const ENTRIES=[
 {
  "icon": "map",
  "category": "relic",
  "title": "ONE INTEGRATED HUD",
  "body": "The illustrated bottom HUD now uses a continuous frame with bounded layout sections. The minimap, portrait, character name, health, abilities, carried items and utility buttons fit together, including at wider resolutions."
 },
 {
  "icon": "compass",
  "category": "weapon",
  "title": "HEALTH AND EXPERIENCE, REFRAMED",
  "body": "Health and experience displays have received a fresh art pass. The level badge is integrated into the portrait section, and the experience bar sits above the abilities within the HUD frame. Item pages keep overflow accessible through the backpack."
 },
 {
  "icon": "tablet",
  "category": "weapon",
  "title": "MATCHING MENUS AND FIELD PANELS",
  "body": "The pause menu, score panel and location timer now match your selected HUD theme. Location and countdown text are centered more clearly. The pause menu has simpler labels and fewer unnecessary actions."
 },
 {
  "icon": "clock",
  "category": "relic",
  "title": "FIRST ITERATION — KEEP THE FEEDBACK COMING",
  "body": "The new UI remains a first iteration and will have issues. Please report clipped text, scaling problems, awkward spacing or hard-to-read markers. Existing saves and progression are retained. The website now has fresh gameplay screenshots and a short spoiler-free trailer."
 }
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all
