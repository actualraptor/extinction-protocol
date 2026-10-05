extends RefCounted
const VERSION="0.12.0"
const TITLE="Hollow Harvest: Extinction Rises"
const ENTRIES=[
 {"icon":"map","category":"relic","title":"A WORLD OUT OF TIME","body":"A narrated illustrated opening welcomes new players, with atmospheric music and subtle motion. Replay it from the main menu."},
 {"icon":"club","category":"weapon","title":"EXTINCTION WITHIN REACH","body":"The meteor now has 20 million health. Victory has room to settle before the ending, followed by rolling credits."},
 {"icon":"prism","category":"relic","title":"FASTER TEST RUNS","body":"An optional password-protected test mode uses an isolated save, a powerful Kael build, 10x simulation speed, automatic upgrades and automatic portal approach."}
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all
