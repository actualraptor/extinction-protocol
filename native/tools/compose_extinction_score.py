"""Original 210-second linear Extinction Engine score; no loop or victory assumption."""
from music_cue import Cue,OUT,render
import json, subprocess, wave, re
import numpy as np
import imageio_ffmpeg

NAME='Extinction-Protocol-The-Last-Light-Meteor-Score-v1'
cue=Cue(NAME,120,105,
    {0:('horns',60,94,63,35),1:('cellos',42,90,47,29),2:('tremolo-strings',44,77,78,35),
     3:('double-basses',43,101,62,20),4:('trumpets',56,78,73,32),5:('violins',40,79,42,36),
     6:('choir',52,67,68,41),7:('timpani',47,104,56,27),8:('harp',46,68,79,25),
     9:('orchestral-percussion',0,108,62,26),10:('string-ostinato',48,78,57,25)},
    {'title':'The Last Light','intent':'A full orchestral extinction countdown, enormous but melodic. Single linear dramatic arc, never looping.',
     'encounter':'Extinction Engine','duration_seconds':210,'loop':False,
     'material':{'motif':'D F A Bb A G E D','stated_in':'The shadow','character':'An ancient rising call that returns under increasing pressure'},
     'form':[{'seconds':[0,30],'development':'augment','purpose':'The shadow; low horns and measured tread'},
             {'seconds':[30,60],'development':'extend','purpose':'Orchestral motion opens beneath the theme'},
             {'seconds':[60,90],'development':'vary','purpose':'Brass confrontation and choral arrival'},
             {'seconds':[90,120],'development':'fragment','purpose':'A darker pullback with pulse intact'},
             {'seconds':[120,150],'development':'sequence','purpose':'Rebuild and rising strings'},
             {'seconds':[150,180],'development':'recap','purpose':'Final-minute warning; full theme, choir and percussion'},
             {'seconds':[180,195],'development':'contract','purpose':'Compressed gestures and accelerating subdivisions'},
             {'seconds':[195,210],'development':'fragment','purpose':'Final desperate pressure; unresolved cutoff at extinction'}],
     'harmony':'D minor with Phrygian bII, borrowed minor colours, changing bass and a chromatic approach to the final dominant.',
     'harmony_letters':'Dm Bb Gm Eb Am / Bb F Cm Gm / Gm Eb Dm Am / Dm C Bb Eb A',
     'energy_curve':[.4,.58,.76,.43,.68,.91,.93,1],
     'subtraction_events':'90 seconds: withdraw horns, trumpet and choir; cello/harp foreground. Rebuild at 120.',
     'mix_intent':'Separated strings, brass, choir and percussion with orchestral dynamic space; strong bass without wind/noise bed or audible performer breathing.',
     'timing_contract':{'source':'expedition.gd update_boss: boss_time reaches 210, warning at 150',
                        'clock':'Use simulation boss_time, not wall time. Pause music whenever combat simulation pauses.',
                        'health_phases':'Health thresholds at 67/34 percent are not fixed musical time markers.',
                        'early_victory':'Fade score immediately into victory cue; never play the defeat cutoff on an early win.',
                        'defeat':'Stop score at timeout/earlier death and hand off to the existing defeat cinematic.',
                        'preview_status':'Audio draft for review; encounter playback integration follows approval.'}})

dm=(38,53,57);bb=(34,53,58);gm=(43,55,58);eb=(39,55,58);am=(33,52,57);fm=(41,53,57);cm=(36,51,55)
patterns=[[dm,dm,bb,gm,dm,eb,am,am], [dm,bb,gm,am,bb,fm,eb,am],
          [dm,bb,cm,gm,bb,gm,eb,am], [gm,eb,dm,am,gm,cm,eb,am],
          [dm,bb,fm,gm,eb,gm,dm,am], [dm,bb,gm,eb,dm,cm,eb,am],
          [dm,eb,bb,am], [dm,cm,bb,eb,am]]
def section(bar):return 0 if bar<15 else 1 if bar<30 else 2 if bar<45 else 3 if bar<60 else 4 if bar<75 else 5 if bar<90 else 6 if bar<98 else 7
def harmony(bar):
    sec=section(bar);base=[0,15,30,45,60,75,90,98][sec]
    return patterns[sec][(bar-base)%len(patterns[sec])]
main=[(0,62,1.9,79),(2,65,.9,74),(3,69,2.9,85),(6,70,1.9,82),
      (8,69,1.9,80),(10,67,1.9,76),(12,64,1.9,72),(14,62,1.6,75)]
answer=[(0,60,1.9,73),(2,62,.9,71),(3,65,2.9,79),(6,67,1.9,78),
        (8,65,1.9,73),(10,64,1.9,70),(12,60,1.9,68),(14,57,1.6,70)]
