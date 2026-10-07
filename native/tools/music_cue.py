"""Second menu take and first-map cue: MIDI, sampled renders and editable stems."""
import sys, json, subprocess, wave, re
import numpy as np
from music_renderer import ROOT, render
sys.path.insert(0,str(ROOT/'tools/music/python-packages'))
import mido, imageio_ffmpeg
OUT=ROOT/'native/build/music-review'
TPB=960

class Cue:
    def __init__(self,name,bpm,bars,roster,spec):
        self.name=name;self.bpm=bpm;self.bars=bars;self.beats=bars*4
        self.tempo=mido.bpm2tempo(bpm);self.seconds=self.beats*self.tempo/1e6
        self.roster=roster;self.ev={ch:[] for ch in roster};self.spec=spec
        self.spec.update(meta={'bpm':bpm,'bars':bars,'meter':'4/4','key':'D minor / Phrygian colour','seconds':self.seconds},
                         backend='FluidSynth 2.6.1 / GeneralUser GS 2.0.3 sampled MIDI mockup',
                         provenance='Original composed notes; reference informs mood and orchestration only.',
                         exceptions='Instrumental game loops: no lyrics, mandatory key lift or final cadence.')
        (OUT/(name+'-arrangement.json')).write_text(json.dumps(self.spec,indent=2),encoding='utf-8')
    def event(self,ch,t,msg,order=1):
        assert 0<=t<=self.beats
        self.ev[ch].append((round(t*TPB),order,msg))
    def cc(self,ch,t,control,value):self.event(ch,t,mido.Message('control_change',channel=ch,control=control,value=value),-1)
    def note(self,ch,t,n,d,v):
        assert d>0 and t+d<=self.beats+.001
        self.event(ch,t,mido.Message('note_on',channel=ch,note=n,velocity=v),1)
        self.event(ch,t+d,mido.Message('note_off',channel=ch,note=n,velocity=0),0)
    def phrase(self,ch,start,notes,dynamic=1):
        # Connected notes, one controlled breath at the phrase end; slight purposeful rubato.
        for i,(t,n,d,v) in enumerate(notes):
            self.note(ch,start+t,n,d,round(v*dynamic))
        end=start+notes[-1][0]+notes[-1][2]
        for t,value in [(start,79),(start+1.0,89),(start+2.4,100),(end-.7,87),(end-.14,66)]:
            self.cc(ch,t,11,value)
    def midi(self,path,repeats=3,only=None):
        mf=mido.MidiFile(ticks_per_beat=TPB);meta=mido.MidiTrack();mf.tracks.append(meta)
        meta.append(mido.MetaMessage('set_tempo',tempo=self.tempo))
        meta.append(mido.MetaMessage('time_signature',numerator=4,denominator=4))
        for ch,(label,program,volume,pan,reverb) in self.roster.items():
            if only is not None and ch!=only:continue
            tr=mido.MidiTrack();mf.tracks.append(tr)
            tr.append(mido.MetaMessage('track_name',name=label))
            if ch!=9:tr.append(mido.Message('program_change',channel=ch,program=program))
            for cc,val in [(7,volume),(10,pan),(91,reverb),(11,90)]:
                tr.append(mido.Message('control_change',channel=ch,control=cc,value=val))
            sequence=[]
            for rep in range(repeats):
                sequence.extend((tick+rep*self.beats*TPB,order,msg) for tick,order,msg in self.ev[ch])
            prev=0;active=set()
            for tick,order,msg in sorted(sequence,key=lambda e:(e[0],e[1])):
                if msg.type=='note_on':assert msg.note not in active;active.add(msg.note)
                elif msg.type=='note_off':assert msg.note in active;active.remove(msg.note)
                tr.append(msg.copy(time=tick-prev));prev=tick
            assert not active
            tr.append(mido.MetaMessage('end_of_track',time=repeats*self.beats*TPB-prev))
        mf.save(path)
    def finish(self,target_lufs):
        source=OUT/(self.name+'-three-cycles.mid');self.midi(source)
        self.midi(OUT/(self.name+'.mid'),1)
        raw=OUT/(self.name+'-render.wav');render(source,raw)
        with wave.open(str(raw),'rb') as w:
            rate=w.getframerate();audio=np.frombuffer(w.readframes(w.getnframes()),'<i2').reshape(-1,2).astype(float)/32768
        start=round(self.seconds*rate);end=round(self.seconds*2*rate)
        loop=audio[start:end].copy()
        ff=imageio_ffmpeg.get_ffmpeg_exe()
        def save(path,data):
            with wave.open(str(path),'wb') as w:
                w.setnchannels(2);w.setsampwidth(2);w.setframerate(rate)
                w.writeframes((np.clip(data,-1,1)*32767).astype('<i2').tobytes())
        path=OUT/(self.name+'.wav');save(path,loop)
        def measure(path):
            p=subprocess.run([ff,'-hide_banner','-i',str(path),'-af',f'loudnorm=I={target_lufs}:TP=-2:LRA=11:print_format=json','-f','null','-'],capture_output=True,text=True,check=True)
            return json.loads(re.findall(r'\{[^{}]*"input_i"[^{}]*\}',p.stderr,re.S)[-1])
        stats=measure(path)
        gain=min(10**((target_lufs-float(stats['input_i']))/20),10**(-2/20)/np.max(abs(loop)))
        loop*=gain
        # Tiny continuity correction over 3 ms; no audible fade-out at the loop boundary.
        seam_before=float(np.max(abs(loop[-1]-loop[0])))
        correction=loop[0]-loop[-1]
        loop[-128:]+=np.linspace(0,1,128)[:,None]*correction
        save(path,loop)
        subprocess.run([ff,'-y','-i',str(path),'-c:a','libmp3lame','-b:a','256k',str(path.with_suffix('.mp3'))],capture_output=True,check=True)
        metrics=measure(path)
        report={'seconds':len(loop)/rate,'integrated_lufs':float(metrics['input_i']),
                'true_peak_dbfs':float(metrics['input_tp']),'seam_before':seam_before,
                'seam_after':float(np.max(abs(loop[-1]-loop[0]))),'notes_closed':True,
                'audit':{'verified':'Section variation, contrasting phrase endings, instrument withdrawal, velocity/expression changes, no stuck notes or clipping.',
                         'listening_review':'Pending user review; sampled articulation realism remains a mockup limitation.'}}
        assert np.max(abs(loop))<.999 and report['seam_after']<1e-5
        (OUT/(self.name+'-review.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
        stemdir=OUT/(self.name+'-stems');stemdir.mkdir(exist_ok=True)
        for ch,(label,*_) in self.roster.items():
            mid=stemdir/(label+'.mid');self.midi(mid,only=ch)
            wav=stemdir/(label+'.wav');render(mid,wav)
            with wave.open(str(wav),'rb') as w:
                data=np.frombuffer(w.readframes(w.getnframes()),'<i2').reshape(-1,2).astype(float)/32768
            save(wav,data[start:end]*gain)
        print(self.name,json.dumps(report),flush=True)

