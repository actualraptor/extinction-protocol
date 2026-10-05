"""Prepare local player-facing release notes. Never publishes."""
import release_fortune_011 as notes
notes.VERSION='0.11.5'
notes.TITLE='Relics in Stone'
notes.entries=[
 ('prism','relic','POWER DESERVES A BETTER FRAME','Every rarity now has its own detailed painted card. Common is fossil stone and bone; Uncommon is emerald roots; Rare is silver and blue crystal; Epic is thorned bronze and violet arcane stone; Legendary burns with gold and fire; Artifact breaks into prismatic cosmic crystal.'),
 ('lens','relic','YOUR REWARD TAKES THE SPOTLIGHT','Larger item artwork, engraved title plaques and clear stat panels make each offer easier to read. The cards keep their proportions across screen sizes, including long upgrade descriptions. Your functional tags and affected weapons remain visible.'),
 ('wrap','relic','CHOOSE. OR BANISH.','Take and Banish now sit inside the card artwork. Banish has a compact dedicated position beside the bottom ornament. Rarity changes the whole card, while your actual rewards and upgrade values remain unchanged.'),
]
def render(data):
 source=notes.Path(notes.__file__).read_text(encoding='utf-8-sig')
 source=source.replace("'FORTUNE'","'RELICS'").replace("'AND FANG'","'IN STONE'").replace('0.11.0  /  HOLLOW HARVEST CONTINUES','0.11.5  /  HOLLOW HARVEST CONTINUES').replace('One lucky find. A whole new build.','Power deserves a better frame.')
 namespace={'__file__':notes.__file__,'__name__':'release_renderer'}
 exec(source,namespace)
 namespace['VERSION']=notes.VERSION
 namespace['render'](data)
notes.render=render
notes.prepare()
for name in ['project.godot','export_presets.cfg','scripts/daily_challenge.gd','scripts/expedition.gd']:
 p=notes.NATIVE/name
 p.write_text(p.read_text(encoding='utf-8-sig').replace('0.11.4','0.11.5'),encoding='utf-8')
