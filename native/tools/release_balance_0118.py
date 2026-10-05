import release_fortune_011 as n
n.VERSION='0.11.8';n.TITLE='Hollow Harvest: Fortune and Fury'
n.entries=[('prism','relic','CRITICAL COMMITMENT','Critical chance returns to its original diminishing curve: the first 100 points count fully, the next 100 at 65%, the next 200 at 40%, and further gains at 25%. Crit damage remains multiplicative at 1.9x per tier. Card previews show effective chance.'),('lens','relic','FORTUNE REBALANCED','Luck returns to its original rarity-weight curve. Artifact base odds remain 0.3%; higher Luck improves rare tiers gradually. Chest and upgrade odds use the same curve, with chest bad-luck protection retained.'),('map','relic','LET THE EARTH BREAK','Kael, World Breaker and Earth Shaker no longer have a 300-unit Area radius cap. Ground fractures follow the actual damage radius while their geometry remains bounded. Main hits leave stationary cracks and a small crater; echoes keep their damage without extra stamps.')]
def render(data):
 source=n.Path(n.__file__).read_text(encoding='utf-8-sig').replace("'FORTUNE'","'HOLLOW'").replace("'AND FANG'","'HARVEST'").replace('0.11.0  /  HOLLOW HARVEST CONTINUES','0.11.8  /  FORTUNE AND FURY').replace('One lucky find. A whole new build.','Power rewards commitment.')
 ns={'__file__':n.__file__,'__name__':'release_renderer'};exec(source,ns);ns['VERSION']=n.VERSION;ns['render'](data)
n.render=render;n.prepare()
for name in ['project.godot','export_presets.cfg','scripts/daily_challenge.gd','scripts/expedition.gd']:
 p=n.NATIVE/name;p.write_text(p.read_text(encoding='utf-8-sig').replace('0.11.7','0.11.8'),encoding='utf-8')
p=n.NATIVE/'RELEASE-0.11.8.md';p.write_text(p.read_text()+'\n\nKnown card layout issues remain tracked in GitHub issue #2. Linux build is unverified.\n',encoding='utf-8')
