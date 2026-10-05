extends RefCounted
## Player-facing changes only.
const VERSION="0.11.5"
const TITLE="Relics in Stone"
const ENTRIES=[
 {
  "icon": "prism",
  "category": "relic",
  "title": "POWER DESERVES A BETTER FRAME",
  "body": "Every rarity now has its own detailed painted card. Common is fossil stone and bone; Uncommon is emerald roots; Rare is silver and blue crystal; Epic is thorned bronze and violet arcane stone; Legendary burns with gold and fire; Artifact breaks into prismatic cosmic crystal."
 },
 {
  "icon": "lens",
  "category": "relic",
  "title": "YOUR REWARD TAKES THE SPOTLIGHT",
  "body": "Larger item artwork, engraved title plaques and clear stat panels make each offer easier to read. The cards keep their proportions across screen sizes, including long upgrade descriptions. Your functional tags and affected weapons remain visible."
 },
 {
  "icon": "wrap",
  "category": "relic",
  "title": "CHOOSE. OR BANISH.",
  "body": "Take and Banish now sit inside the card artwork. Banish has a compact dedicated position beside the bottom ornament. Rarity changes the whole card, while your actual rewards and upgrade values remain unchanged."
 }
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all
