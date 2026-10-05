import release_fortune_011 as n
n.VERSION='0.11.7';n.TITLE='Hollow Harvest: Scars of the Earth'
n.entries=[('map','relic','LEAVE YOUR MARK','Kael leaves a small crater and branching ground fractures at the main impact point. World Breaker glows yellow; Earth Shaker glows red. Scars stay on the ground and fade. The visible footprint grows with the actual damage radius.'),('map','relic','MORE HITS. LESS OVERHEAD.','Echoes and aftershocks retain their damage without creating extra crater or crack stamps. Cached, bounded fracture geometry replaces the costly rising debris and moving glow fronts.'),('lens','relic','FORTUNE FINDS ITS BALANCE','Luck now adds one fifth of its previous rarity-roll bonus. +10% Luck adds two roll points instead of ten. The displayed Luck stat is unchanged; chest odds and upgrade rolls use the tuned bonus.'),('prism','relic','A CRIT ON YOUR CRIT','Critical damage multiplies again at each tier: 1.9x, 3.61x, 6.859x and beyond. Ordinary enemies show the full hit value, including overkill, while damage statistics still count only health removed. Boss resistance and phase gates remain intact.')]
original=n.render
def render(data):
 source=n.Path(n.__file__).read_text(encoding='utf-8-sig').replace("'FORTUNE'","'HOLLOW'").replace("'AND FANG'","'HARVEST'").replace('0.11.0  /  HOLLOW HARVEST CONTINUES','0.11.7  /  SCARS OF THE EARTH').replace('One lucky find. A whole new build.','The ground remembers every blow.')
 ns={'__file__':n.__file__,'__name__':'release_renderer'};exec(source,ns);ns['VERSION']=n.VERSION;ns['render'](data)
n.render=render;n.prepare()
for name in ['project.godot','export_presets.cfg','scripts/daily_challenge.gd','scripts/expedition.gd']:
 p=n.NATIVE/name;p.write_text(p.read_text(encoding='utf-8-sig').replace('0.11.6','0.11.7'),encoding='utf-8')
p=n.NATIVE/'RELEASE-0.11.7.md';p.write_text(p.read_text(encoding='utf-8')+'\n\nKnown card layout issues remain tracked in GitHub issue #2. Linux build is unverified. Human-directed hobby project with extensive AI assistance.\n',encoding='utf-8')
