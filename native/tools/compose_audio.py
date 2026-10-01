"""Original, deterministic chiptune score and layered weapon PCM sound design."""
from pathlib import Path
import wave
import numpy as np
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
OUT.mkdir(exist_ok=True)
SR = 32000
rng = np.random.default_rng(42031)

def save(name, data):
    if data.ndim == 1: data = np.stack([data,data],axis=1)
    peak = np.max(np.abs(data))
    if peak > .92: data *= .92/peak
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes((np.clip(data,-1,1)*32767).astype('<i2').tobytes())

def tone(freq, duration, kind='bell'):
    t = np.arange(int(duration*SR))/SR
    phase = freq*t
    attack = np.minimum(t/.006,1)
    if kind=='bass': signal = (2/np.pi*np.arcsin(np.sin(2*np.pi*phase))+.15*np.sin(4*np.pi*phase))*.65
    elif kind=='lead': signal = sum(np.sin(2*np.pi*phase*k)/k for k in [1,3,5,7])*.6
    elif kind=='pad':
        signal = (np.sin(2*np.pi*phase)+np.sin(2*np.pi*phase*1.003))*.25
        attack = np.minimum(t/.15,1)
    else: signal = np.sin(2*np.pi*phase)*np.exp(-t*4)+.3*np.sin(2*np.pi*phase*2.01)*np.exp(-t*11)
    return signal*attack*np.minimum((duration-t)/.055,1)

def hz(midi): return 440*2**((midi-69)/12)
def drum(kind):
    duration = .26 if kind=='kick' else .16 if kind=='snare' else .08
    t = np.arange(int(duration*SR))/SR
    noise = rng.uniform(-1,1,len(t))
    if kind=='kick': return np.sin(2*np.pi*(48*t+4*(1-np.exp(-t*35))))*np.exp(-t*20)*.8
    if kind=='snare': return (noise*.6+np.sin(2*np.pi*170*t)*.3)*np.exp(-t*23)
    return np.diff(noise,prepend=0)*np.exp(-t*65)*.22

# Against the Falling Sky: original 32-bar D-minor adventure/chiptune loop.
beat = 60/116
length = int(32*4*beat*SR)
base = np.zeros((length,2)); surge = np.zeros_like(base)
def place(track,sound,when,gain,pan=0,echo=False):
    start = int(when*SR)
    channels = np.array([np.sqrt((1-pan)/2),np.sqrt((1+pan)/2)])
    for delay,volume in ([(0,1),(.187,.22),(.374,.09)] if echo else [(0,1)]):
        at = (start+int(delay*SR))%length
        samples = sound[:,None]*channels*gain*volume
        first = min(len(samples),length-at)
        track[at:at+first] += samples[:first]
        if first<len(samples): track[:len(samples)-first] += samples[first:]
chords = [(50,53,57),(46,50,53),(53,57,60),(48,52,55)]
motifs = [[74,77,81,79,77,74,72,69],[70,74,77,81,79,77,74,72],[77,81,84,81,79,77,76,72],[72,76,79,77,76,72,69,73]]
for bar in range(32):
    chord = chords[bar%4]; at = bar*4*beat
    for k,n in enumerate(chord): place(base,tone(hz(n+12),4*beat,'pad'),at,.085,(k-1)*.65)
    for step in range(8):
        note = chord[0]-12+(12 if step in [3,7] else 0)
        place(base,tone(hz(note),beat*.43,'bass'),at+step*beat*.5,.23)
        place(base,tone(hz(chord[step%3]+24),.24),at+step*beat*.5,.07,(-1 if step%2 else 1)*.45,True)
        if bar%8>=2:
            melody = motifs[bar%4][step]+(12 if bar>=24 else 0)
            place(base,tone(hz(melody),beat*(.8 if step in [0,4] else .4),'lead'),at+step*beat*.5,.13,.12,True)
        place(surge,drum('hat'),at+step*beat*.5,.22,(-1 if step%2 else 1)*.35)
        place(surge,tone(hz(chord[step%3]),beat*.2,'lead'),at+step*beat*.5,.08,-.2)
    for step in range(4):
        place(base,drum('kick'),at+step*beat,.27 if step%2==0 else .1)
        if step%2: place(base,drum('snare'),at+step*beat,.17,-.1)
        place(surge,drum('kick' if step%2==0 else 'snare'),at+step*beat,.33)
    if bar%8==7:
        for k in range(4): place(surge,drum('snare'),at+(3+k*.25)*beat,.12+k*.025,k*.15-.2)
save('music_cradle',base); save('music_extinction_layer',surge)

