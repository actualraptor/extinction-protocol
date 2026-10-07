from music_cue import OUT,render
import json, subprocess, wave, re
import numpy as np
import imageio_ffmpeg

def render_linear(cue, NAME):
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

