extends RefCounted
## Player-facing changes only; unrevealed content stays out of public notes.
const VERSION="0.14.3"
const TITLE="Boss Build Fixes"
const ENTRIES=[
  {
    "icon": "mortar",
    "category": "weapon",
    "title": "BOSS BUILD FIXES",
    "body": "Boss attack artwork is now bundled inside the game, missing runtime dependencies are restored, and experimental beam audio is kept out of ordinary gameplay."
  },
  {
    "icon": "thorns",
    "category": "weapon",
    "title": "THE DINOSAUR BOSS REWORK",
    "body": "T-rex and Triceratops are finished in the public build, with rebuilt models, grounded pursuit, directional attacks, clearer spacing and creature sound."
  },
  {
    "icon": "mortar",
    "category": "weapon",
    "title": "METEOR: FIRST PASS",
    "body": "Meteor has entered its first reconstructed presentation pass. Entrance motion, shell animation, fire pressure and randomized waves will continue to receive updates."
  },
  {
    "icon": "spear",
    "category": "weapon",
    "title": "A PREHISTORIC WORLD",
    "body": "Individually rebuilt dinosaur and boss artwork brings cleaner silhouettes, corrected anatomy and clearer creatures across all three maps. The opening story now matches the prehistoric roster."
  },
  {
    "icon": "compass",
    "category": "weapon",
    "title": "SURVIVE THE STAMPEDE",
    "body": "Tightly packed Compy flocks rush across the battlefield, pushing survivors and nearby creatures aside. The first stampede arrives around 45 seconds into a run."
  },
  {
    "icon": "tablet",
    "category": "weapon",
    "title": "A NEW HOME FOR DISCOVERIES",
    "body": "Browse a large discovery grid with categories, unlock states, requirements and a dedicated detail panel. Main-menu buttons, the official logo, moving mist and flickering lights give the menu a fresh look."
  },
  {
    "icon": "clock",
    "category": "relic",
    "title": "SOUNDTRACK AND A MOMENT TO BREATHE",
    "body": "New orchestral themes accompany the maps and boss encounters, including a full score for the final countdown. Defeating a boss grants a brief respite from new spawns while the next horde gathers."
  }
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all
