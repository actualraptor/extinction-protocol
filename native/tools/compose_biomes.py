"""Original loopable 32-bar combat cues. Deterministic synthesis; no samples."""
from pathlib import Path
import wave
import numpy as np
SR = 32000
OUT = Path(__file__).resolve().parents[1] / 'assets/audio'
rng = np.random.default_rng(61036)

def note(midi,duration,voice):
    t = np.arange(int(duration*SR))/SR
    f = 440*2**((midi-69)/12)
    phase = 2*np.pi*f*t
    if voice=='bass':
        sig = np.sin(phase)+.26*np.sin(phase*2)+.13*np.sin(phase*3)
        env = np.exp(-t*4)*np.minimum(t/.004,1)
    elif voice=='pluck':
        sig = sum(np.sin(phase*k)/k for k in [1,2,3,4,6])*.45
        env = np.exp(-t*7)*np.minimum(t/.003,1)
    elif voice=='lead':
        sig = sum(np.sin(phase*k+np.sin(t*35)*.025)/k for k in [1,3,5,7])*.58
        env = np.minimum(t/.012,1)*(.75+.25*np.exp(-t*12))
    else:
        sig = np.sin(phase)*.5+np.sin(phase*1.003)*.25+np.sin(phase*2)*.12
        env = np.minimum(t/.07,1)*np.exp(-t*.55)
    return sig*env*np.minimum((duration-t)/.035,1)

def drum(kind):
    duration = {'kick':.32,'snare':.20,'hat':.07,'tom':.28,'crash':.8}[kind]
    t = np.arange(int(SR*duration))/SR
    noise = rng.normal(0,.4,len(t))
    if kind=='kick': return (np.sin(2*np.pi*(48*t+2.7*(1-np.exp(-t*45))))*np.exp(-t*15)+noise*np.exp(-t*150)*.18)
    if kind=='snare': return (noise*.8+np.sin(t*2*np.pi*185)*.23)*np.exp(-t*20)
    if kind=='tom': return np.sin(2*np.pi*(95*t+2*(1-np.exp(-t*25))))*np.exp(-t*14)
    high = np.diff(noise,prepend=0)
    return high*np.exp(-t*(65 if kind=='hat' else 5))*.4

TRACKS = [
    ('combat_0',140,[(50,53,57),(46,50,53),(53,57,60),(48,52,55)],
     [[74,77,81,77,79,77,74,72],[70,74,77,79,77,74,72,69],[77,81,84,81,79,77,74,77],[72,76,79,81,79,76,73,69]]),
    ('combat_1',152,[(45,48,52),(41,45,48),(43,47,50),(40,44,47)],
     [[69,72,76,75,76,72,69,67],[65,69,72,76,74,72,69,68],[67,71,74,77,74,71,69,67],[64,68,71,76,74,71,68,64]]),
    ('combat_2',164,[(48,51,55),(44,48,51),(41,44,48),(43,47,50)],
     [[72,79,75,79,84,82,79,75],[68,75,72,75,80,79,75,72],[65,72,68,72,77,75,72,68],[67,74,71,74,79,77,74,71]])]
for name,bpm,chords,motifs in TRACKS:
    beat = 60/bpm
    length = round(SR*beat*128)
    track = np.zeros((length,2))
    def place(sound,when,gain,pan=0,echo=False):
        channels = np.sqrt(np.array([1-pan,1+pan])/2)
        for delay,amp in ([(0,1),(beat*.75,.20),(beat*1.5,.075)] if echo else [(0,1)]):
            at = int((when+delay)*SR)%length
            data = sound[:,None]*channels*gain*amp
            n = min(len(data),length-at)
            track[at:at+n] += data[:n]
            if n<len(data): track[:len(data)-n] += data[n:]
    for bar in range(32):
        phrase = bar//8
        chord = chords[(bar//2)%4]
        motif = motifs[(bar//2)%4]
        at = bar*4*beat
        for step in range(16):
            when = at+step*beat/4
            if step%2==0 or (phrase>=2 and step in [7,15]):
                bass = chord[0]-12+(12 if step in [6,14] else 0)
                place(note(bass,beat*.36,'bass'),when,.48)
            place(drum('hat'),when,.11 if step%2 else .22,(-1 if step%2 else 1)*.3)
            if step in [0,6,8,11] or (name=='combat_2' and step in [3,14]): place(drum('kick'),when,.60)
            if step in [4,12]: place(drum('snare'),when,.60,-.06)
            if step%2==1:
                place(note(chord[(step//2)%3]+12,beat*.23,'pluck'),when,.13,.5 if bar%2 else -.5,True)
        # A memorable eight-note hook with call/response and an octave lift.
        for step,n in enumerate(motif):
            if phrase==1 and step in [1,5]: continue
            n += 12 if phrase==3 and step in [2,4,6] else 0
            duration = beat*(.7 if step in [0,4,7] else .38)
            place(note(n,duration,'lead'),at+step*beat/2,.25 if phrase!=1 else .18,.1,True)
        if bar%2==0:
            for j,n in enumerate(chord): place(note(n+12,beat*3.8,'pad'),at,.12,(j-1)*.6)
        if bar%8==0: place(drum('crash'),at,.24,.3)
        if bar%8==7:
            for step in [12,13,14,15]: place(drum('tom' if step<14 else 'snare'),at+step*beat/4,.32,(step-13.5)*.25)
    # Gentle saturation controls coincident transients, keeping drums punchy.
    track = np.tanh(track*1.2)
    track *= .89/max(np.max(np.abs(track)),.01)
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes((track*32767).astype('<i2').tobytes())
    print(name,bpm,round(length/SR,2),'seconds', 'RMS',round(float(np.sqrt(np.mean(track**2))),3))
