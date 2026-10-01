extends RefCounted
## Player-facing changes only. Preserve older releases in assets/patch-history.json.
const VERSION="0.9.0"
const TITLE="Lasting Expeditions"
const ENTRIES=[
 {"icon":"fire","title":"BOSSES & PORTALS","body":"Defeated bosses no longer leave queued attacks behind. Portals wait until boss loot is claimed. Completed runs cannot take late damage or gain extra score."},
 {"icon":"lightning","title":"DAILY & REWARDS","body":"Caches and shrines wait while another reward is open. New Daily circuits refresh exploration and breakables. Daily rewards cannot be rerolled."},
 {"icon":"frost","title":"PROGRESSION & INTERFACE","body":"Progress can recover from a damaged save using a safety copy. Unlocks and research carry forward. Survivor selection fits smaller screens; large HUD totals stay inside their frames."}
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all
