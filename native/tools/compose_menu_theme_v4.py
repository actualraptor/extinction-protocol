"""Quiet, circular menu composition, rendered with the project sampled palette."""
from pathlib import Path
import sys, json, wave, subprocess, re
import numpy as np
from music_renderer import render, ROOT
sys.path.insert(0,str(ROOT/'tools/music/python-packages'))
import mido, imageio_ffmpeg

OUT=ROOT/'native/build/music-review'
OUT.mkdir(parents=True,exist_ok=True)
NAME='Extinction-Protocol-Embers-of-the-Cradle-Menu-v1'
BPM=76; BEATS=80; TPB=960; SECONDS=BEATS*60/BPM
spec={
 'title':'Embers of the Cradle','role':'Quiet repeating main-menu theme',
 'intent':{'emotion':'Ancient mystery with a small human warmth','focus':'A memorable, unhurried flute phrase','avoid':'Wind, engine hum, combat intensity, finale','context':'Extinction Protocol menu'},
 'meta':{'bpm':BPM,'meter':'4/4','key':'D minor with occasional Phrygian colour','bars':20,'seconds':SECONDS},
 'material':{'motif':'D5 F5 A5 G5 E5 D5','rhythm_beats':'0:1.25, 1.5:0.5, 2.25:1.25, 4:0.75, 5:0.75, 6:1.25; rests between attacks','character':'Rising curiosity, gentle descending answer','stated_in':'A'},
 'form':[{'id':'A','bars':6,'development':'repeat','harmony':'i / i / VI / iv / i / v','letters':'Dm Dm Bb Gm Dm Am'},
         {'id':'B','bars':4,'development':'vary','harmony':'VI / III / iv / v','letters':'Bb F Gm Am'},
         {'id':'breath','bars':4,'development':'fragment','harmony':'iv / iv / bII / v','letters':'Gm Gm Eb Am'},
         {'id':'return','bars':6,'development':'recap','harmony':'i / VI / iv / i / bII / v','letters':'Dm Bb Gm Dm Eb Am'}],
 'roster':{'pan_flute':'Single foreground voice; rests for breathing','nylon_strings':'Sparse alternating plucks, left of centre','cello':'Quiet changing two-note harmony, behind melody','acoustic_bass':'Short low accents','percussion':'Soft toms and woodblock; absent during breath'},
 'mix_intent':'Flute clearly audible at low playback level, percussion behind it; no drone or noise bed. Moderate width, no huge reverberant wall.',
 'energy_curve':[0.35,0.42,0.22,0.36],
 'render':'MIDI with GeneralUser GS 2.0.3 through FluidSynth 2.6.1; three repeats, middle cycle extracted to retain reverb tails.',
 'exceptions':'No vocals, modulation or dramatic climax: simple background loop requested.'
}
(OUT/(NAME+'-arrangement.json')).write_text(json.dumps(spec,indent=2),encoding='utf-8')
events={i:[] for i in (0,1,2,3,9)}
def note(ch,t,n,d,v):
    assert t>=0 and d>0 and 0<n<128
    events[ch].append((round(t*TPB),1,mido.Message('note_on',channel=ch,note=n,velocity=v)))
    events[ch].append((round((t+d)*TPB),0,mido.Message('note_off',channel=ch,note=n,velocity=0)))

chords=[(38,53,57),(38,53,57),(34,53,58),(43,55,58),(38,53,57),(33,52,57),
        (34,53,58),(41,53,57),(43,55,58),(33,52,57),
        (43,55,58),(43,55,58),(39,55,58),(33,52,57),
        (38,53,57),(34,53,58),(43,55,58),(38,53,57),(39,55,58),(33,52,57)]
motif=[(0,74,1.25,65),(1.5,77,.5,57),(2.25,81,1.25,62),(4,79,.75,60),(5,76,.75,54),(6,74,1.25,57)]
answer=[(0,72,1.25,59),(1.5,74,.5,54),(2.25,77,1.25,61),(4,76,.75,55),(5,72,.75,51),(6,69,1.25,53)]
variation=[(0,77,1.25,62),(1.5,79,.5,56),(2.25,81,1,63),(3.5,79,.35,53),(4,77,.75,57),(5,76,.75,53),(6,74,1.25,56)]
phrases=[(0,motif),(8,answer),(16,motif),(24,variation),(32,answer),
         (40,[(0,79,1.5,49),(2.5,77,1,46),(5,74,1.4,48)]),
         (48,[(0,75,1.25,49),(2,74,1.25,47),(5,72,1.25,45)]),
         (56,motif),(64,variation),(72,[(0,75,1.2,54),(1.5,77,.5,50),(2.25,79,1.1,56),(4,76,1,49),(6,73,1.4,47)])]
