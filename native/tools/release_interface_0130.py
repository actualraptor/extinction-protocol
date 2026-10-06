"""Prepare 0.13.0 metadata and spoiler-free public notes. Does not publish."""
from pathlib import Path
import json, re

ROOT = Path(__file__).resolve().parents[2]
NATIVE = ROOT / 'native'
VERSION = '0.13.0'
TITLE = 'Hollow Harvest: Fieldwork'
ENTRIES = [
    dict(icon='map', category='relic', title='A NEW HUD — FIRST ITERATION', body='The bottom HUD has a new illustrated layout, character-themed frames, portraits, health and experience displays, and integrated backpack, amber and re-roll panels. This is the first iteration: expect layout, scaling and visual issues while we refine it. The experience bar still needs further polish.'),
    dict(icon='compass', category='weapon', title='READ THE FIELD', body='The minimap shows a wider view of explored ground. Both maps show terrain, locations, chests and pickups, including magnets, so useful supplies are easier to find. Carried items use pages when the HUD runs out of room; your backpack still holds them.'),
    dict(icon='tablet', category='weapon', title='CLEARER UPGRADE CHOICES', body='Upgrade cards, Take buttons and re-roll controls have a new art pass. Reward previews and evolution reveals show more useful information about the upgrade you are choosing.'),
    dict(icon='club', category='weapon', title='ENCOUNTER AND PRESENTATION POLISH', body='Boss names and health-bar frames better match each encounter. Large enemies can move through crowds more reliably, and charging allies can no longer shove the meteor. Animation, transitions and effects have received another polish pass.'),
    dict(icon='clock', category='relic', title='CONTROL YOUR SOUND', body='Settings now includes separate volume controls for effects, music, voices and cinematics. Existing progression is retained when you update.'),
]

def prepare():
    notes = NATIVE / 'scripts/patch_notes.gd'
    old = notes.read_text(encoding='utf-8-sig')
    history_path = NATIVE / 'assets/patch-history.json'
    history = json.loads(history_path.read_text(encoding='utf-8-sig'))
    previous = re.search(r'const VERSION="([^"]+)"', old).group(1)
    if previous != VERSION and not any(r['version'] == previous for r in history):
        prior_entries = json.loads(re.search(r'const ENTRIES=(\[.*?\])\s*static func', old, re.S).group(1))
        history.insert(0, dict(version=previous, title=re.search(r'const TITLE="([^"]+)"', old).group(1), entries=prior_entries))
    history_path.write_text(json.dumps(history, ensure_ascii=False, indent=2), encoding='utf-8')
    notes.write_text('extends RefCounted\n## Player-facing changes only; unrevealed content stays out of public notes.\nconst VERSION="'+VERSION+'"\nconst TITLE="'+TITLE+'"\nconst ENTRIES='+json.dumps(ENTRIES, ensure_ascii=False, indent=1)+'\nstatic func releases():\n\tvar all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]\n\tall.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))\n\treturn all\n', encoding='utf-8')
    markdown = '# Extinction Protocol '+VERSION+' — '+TITLE+'\n\n'+'\n\n'.join('## '+entry['title']+'\n\n'+entry['body'] for entry in ENTRIES)+'\n\nWindows x64 has been tested. Linux x64 is available as an unverified test build.\n'
    (NATIVE / ('RELEASE-'+VERSION+'.md')).write_text(markdown, encoding='utf-8')
    for name in ['project.godot', 'export_presets.cfg', 'scripts/daily_challenge.gd', 'scripts/expedition.gd']:
        p = NATIVE / name
        p.write_text(p.read_text(encoding='utf-8-sig').replace('0.12.0', VERSION), encoding='utf-8')
    preset = NATIVE / 'export_presets.cfg'
    p = preset.read_text(encoding='utf-8')
    p = p.replace('include_filter="assets/hud-modular/*.json,assets/blocks/*.bin,assets/*.json"', 'include_filter="assets/hud-modular/*.json,assets/blocks/*.bin,assets/*.json,assets/kael-slam-0111/frames.json,assets/hero-attacks-0111/frames.json,assets/voices/manifest.json"')
    preset.write_text(p, encoding='utf-8')
    print('Prepared 0.13.0 metadata and spoiler-free notes')

if __name__ == '__main__': prepare()
