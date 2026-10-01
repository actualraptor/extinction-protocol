"""Repeatable private-release gate. Fixtures use native/build, never tester saves."""
import argparse,subprocess,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
SUITES={
 'saves':('profile_safety.gd',False,90,[]),
 'runs':('private_runs.gd',False,90,[]),
 'daily':('daily_082.gd',False,180,[]),
 'weapons':('run.gd',False,90,['--fast']),
 'ui':('private_ui.gd',True,120,[]),
 'cards':('skin_081.gd',True,120,[]),
 'reels':('daily_reel_087.gd',True,90,[]),
 'soak':('run.gd',False,1200,[]),
}
def run(name,engine):
 script,gui,timeout,args=SUITES[name]
 log=ROOT/'native/build'/('gate-'+name+'.log')
 cmd=[str(engine),'--path',str(ROOT/'native'),'--accessibility','disabled','--script','res://tests/'+script,'--log-file',str(log)]
 if not gui:cmd.append('--headless')
 if args:cmd+=['--']+args
 result=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,errors='replace',timeout=timeout)
 output=result.stdout+result.stderr
 failed=result.returncode!=0 or 'SCRIPT ERROR:' in output or 'FAIL /' in output or ('ERROR:' in output.replace('ERROR: Failed to read the root certificate store.',''))
 print(name+': '+('FAILED' if failed else 'PASS')+' — '+str(log),flush=True)
 if failed:print(output[-5000:])
 return not failed
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--suite',action='append',choices=SUITES);p.add_argument('--engine',type=Path,default=ROOT/'tools/godot/Godot_v4.7.2-stable_win64_console.exe');a=p.parse_args()
 ok=True
 for name in a.suite or ['saves','runs','daily','weapons','ui','cards','reels']:
  try:ok=run(name,a.engine) and ok
  except subprocess.TimeoutExpired:print(name+': FAILED — timed out');ok=False
 sys.exit(0 if ok else 1)
