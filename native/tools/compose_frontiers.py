"""Original 48-bar NES-inspired progressive adventure scores. No sampled melodies.
Two pulse leads, triangle-like bass, rapid arpeggios and tuned/noise percussion.
Map motif plus biome-specific key, harmony, orchestration and rhythmic variation.
"""
from pathlib import Path
import numpy as np
import wave, json
SR=32000
OUT=Path(__file__).resolve().parents[1]/'assets/audio'
rng=np.random.default_rng(73007)
CACHE={}
def tone(midi,duration,voice,duty=.25):
    key=(midi,round(duration,5),voice,duty)
    if key in CACHE:return CACHE[key]
    t=np.arange(round(duration*SR))/SR
    f=440*2**((midi-69)/12)
    vibrato=np.maximum(0,t-.09)*0.045*np.sin(t*34)
    phase=2*np.pi*f*t+vibrato
    if voice=='bass':
        sig=sum(((-1)**((k-1)//2))*np.sin(phase*k)/k**2 for k in [1,3,5,7])*.9
    elif voice=='bell':
        sig=np.sin(phase)+.30*np.sin(phase*2)*np.exp(-t*15)+.12*np.sin(phase*3.01)*np.exp(-t*25)
    else:
        # Band-limited pulse harmonics, variable duty for expressive NES-like color.
        sig=sum(np.sin(np.pi*k*duty)*np.cos(phase*k-np.pi*k*duty)/k for k in range(1,min(17,int(SR*.45/f))))*.7
    env=np.minimum(t/.003,1)*np.minimum(np.maximum(duration-t,0)/.018,1)
    env*=np.exp(-t*(7 if voice=='arp' else 3 if voice=='bell' else .6))
    result=sig*env
    CACHE[key]=result
    return result
def drum(kind):
    key=('drum',kind)
    if key in CACHE:return CACHE[key]
    dur={'kick':.22,'snare':.16,'hat':.045,'tom':.23,'crash':.5}[kind]
    t=np.arange(int(dur*SR))/SR
    noise=rng.normal(0,.35,len(t));high=np.diff(noise,prepend=0)
    if kind=='kick':sig=np.sin(2*np.pi*(45*t+3*(1-np.exp(-t*35))))*np.exp(-t*22)
    elif kind=='snare':sig=(high*.6+np.sin(t*2*np.pi*180)*.18)*np.exp(-t*25)
    elif kind=='tom':sig=np.sin(2*np.pi*(85*t+2*(1-np.exp(-t*20))))*np.exp(-t*19)
    else:sig=high*np.exp(-t*(85 if kind=='hat' else 9))*.55
    CACHE[key]=sig;return sig
# Original scale-degree phrases: each map has its own melodic contour.
MOTIFS=[
 [0,2,4,7,6,4,2,1,0,4,3,2,6,4,1,0],
 [7,4,2,3,4,6,7,9,7,6,4,2,3,1,2,0],
 [0,4,1,5,2,6,4,7,6,3,5,2,4,1,3,0]]
NAMES=[['Canopy Overture','Cinder Counterpoint','The Last Procession'],['Ivory Aurora','Glassbound Fugue','Winter at the Edge of Time'],['The Drowned Clock','Brass Meridian','Unmaking the Heavens']]
manifest=[]
for map_index in range(3):
 for biome in range(3):
    bpm=144+map_index*5+biome*12
    beat=60/bpm
    # A/B/breakdown/development/recapitulation/coda; 48 bars, no short repeated loop.
    length=round(SR*beat*192);mix=np.zeros((length,2),dtype=np.float64)
    root=[50,47,48][map_index]+[0,2,-2][biome]
    scale=[0,2,3,5,7,8,11] if map_index!=1 else [0,2,3,5,7,9,10]
    progression=[[0,5,3,4,0,2,5,4],[0,3,5,4,2,5,1,4],[0,2,5,1,3,5,4,4]][map_index]
    def degree(d): return root+scale[d%7]+12*(d//7)
    def place(sig,when,gain,pan=0,echo=False):
        channels=np.sqrt(np.array([1-pan,1+pan])/2)
        for delay,amp in ([(0,1),(beat*.75,.17)] if echo else [(0,1)]):
            at=round((when+delay)*SR)%length
            data=sig[:,None]*channels*gain*amp;n=min(len(data),length-at)
            mix[at:at+n]+=data[:n]
            if n<len(data):mix[:len(data)-n]+=data[n:]
    for bar in range(48):
        section=bar//8; chord=progression[bar%8];at=bar*4*beat
        breakdown=section==2
        for step in range(16):
            when=at+step*beat/4
            if step%2==0:
                place(tone(degree(chord)-12+(12 if step in [6,14] else 0),beat*.42,'bass'),when,.45)
            if not breakdown or step%4==0:
                arp=degree(chord+[0,2,4,6,4,2,0,4][step%8])+12
                place(tone(arp,beat*.23,'arp',.125 if biome==2 else .25),when,.12,(-1 if step%2 else 1)*.45)
            if not breakdown:
                if step in ([0,6,8,11] if biome<2 else [0,3,6,8,10,14]):place(drum('kick'),when,.48)
                if step in [4,12]:place(drum('snare'),when,.42)
                if step%2==0 or biome==2:place(drum('hat'),when,.15 if step%4 else .23,.18)
        for step in range(8):
            motif=MOTIFS[map_index]
            idx=(step+(bar%2)*8)%16
            degree_value=motif[idx]+(2 if section in [1,3] else 0)
            if section==3 and bar%2:degree_value=7-degree_value
            pitch=degree(degree_value)+12+(12 if section==4 and step in [3,7] else 0)
            sustain=beat*(.85 if step in [0,7] else .39)
            if not breakdown or step%2==0:
                place(tone(pitch,sustain,'bell' if breakdown else 'lead',.125 if section==1 else .25),at+step*beat/2,.24 if not breakdown else .20,-.10,True)
            if section in [1,3,4,5] and step in [1,3,5,7]:
                counter=degree(chord+[4,2,6,4][step//2])+12
                place(tone(counter,beat*.65,'lead',.5),at+step*beat/2,.13,.35)
        if bar%8==7:
            for step in range(12,16):place(drum('tom' if step<14 else 'snare'),at+step*beat/4,.28,(step-13.5)*.3)
        if bar%8==0:place(drum('crash'),at,.24,.15)
    mix=np.tanh(mix*1.15);mix*=.86/max(.001,np.max(np.abs(mix)))
    filename=f'frontier_{map_index}_{biome}.wav'
    with wave.open(str(OUT/filename),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes((mix*32767).astype('<i2').tobytes())
    manifest.append({'file':filename,'title':NAMES[map_index][biome],'bpm':bpm,'seconds':round(length/SR,2),'peak':float(np.max(np.abs(mix))),'rms':float(np.sqrt(np.mean(mix**2)))})
    print(filename,NAMES[map_index][biome],round(length/SR,2),flush=True)
# Four short original signatures using the same synthesis primitives.
for id,midi,voice in [('harpoon',42,'bass'),('lantern',67,'bell'),('glacier',88,'bell'),('sunbow',76,'lead')]:
    sig=tone(midi,.28,voice)+.35*tone(midi+7,.28,'arp')
    if id=='harpoon':sig+=np.pad(drum('snare'),(0,max(0,len(sig)-len(drum('snare')))))[:len(sig)]*.4
    sig*=.7/max(.001,np.max(np.abs(sig)))
    with wave.open(str(OUT/(id+'.wav')),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(SR);f.writeframes((sig*32767).astype('<i2').tobytes())
(OUT/'frontiers-score.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
