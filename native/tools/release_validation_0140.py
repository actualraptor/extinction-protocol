"""Run independent simulation/regression checks with bounded processes and private logs."""
from pathlib import Path
import subprocess,concurrent.futures,json,time
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'native/build/release-0.14.0-validation';OUT.mkdir(exist_ok=True)
engine=ROOT/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
tests=['private_runs','profile_safety','archive_respec','archive_respec_ui','dinosaur_roster','dinosaur_bosses',
       'boss_identity','boss_balance','boss_spawn_respite','dinosaur_combat_visuals','compy_flock_visuals',
       'cinematic_gallery','first_rite','first_rite_playback','gallery_playback','remnants','army_contact',
       'army_revision','ritual_cache_layers','ritual_scrap_motion','ritual_submission_profile','ritual_foley',
       'content_profiles','frontiers_07','frontier_routes_07','stage_objects','continuous_terrain',
       'main_menu_motion','official_brand','epic_trailer_intro','soundtrack_loops','discovery_grid_preview',
       'starter_migration','starter_attack','starter_audio_0113','reward_flow','harvest_progression','harvest_bosses']
def run(name):
    started=time.time()
    try:
        logfile=OUT/(name+'.godot.log')
        if logfile.exists():logfile.unlink()
        graphical='RenderingServer.frame_post_draw' in (ROOT/'native/tests'/(name+'.gd')).read_text(encoding='utf-8')
        command=[str(engine),*([] if graphical else ['--headless']),'--path',str(ROOT/'native'),'--script','tests/'+name+'.gd','--log-file',str(logfile),'--','--verify-release','--profile-path=res://build/release-0.14.0-validation/'+name+'-profile.json']
        with (OUT/(name+'.console.log')).open('w',encoding='utf-8') as log:
            p=subprocess.Popen(command,stdout=log,stderr=log,creationflags=subprocess.CREATE_NO_WINDOW)
            limit=300 if name=='boss_balance' else 100
            while p.poll() is None:
                output=logfile.read_text(encoding='utf-8',errors='replace') if logfile.exists() else ''
                if 'SCRIPT ERROR:' in output or time.time()-started>limit:p.kill();break
                time.sleep(.25)
            p.wait()
        output=logfile.read_text(encoding='utf-8',errors='replace') if logfile.exists() else ''
        (OUT/(name+'.log')).write_text(output,encoding='utf-8')
        bad=any(s in output for s in ['SCRIPT ERROR:','Assertion failed','Parse Error','FAIL /','FAIL:'])
        result={'test':name,'pass':p.returncode==0 and not bad,'exit':p.returncode,'seconds':round(time.time()-started,1)}
    except subprocess.TimeoutExpired:
        result={'test':name,'pass':False,'reason':'Timed out after 100 seconds','seconds':100}
    print(json.dumps(result),flush=True);return result
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(run,tests))
(OUT/'results.json').write_text(json.dumps(results,indent=2))
print('TOTAL',len(results),'PASS',sum(r['pass'] for r in results),flush=True)
