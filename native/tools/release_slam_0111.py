"""Player notes for the local follow-up. Does not publish."""
import release_fortune_011 as notes
notes.VERSION='0.11.1'
notes.TITLE='Stone and Thunder'
notes.entries=[
 ('thorn','boss','BOSSES FIGHT BACK','First bosses now resist 50% of damage. Second bosses resist 60%. The Extinction Engine resists 70%. Breaking a boss\'s defense lowers resistance by 25 percentage points. Destroy Extinction\'s anchors to open its core: resistance drops from 88% to 40% during the damage window.'),
 ('club','weapon','KAEL BRINGS THE HAMMER DOWN','Kael\'s starter attack is now a full ground slam with anticipation, overhead swing, impact and recovery. Damage lands on impact in a circular shockwave. Move freely while attacking. Windup and recovery speed up with your attack speed, with a much faster maximum slam cadence. His pumpkin club joins the Halloween version.'),
 ('crit','passive','EVERY UPGRADE HAS A TIER','Passive upgrades and weapon augments now roll Common through Artifact. Continuous bonuses scale by 1 / 1.2 / 1.5 / 1.8 / 2.2 / 3 by tier. Extra projectiles, piercing targets, bounces and echoes grant 1 / 1 / 1 / 2 / 2 / 3 per rank. Higher-quality copies add more power without spending another buff slot.'),
 ('haste','passive','READ YOUR POWER','Upgrade cards are now inset stone slabs with carved borders, integrated Take and Banish actions, and richer glow for higher tiers. Cards retain weapon tags, show the weapons they affect and describe the actual rolled bonus. Daily rewards show the same tiered bonuses in their reel.'),
 ('prism','relic','LUCK REACHES ARTIFACT','Luck now lowers the chance of Common and increases every higher tier, including Uncommon and Artifact. Artifact remains the rarest tier. Chest odds continue to show your current Luck and bad-luck protection; level-up rewards use Luck without consuming chest protection.'),
]
original_render=notes.render
def render(data):
 # Reuse the tested artwork layout with updated headline and icon categories.
 source=notes.Path(notes.__file__).read_text(encoding='utf-8-sig')
 source=source.replace("'FORTUNE'","'STONE'").replace("'AND FANG'","'AND THUNDER'").replace('0.11.0  /  HOLLOW HARVEST CONTINUES','0.11.1  /  HOLLOW HARVEST CONTINUES').replace('One lucky find. A whole new build.','Heavy impacts. Rarer power. Tougher bosses.')
 source=source.replace("else 'relics-'","else 'weapons-' if entry['category']=='weapon' else 'upgrades-' if entry['category']=='passive' else 'relics-'")
 namespace={'__file__':notes.__file__,'__name__':'release_renderer'}
 exec(source,namespace)
 namespace['VERSION']=notes.VERSION
 namespace['render'](data)
notes.render=render
notes.prepare()
for name in ['project.godot','export_presets.cfg','scripts/daily_challenge.gd','scripts/expedition.gd']:
 p=notes.NATIVE/name
 p.write_text(p.read_text(encoding='utf-8-sig').replace('0.11.0','0.11.1'),encoding='utf-8')
