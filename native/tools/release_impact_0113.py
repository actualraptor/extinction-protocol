"""Generate local player notes and shareable artwork. Never publishes."""
import release_fortune_011 as notes
notes.VERSION='0.11.3'
notes.TITLE='Impact and Instinct'
notes.entries=[
 ('thorn','boss','THE HUNT COMES TO YOU','All six roaming bosses now pursue you between their attacks, with speeds suited to each creature. Committed windups still give you time to react. Extinction remains rooted in its arena. Boss health stays at 90,000 / 900,000 / 60,000,000 across the three encounters.'),
 ('revolver','weapon','FROM THE MUZZLE','Voss fires her starter revolver from the tip of her gun, including follow-up shots. The muzzle follows her firing pose and facing direction. Moving and attacking quickly keep the shot connected to her current position.'),
 ('lightning','weapon','FROM THE STAFF','Stormbinder now begins at Vesper\'s staff crystal. Normal and Halloween poses use their own emission points. The lightning keeps its existing targeting range and chain behavior.'),
 ('crit','passive','CRITICAL MASS','Critical chance now stacks without diminishing returns. Every full 100% guarantees another crit tier: 250% means every hit is a double crit, with a 50% chance to become a triple crit. Higher tiers gain distinct colors, stronger outlines and larger numbers with an explicit multiplier.'),
 ('prism','relic','FORTUNE FAVORS THE BOLD','Luck shifts Common odds toward every higher rarity, with more weight reaching Epic, Legendary and Artifact. At +84% Luck, ordinary chest odds include 5.71% Legendary and 1.05% Artifact. Bad-luck protection still guarantees Rare or better after four low-tier chests.'),
 ('lightning','weapon','POWER YOU CAN HEAR','Voss\'s revolver gains a warmer crack, mechanical detail and a weightier tail. Stormbinder gains rounded thunder and electrical crackle, with softer chain impacts. Subtle sound variations keep repeated attacks less repetitive.'),
]

def render(data):
 source=notes.Path(notes.__file__).read_text(encoding='utf-8-sig')
 source=source.replace("'FORTUNE'","'IMPACT'").replace("'AND FANG'","'AND INSTINCT'").replace('0.11.0  /  HOLLOW HARVEST CONTINUES','0.11.3  /  HOLLOW HARVEST CONTINUES').replace('One lucky find. A whole new build.','Every shot. Every chain. Every critical hit.')
 source=source.replace("else 'relics-'","else 'weapons-' if entry['category']=='weapon' else 'upgrades-' if entry['category']=='passive' else 'relics-'")
 namespace={'__file__':notes.__file__,'__name__':'release_renderer'}
 exec(source,namespace)
 namespace['VERSION']=notes.VERSION
 namespace['render'](data)
notes.render=render
notes.prepare()
for name in ['project.godot','export_presets.cfg','scripts/daily_challenge.gd','scripts/expedition.gd']:
 p=notes.NATIVE/name
 p.write_text(p.read_text(encoding='utf-8-sig').replace('0.11.2','0.11.3'),encoding='utf-8')
