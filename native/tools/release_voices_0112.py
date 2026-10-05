"""Generate local player notes and shareable artwork. Never publishes."""
import release_fortune_011 as notes
notes.VERSION='0.11.2'
notes.TITLE='Voices and Power'
notes.entries=[
 ('revolver','weapon','THE GUNSLINGER FINDS HER VOICE','Mara Voss now speaks when selected, hurt, low on health, leveling up, meeting a boss, defeating it and dying. Twenty-five recordings play through one speech channel. Important announcements take priority; frequent events have chances and cooldowns.'),
 ('lightning','weapon','THE RIFTWALKER ANSWERS','Vesper brings twenty-three voice lines across the same seven events. Each survivor uses their own recordings. Switching heroes stops the previous voice; variants avoid consecutive repeats. Sound effects settings also control voices.'),
 ('prism','relic','RARITY YOU CAN RECOGNIZE','Stone cards have stronger rarity-colored borders, corner gems and tier runes. Rare cards gain animated highlights, Epic glows violet, Legendary burns orange and Artifact shines with iridescent gold. The carved text area stays clear.'),
 ('revolver','weapon','A SHOT. A SPELL. A REAL ATTACK.','Voss now draws, aims, fires and recoils with her starter revolver. Vesper gathers energy, lifts her staff and releases Stormbinder. Both have normal and Halloween attack poses. Attacks remain mobile, speed up with attack speed and release their damage and sound on the attack frame. Other weapons keep firing independently.'),
 ('thorn','boss','APEX MEANS APEX','Boss health is now ten times higher across every map: 90,000 for first bosses, 900,000 for second bosses and 60,000,000 for Extinction. Innate resistance and earned vulnerable windows remain. Daily circuits retain their rising health. Extinction\'s anchors remain breakable weak points.'),
 ('frost','weapon','TAGS THAT EXPLAIN YOUR BUILD','Weapon is no longer shown as a card tag: it was a category label. Frost stays because ice damage and status strength can be improved. Functional tags are prioritized so delivery and element bonuses remain visible.'),
]
def render(data):
 source=notes.Path(notes.__file__).read_text(encoding='utf-8-sig')
 source=source.replace("'FORTUNE'","'VOICES'").replace("'AND FANG'","'AND POWER'").replace('0.11.0  /  HOLLOW HARVEST CONTINUES','0.11.2  /  HOLLOW HARVEST CONTINUES').replace('One lucky find. A whole new build.','Every survivor has something to say.')
 source=source.replace("else 'relics-'","else 'weapons-' if entry['category']=='weapon' else 'upgrades-' if entry['category']=='passive' else 'relics-'")
 namespace={'__file__':notes.__file__,'__name__':'release_renderer'}
 exec(source,namespace);namespace['VERSION']=notes.VERSION;namespace['render'](data)
notes.render=render
notes.prepare()
for name in ['project.godot','export_presets.cfg','scripts/daily_challenge.gd','scripts/expedition.gd']:
 p=notes.NATIVE/name
 p.write_text(p.read_text(encoding='utf-8-sig').replace('0.11.1','0.11.2'),encoding='utf-8')