for start in range(0,390,16):
    sec=section(start//4);ph=main if (start//16)%2==0 else answer
    if sec==3:ph=[(t,n-12,d,v-17) for t,n,d,v in ph]
    if sec==4:ph=[(t,n+3 if t<8 else n,d,v+2) for t,n,d,v in ph]
    lead=1 if sec in (0,3) else 0
    if start+16<=390:
        cue.phrase(lead,start,ph,.83 if sec==0 else 1)
        if sec in (2,5,6):
            # Violins take a moving independent reply, avoiding constant unison mass.
            countermelody=[(0,77,2.8,64),(3,76,.8,61),(4,74,1.8,65),(6,72,1.8,61),
                          (8,74,2.8,66),(11,76,.8,62),(12,77,1.8,65),(14,76,1.6,60)]
            cue.phrase(5,start,countermelody)
        if sec in (5,6):cue.phrase(4,start+8,[(0,69,1.9,69),(2,70,1.9,73),(4,69,.9,67),(5,67,.9,64),(6,64,1.5,66)])

# Fixed musical accents on the warning and final fifteen-second markers.
for t,n in [(300,38),(390,33)]:
    cue.note(7,t,n,1.5,104)
    cue.note(9,t,49,1.2,73)
for start in range(390,414,8):
    cue.phrase(0,start,[(0,62,.85,88),(1,65,.85,82),(2,69,1.7,91),(4,70,.85,89),(5,69,.85,84),(6,64,1.7,87)])
    cue.phrase(4,start,[(0,74,1.7,75),(2,77,1.7,80),(4,76,1.7,75),(6,73,1.7,77)])
cue.phrase(0,414,[(0,69,1.9,92),(2,70,.9,87),(3,73,2.8,95)])
cue.note(4,416,81,3.8,84)

for bar in range(105):
    t=bar*4;sec=section(bar);root,a,b=harmony(bar)
    intense=sec>=5;quiet=sec in (0,3)
    # Harmonic bed and choir change each bar, with different registers and entrances.
    cue.note(3,t,root,3.85,58 if quiet else 74 if intense else 66)
    if sec not in (0,3):
        for n,v in [(a,43),(b,37)]:cue.note(2,t+.035,n,3.85,v+(8 if intense else 0))
    if sec in (2,5,6,7):
        for n,v in [(a+12,48),(b+12,43)]:cue.note(6,t+.05,n,3.83,v+(8 if intense else 0))
    positions=[0,1.5,3] if quiet else [0,.5,1,1.5,2,2.5,3,3.5]
    if sec>=6:positions=[j*.25 for j in range(16)]
    if sec!=0:
        for j,p in enumerate(positions):
            n=[a,b,a+12,b][j%4]
            cue.note(8 if sec==3 else 10,t+p+.008,n,min(.38,3.94-p),46 if quiet else 59 if intense else 52)
    hits=[(0,41,70),(2.5,45,55)] if quiet else [(0,41,91),(1.5,45,70),(2.5,41,86),(3.25,47,65)]
    if sec>=6:hits=[(0,41,96),(.75,45,75),(1.5,41,88),(2.25,47,77),(3,41,93),(3.5,45,73)]
    for p,n,v in hits:cue.note(9,t+p+.01*(bar%2),n,.13,v)
    if sec not in (0,3):
        for p in [0,2.5]:
            if t+p in (300,390):continue
            cue.note(7,t+p,root+12,.6,72 if intense else 59)
    if sec in (5,6,7):
        for j in range(8):cue.note(9,t+j*.5+.025,42,.09,39 if j%2==0 else 29)
    if bar in (14,29,44,59,74,89,97):
        for p,n,v in [(3,50,61),(3.5,47,68),(3.75,45,73)]:
            if any(abs(p-hit[0])<.16 and n==hit[1] for hit in hits):continue
            cue.note(9,t+p,n,.1,v)

def finish():
    mid=OUT/(NAME+'.mid');cue.midi(mid,repeats=1)
    raw=OUT/(NAME+'-render.wav');render(mid,raw)
    with wave.open(str(raw),'rb') as w:
        rate=w.getframerate();x=np.frombuffer(w.readframes(w.getnframes()),'<i2').reshape(-1,2).astype(float)/32768
    # Runtime score is exactly the simulation's 210 seconds. No tail becomes a second loop.
    x=x[:210*rate]
    ff=imageio_ffmpeg.get_ffmpeg_exe()
    probe=subprocess.run([ff,'-hide_banner','-i',str(raw),'-af','loudnorm=I=-17:TP=-2:LRA=14:print_format=json','-f','null','-'],capture_output=True,text=True,check=True)
    stats=json.loads(re.findall(r'\{[^{}]*"input_i"[^{}]*\}',probe.stderr,re.S)[-1])
    gain=min(10**((-17-float(stats['input_i']))/20),10**(-2/20)/np.max(abs(x)))
    x*=gain
    # A short endpoint fade prevents a cut click; the extinction cinematic owns the impact.
    x[-int(.035*rate):]*=np.linspace(1,0,int(.035*rate))[:,None]
    path=OUT/(NAME+'.wav')
    with wave.open(str(path),'wb') as w:
        w.setnchannels(2);w.setsampwidth(2);w.setframerate(rate);w.writeframes((x*32767).astype('<i2').tobytes())
    subprocess.run([ff,'-y','-i',str(path),'-c:a','libmp3lame','-b:a','256k',str(path.with_suffix('.mp3'))],capture_output=True,check=True)
    stems=OUT/(NAME+'-stems');stems.mkdir(exist_ok=True)
    for ch,(label,*_) in cue.roster.items():cue.midi(stems/(label+'.mid'),repeats=1,only=ch)
    report={'seconds':len(x)/rate,'loop':False,'notes_closed':True,'peak_dbfs':float(20*np.log10(np.max(abs(x)))),
            'cue_markers_seconds':[0,30,60,90,120,150,180,195,210],
            'section_rms_dbfs':[round(float(20*np.log10(np.sqrt(np.mean(x[round(a*rate):round(b*rate)]**2))+1e-12)),2) for a,b in zip([0,30,60,90,120,150,180,195],[30,60,90,120,150,180,195,210])],
            'audit':'Original theme development, distinct entries and withdrawals, independent violin reply, static loudness gain preserves dynamics. Hearing review pending; sampled orchestral mockup.',
            'integration':'Preview only. Use boss_time for playback, pause with simulation, do not loop, early kill/death ends the cue.'}
    assert len(x)==210*rate and np.max(abs(x))<.999
    (OUT/(NAME+'-review.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2),flush=True)

if __name__=='__main__':finish()