for cycle in range(3):
    offset=cycle*BEATS
    for start,phrase in phrases:
        for idx,(t,n,d,v) in enumerate(phrase):note(0,offset+start+t+.008*(idx%3),n,d,v)
    for bar,(root,a,b) in enumerate(chords):
        t=offset+bar*4; quiet=10<=bar<14
        # Plucks make a soft bed without continuously filling the low mids.
        for j,(pos,pitch) in enumerate([(0,a),(1.5,b),(2.75,a+12)]):
            if quiet and j==2:continue
            note(1,t+pos+.009,pitch,.85,41+(bar+j)%5-(5 if quiet else 0))
        note(3,t,root,1.2,47 if not quiet else 37)
        if not quiet:note(3,t+2.5,root+7,.75,38)
        if bar%2==0:
            note(2,t+.04,a-12,6.6,32 if not quiet else 27)
            note(2,t+.065,b-12,6.55,28 if not quiet else 24)
        if quiet:continue
        for pos,pitch,vel in [(0,41,43),(1.75,76,29),(2.5,45,33)]:
            note(9,t+pos+.007*(bar%3),pitch,.16,vel+bar%4)
        if bar in (5,9,17):note(9,t+3.5,50,.13,28)

def make_midi(path,only=None,repeats=3):
    midi=mido.MidiFile(ticks_per_beat=TPB)
    meta=mido.MidiTrack();midi.tracks.append(meta)
    meta.append(mido.MetaMessage('set_tempo',tempo=mido.bpm2tempo(BPM)))
    meta.append(mido.MetaMessage('time_signature',numerator=4,denominator=4))
    for ch in events:
        if only is not None and ch!=only:continue
        tr=mido.MidiTrack();midi.tracks.append(tr)
        tr.append(mido.MetaMessage('track_name',name={0:'Flute',1:'Plucked strings',2:'Cello harmony',3:'Bass',9:'Wood and hide percussion'}[ch]))
        if ch!=9:tr.append(mido.Message('program_change',channel=ch,program={0:75,1:24,2:42,3:32}[ch]))
        for cc,value in [(7,{0:94,1:77,2:61,3:75,9:74}[ch]),(10,{0:65,1:47,2:80,3:64,9:57}[ch]),(91,28 if ch!=9 else 14)]:
            tr.append(mido.Message('control_change',channel=ch,control=cc,value=value))
        prev=0
        for tick,order,msg in sorted(events[ch],key=lambda x:(x[0],x[1])):
            if tick>=BEATS*repeats*TPB:continue
            tr.append(msg.copy(time=tick-prev));prev=tick
        tr.append(mido.MetaMessage('end_of_track',time=max(0,BEATS*repeats*TPB-prev)))
    midi.save(path)
    # Verify note closure independently by reading emitted events.
    for tr in midi.tracks:
        active=set()
        for msg in tr:
            if msg.type=='note_on' and msg.velocity:assert msg.note not in active;active.add(msg.note)
            elif msg.type=='note_off':assert msg.note in active;active.remove(msg.note)
        assert not active

source=OUT/(NAME+'-three-cycles.mid');make_midi(source)
make_midi(OUT/(NAME+'.mid'),repeats=1)
raw=OUT/(NAME+'-render.wav');render(source,raw)
with wave.open(str(raw),'rb') as w:
    rate=w.getframerate();audio=np.frombuffer(w.readframes(w.getnframes()),'<i2').reshape(-1,2).astype(np.float64)/32768
start=round(SECONDS*rate); end=round(2*SECONDS*rate)
loop=audio[start:end]
ff=imageio_ffmpeg.get_ffmpeg_exe()
probe=subprocess.run([ff,'-hide_banner','-i',str(raw),'-af','loudnorm=I=-20:TP=-2:LRA=11:print_format=json','-f','null','-'],capture_output=True,text=True)
stats=json.loads(re.findall(r'\{[^{}]*"input_i"[^{}]*\}',probe.stderr,re.S)[-1])
gain=min(10**((-20-float(stats['input_i']))/20),10**(-2/20)/np.max(abs(loop)))
loop*=gain
def savewav(path,data):
    with wave.open(str(path),'wb') as w:
        w.setnchannels(2);w.setsampwidth(2);w.setframerate(rate);w.writeframes((np.clip(data,-1,1)*32767).astype('<i2').tobytes())
target=OUT/(NAME+'.wav');savewav(target,loop)
subprocess.run([ff,'-y','-i',str(target),'-c:a','libmp3lame','-b:a','256k',str(target.with_suffix('.mp3'))],check=True,capture_output=True)
# Check adjacent rendered cycles before quantization; they must agree at the seam.
third=audio[end:end+len(loop)]*gain
report={'seconds':len(loop)/rate,'peak_dbfs':float(20*np.log10(np.max(abs(loop)))),
        'source_integrated_lufs':stats['input_i'],'static_gain_db':float(20*np.log10(gain)),
        'seam_step':float(np.max(abs(loop[0]-loop[-1]))),
        'cycle_difference_rms':float(np.sqrt(np.mean((loop[:len(third)]-third)**2))),
        'closed_midi_notes':True,'no_clipping':bool(np.max(abs(loop))<1),
        'audit':{'arrangement':'Melody varies; percussion withdraws for four bars; harmony and energy change; no noise bed, vocal or key lift','listening':'User listening review pending; technical metrics do not establish musical quality'},
        'provenance':spec['render']}
assert report['no_clipping'] and report['seam_step']<.04
(OUT/(NAME+'-review.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
for ch,label in [(0,'flute'),(1,'plucks'),(2,'cello'),(3,'bass'),(9,'percussion')]:
    make_midi(OUT/(NAME+'-'+label+'.mid'),only=ch)
print(json.dumps(report,indent=2))
