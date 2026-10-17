extends RefCounted
## Player-facing changes only; unrevealed content stays out of public notes.
const VERSION="0.15.0"
const TITLE="Torr Stormbuk"
const ENTRIES=[
  {
    "icon": "mjolnir",
    "category": "weapon",
    "title": "TORR STORMBUK",
    "body": "Discover a new survivor and his divine arsenal. His returning hammer can ricochet through enemies or become a permanent ring that follows him."
  },
  {
    "icon": "worldwake",
    "category": "weapon",
    "title": "A DIVINE ARSENAL",
    "body": "Eight [God] weapons, distinct rank-5 and rank-10 paths, and discoverable combinations. God equipment belongs to God survivors; ordinary heroes keep their own drafts."
  },
  {
    "icon": "mjolnir",
    "category": "weapon",
    "title": "PAINTED MOTION AND A STORMY TALE",
    "body": "Independent walking, throwing and catching poses, recorded battle lines, and an illustrated first-time lesson that grants a useful replacement reward. Completed stories can be replayed from Settings."
  },
  {
    "icon": "spear",
    "category": "weapon",
    "title": "BUILD AND RUN PRESENTATION",
    "body": "The current weapon path, combination and rarity celebrations are included, alongside the ornate run scoreboard and individual damage and kill leaders."
  }
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all
