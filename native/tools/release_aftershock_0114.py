"""Generate local player notes and shareable artwork. Never publishes."""
import release_fortune_011 as notes
notes.VERSION='0.11.4'
notes.TITLE='Aftershock'
notes.entries=[
 ('club','weapon','MAKE THE EARTH ANSWER','Kael smashes the ground and sends rapid, staggered shock fronts outward. Each front erupts around the impact, with dirt, ice or stone thrown upward to match the stage. World Breaker gains a stronger wave sequence. Each enemy takes one hit per shockwave, even when crossing its bands.'),
 ('earthshaker','weapon','EARTH SHAKER. STILL KAEL.','Combining into Earth Shaker keeps Kael\'s painted slam animation and the new radial eruption effects. Its stronger shockwave replaces the old effect. High attack speed accelerates the slam without losing the impact frame.'),
 ('crit','passive','CRITS THAT SPEAK FOR THEMSELVES','Damage numbers no longer show a crit multiplier suffix. Double, triple and higher crits have stronger colors, larger animated pops and expanding impact crowns. Extreme crit tiers become prismatic. Linear crit chance and damage scaling stay unchanged.'),
 ('magnet','relic','LEAVE NO EXPERIENCE BEHIND','Gravity Well now lasts five seconds and keeps drawing in newly dropped XP. Buffs and other pickups stay where they fell. Defeating a boss sweeps up all XP already on the ground once, without granting a timed magnet.'),
 ('prism','relic','LET FORTUNE RUN WILD','Luck now adds directly to the rarity roll: +10% Luck adds ten points to a roll from zero to 100. Overflow becomes Artifact, with no diminishing curve. At +10% Luck, Artifact odds are 10.3%; at +84%, they are 84.3%. The reel shows your actual odds. Bad-luck protection remains.'),
 ('meteor','boss','POWER DESERVES A NEW BALANCE','Extinction now has 30,000,000 health, down from 60,000,000: five times its original health. First and second bosses retain 90,000 and 900,000 health. Daily circuit health scaling and boss resistance remain.'),
 ('prism','relic','A CARD WORTH ITS RARITY','Common is chipped stone; Uncommon grows moss and vines; Rare is faceted ice; Epic is occult obsidian; Legendary is forged sun-metal; Artifact is celestial glass. Each tier has its own face, material and ornaments, with stronger animated accents for the highest rarities.'),
]
def render(data):
 source=notes.Path(notes.__file__).read_text(encoding='utf-8-sig')
 source=source.replace("'FORTUNE'","'AFTERSHOCK'").replace("'AND FANG'","'THE EARTH ANSWERS'").replace('0.11.0  /  HOLLOW HARVEST CONTINUES','0.11.4  /  HOLLOW HARVEST CONTINUES').replace('One lucky find. A whole new build.','More impact. Wilder fortune. Greater power.')
 source=source.replace("heading=ImageFont.truetype(str(fonts/'Cinzel.ttf'),70)","heading=ImageFont.truetype(str(fonts/'Cinzel.ttf'),54)")
 source=source.replace("else 'relics-'","else 'weapons-' if entry['category']=='weapon' else 'upgrades-' if entry['category']=='passive' else 'relics-'")
 namespace={'__file__':notes.__file__,'__name__':'release_renderer'}
 exec(source,namespace)
 namespace['VERSION']=notes.VERSION
 namespace['render'](data)
notes.render=render
notes.prepare()
for name in ['project.godot','export_presets.cfg','scripts/daily_challenge.gd','scripts/expedition.gd']:
 p=notes.NATIVE/name
 p.write_text(p.read_text(encoding='utf-8-sig').replace('0.11.3','0.11.4'),encoding='utf-8')