def effect(name,duration=.65):
    t = np.arange(int(duration*SR))/SR
    n = rng.uniform(-1,1,len(t)); low = np.convolve(n,np.ones(17)/17,mode='same'); high = n-low
    env = np.minimum(t/.002,1)*np.minimum((duration-t)/.035,1)
    signal = np.zeros_like(t)
    if name in ('frost','impact_frost','winter'):
        # Brittle ice fracture, an airy rush, then an inharmonic glass shimmer.
        signal = high*np.exp(-t*100)*.85
        for k,f in enumerate([1267,2113,3191,4729,6371]):
            signal += np.sin(2*np.pi*f*t+.35*np.sin(t*41))*np.exp(-t*(10+k*3))*.12
        signal += low*np.exp(-((t-.065)/.045)**2)*1.3
        signal += np.sin(2*np.pi*(120*t+1.5*(1-np.exp(-t*45))))*np.exp(-t*35)*.32
        for at in [.028,.061,.096]: signal += high*np.exp(-((t-at)/.003)**2)*(.5 if name=='impact_frost' else .22)
    elif name in ('revolver','shotgun','impact_metal'):
        signal = n*np.exp(-t*(55 if name=='revolver' else 28))*.8
        signal += np.sin(2*np.pi*(90*t+2*(1-np.exp(-t*30))))*np.exp(-t*20)*.6
        signal += np.sin(2*np.pi*1830*t)*np.exp(-t*50)*.1
    elif name in ('fire','pyre','impact_fire','mortar','nuke','thermal'):
        signal = low*np.exp(-t*4)*2.2+high*np.exp(-t*13)*.32
        signal += np.sin(2*np.pi*(46*t+2*(1-np.exp(-t*22))))*np.exp(-t*8)*.6
        if name=='thermal': signal += np.sin(2*np.pi*1600*t)*np.exp(-t*9)*.22
    elif name in ('lightning','chain_tick','thunderstorm','thunder_hit'):
        # Dry electrical snap with separate arc crackles and low thunder body.
        signal = high*np.exp(-t*120)*1.05
        signal += np.sin(2*np.pi*(1700*t+19*(1-np.exp(-t*45))))*np.exp(-t*32)*.2
        for at in [.024,.051,.088,.135]: signal += high*np.exp(-((t-at)/.004)**2)*.42*np.exp(-at*5)
        signal += np.sin(2*np.pi*(66*t+1.8*(1-np.exp(-t*25))))*np.exp(-t*18)*.48
        if name.startswith('thunder'):
            signal += low*np.exp(-t*5)*2.4+np.sin(2*np.pi*43*t)*np.exp(-t*7)*.35
        if name=='chain_tick': signal *= np.exp(-t*16)*.6
    elif name=='venom_spit':
        signal = low*np.exp(-t*14)*2+np.sin(2*np.pi*(270*t+5*(1-np.exp(-t*24))))*np.exp(-t*23)*.3
    elif name in ('club','spear','hit','boss'):
        signal = low*np.exp(-((t-.055)/.035)**2)*2.5+n*np.exp(-t*40)*.18+np.sin(2*np.pi*74*t)*np.exp(-t*15)*.55
    elif name in ('orbital','dread','aegis','stasis','miasma'):
        root = {'orbital':370,'dread':92,'aegis':620,'stasis':220,'miasma':145}[name]
        for ratio in [1,1.5,2.01]: signal += np.sin(2*np.pi*root*ratio*t+np.sin(t*13)*2)*np.exp(-t*5)*.2
        signal += low*np.sin(t*40)**2*np.exp(-t*5)*.4
    elif name=='reel_tick': signal = high*np.exp(-t*100)*.3+np.sin(2*np.pi*900*t)*np.exp(-t*80)*.3
    else:
        rank = int(name[-1]) if name.startswith('rarity_') else 2
        for k,note in enumerate([62,65,69,74,77,81][:min(6,rank+2)]):
            offset = int(k*.09*SR); sound = tone(hz(note),max(.05,duration-k*.09))*.22
            signal[offset:offset+min(len(sound),len(signal)-offset)] += sound[:len(signal)-offset]
    signal *= env
    stereo = np.stack([signal,signal],axis=1)
    reflections = [(.023,.08),(.061,.04)] if name in ('frost','impact_frost','lightning','chain_tick','revolver','shotgun') else [(.047,.16),(.113,.09),(.193,.04)]
    for delay,gain in reflections:
        for channel,extra in [(0,0),(1,31)]:
            shift = int(delay*SR)+extra
            if shift<len(signal): stereo[shift:,channel] += signal[:-shift]*gain
    # Soft saturation keeps the attack present without hard clipping.
    save(name,np.tanh(stereo*1.15)*.85)
names = 'revolver shotgun frost fire lightning club spear orbital mortar pyre winter miasma dread aegis stasis impact_frost impact_fire impact_metal thermal reel_tick hit kill level evolve boss loot freeze magnet nuke frenzy'.split()
for name in names: effect(name,1.2 if name in ['mortar','nuke','boss','evolve','level'] else .55)
for name,duration in [('chain_tick',.2),('thunderstorm',.8),('thunder_hit',.65),('venom_spit',.3)]: effect(name,duration)
for rank in range(6): effect('rarity_'+str(rank),.75+rank*.22)
print('Rendered',len(names)+8,'original stereo assets; music loop',round(length/SR,2),'seconds.')
