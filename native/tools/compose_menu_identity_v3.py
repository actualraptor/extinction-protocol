"""Private original menu sketch: organic modal timbres, no chiptune oscillators.
All instruments are synthesized locally. This is an audition, not a game replacement.
"""
from pathlib import Path
import json
import wave
import subprocess
import numpy as np
import imageio_ffmpeg

SR = 44100
BPM = 84
BEAT = 60 / BPM
DURATION = 96 * BEAT
N = round(DURATION * SR)
OUT = Path(__file__).resolve().parents[1] / 'build/music-review'
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(710064)
stems = {name: np.zeros((N, 2), dtype=np.float64) for name in ['atmosphere', 'percussion', 'motif', 'bass']}

def filtered_noise(length, low, high):
    noise = rng.normal(0, 1, length)
    spectrum = np.fft.rfft(noise)
    hz = np.fft.rfftfreq(length, 1/SR)
    weight = (1-np.exp(-(hz/max(1,low))**4)) * np.exp(-(hz/high)**4)
    result = np.fft.irfft(spectrum*weight, n=length)
    return result / max(.01, float(np.std(result)))

def place(stem, signal, beat, gain, pan=0):
    index = (round(beat*BEAT*SR)+np.arange(len(signal))) % N
    channels = np.sqrt(np.array([1-pan, 1+pan])/2)
    for channel in range(2):
        np.add.at(stems[stem][:, channel], index, signal*gain*channels[channel])

def drum(kind, variation=0):
    duration = {'hide':1.3, 'tom':1.1, 'wood':.3, 'rattle':.55}[kind]
    t = np.arange(round(SR*duration))/SR
    if kind in ['hide', 'tom']:
        fundamental = (79 if kind=='hide' else 138)*(1+variation*.035)
        sig = sum(np.sin(2*np.pi*fundamental*ratio*t + .8*(1-np.exp(-t*25))) * gain * np.exp(-t*decay)
                  for ratio, gain, decay in [(1,1,5.0),(1.59,.42,7.0),(2.14,.24,10.0),(2.65,.13,14.0)])
        sig += filtered_noise(len(t), 100, 1800)*np.exp(-t*45)*.25
    elif kind=='wood':
        sig = sum(np.sin(2*np.pi*hz*t)*np.exp(-t*decay)*gain for hz,decay,gain in [(840,32,.5),(1243,42,.3),(1920,60,.12)])
        sig += filtered_noise(len(t), 500, 3500)*np.exp(-t*95)*.08
    else:
        sig = filtered_noise(len(t), 1800, 6500)*np.exp(-t*8)*(.35+.65*np.sin(t*2*np.pi*21)**8)*.2
    return sig*np.minimum(1,t/.0015)*np.minimum(1,(duration-t)/.02)

def voice(midi, duration, kind):
    t = np.arange(round(SR*duration))/SR
    f = 440*2**((midi-69)/12)
    flutter = .008*np.sin(t*2*np.pi*.72)+.002*np.sin(t*2*np.pi*4.4)
    phase = 2*np.pi*f*t + np.cumsum(flutter)*2*np.pi*f/SR
    if kind=='flute':
        sig = sum(np.sin(phase*k + k*.17)*a for k,a in [(1,1),(2,.22),(3,.065),(4,.025)])
        sig += filtered_noise(len(t), 400, 3300)*.047
        attack, release = .09, .38
    elif kind=='horn':
        sig = sum(np.sin(phase*k)*np.exp(-k*.6)/k for k in range(1,9))
        attack, release = .8, 1.7
    else:
        # Bowed harmonics with slow instability and low-level rosin friction.
        sig = sum(np.sin(phase*k + .12*np.sin(t*(.7+k*.13)))*np.exp(-k*.3)/k for k in range(1,13))
        sig += filtered_noise(len(t), 150, 1600)*.015
        attack, release = .32, 1.0
    envelope = np.sin(np.minimum(t/attack,1)*np.pi/2)**2 * np.sin(np.minimum((duration-t)/release,1)*np.pi/2)**2
    return sig*envelope*(.9+.1*np.sin(t*2*np.pi*.19))

# Clear eight-note identity. A/B/A-prime/C/B-prime/A circular structure.
def pluck(midi,duration):
    t=np.arange(round(duration*SR))/SR
    f=440*2**((midi-69)/12)
    sig=sum(np.sin(2*np.pi*f*k*t+.04*k)*np.exp(-t*(2.4+k*.6))/k**1.5 for k in range(1,11))
    return sig*np.minimum(t/.005,1)*np.minimum((duration-t)/.055,1)

hook=[(0,62,.65),(.75,69,.6),(1.5,72,1.1),(3,70,.7),
      (4,69,1.1),(5.5,65,1.1),(7,63,1.7),(9.5,62,2.3)]
answer=[(0,65,.9),(1.25,67,.7),(2.25,69,1.3),(4,72,.8),
        (5.25,70,1.2),(7,67,.8),(8.25,63,1.2),(10,62,2.2)]
sections=['A','B','A_prime','C','B_prime','A']
roots=[38,46,43,45,46,38]
for section,(name,root) in enumerate(zip(sections,roots)):
    first=section*16
    quiet=name=='C'
    # Two-bar bass cell: short notes and rests, never a sustained sub drone.
    for bar in range(4):
        at=first+bar*4
        for offset,note,length,gain in [(0,root,.85,.16),(1.5,root,.45,.10),(2.5,root+7,.60,.12),(3.5,root+12,.30,.065)]:
            place('bass',pluck(note,length*BEAT),at+offset,gain*(.72 if quiet else 1),0)
        place('percussion',drum('hide',bar%3),at+.025,.24*(.7 if quiet else 1),-.12)
        if not quiet:place('percussion',drum('tom',bar%3),at+2.5,.14,.25)
        for offset,gain,pan in [(1,.11,-.45),(2.75,.075,.4),(3.5,.10,-.3)]:
            place('percussion',drum('wood'),at+offset,gain*(.65 if quiet else 1),pan)
        if name in ['A_prime','B_prime']:place('percussion',drum('rattle'),at+3.1,.065,.5)
        if bar==3 and not quiet:
            for offset,gain in [(2.9,.055),(3.35,.075),(3.75,.09)]:place('percussion',drum('tom'),at+offset,gain,-.2)
    phrase=answer if name.startswith('B') else hook
    if quiet:
        # Breathing section: wooden tuned plucks carry the familiar identity.
        for offset,note,length in hook:
            place('motif',pluck(note,length*BEAT),first+offset,.13,.12)
    else:
        for offset,note,length in phrase:
            place('motif',voice(note,length*BEAT,'flute'),first+offset,.17,-.10)
            if name in ['A_prime','B_prime']:
                place('motif',pluck(note-12,length*BEAT),first+offset,.07,.28)
    # Restrained, short string harmony follows bass roots rather than drones.
    chord=[root+12,root+19,root+27]
    for offset in [0,8]:
        for k,note in enumerate(chord):place('atmosphere',voice(note,3.4*BEAT,'bow'),first+offset+.1,.016,(-.4 if k%2 else .4))
    for offset,note,length in [(12.5,57,.65),(13.5,53,.65),(14.5,50,.9)]:
        place('motif',voice(note,length*BEAT,'horn'),first+offset,.07,.32)

# Circular diffuse reverb wraps all tails across the loop boundary.
for name, dry in stems.items():
    wet = np.zeros_like(dry)
    for channel in range(2):
        length=round(SR*1.9)
        ir=filtered_noise(length,120,3100)*np.exp(-np.arange(length)/SR*3.9)*.00015
        for delay,gain in [(0.09,.09),(.19,.055),(.31,.04),(.53,.025)]:
            ir[round((delay+channel*.017)*SR)]+=gain
        ir[:round(.065*SR)]=0
        wet[:,channel]=np.fft.irfft(np.fft.rfft(dry[:,channel])*np.fft.rfft(ir,n=N),n=N)
    stems[name] = dry+wet*(.45 if name=='motif' else .25)

mix=sum(stems.values())
mix-=mix.mean(axis=0)
mix=np.tanh(mix*1.25)/1.25
gain=10**(-2/20)/np.max(np.abs(mix))
mix*=gain

def save(path, samples):
    pcm=(np.clip(samples,-1,1)*32767).astype('<i2')
    with wave.open(str(path),'wb') as wav:
        wav.setnchannels(2);wav.setsampwidth(2);wav.setframerate(SR);wav.writeframes(pcm.tobytes())

master=OUT/'Extinction-Protocol-Ancient-Waking-Menu-Sketch-v3.wav'
save(master,mix)
for name,stem in stems.items():save(OUT/f'Ancient-Waking-v3-{name}.wav',stem*gain)
ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
preview=master.with_suffix('.mp3')
subprocess.run([ffmpeg,'-y','-i',str(master),'-c:a','libmp3lame','-b:a','256k',str(preview)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
metadata={'title':'Ancient Waking — Identity Theme','game':'Extinction Protocol','version':3,'role':'Idle main menu audition','duration_seconds':DURATION,'bpm':BPM,'motif':'D–A–C–B-flat–A–F–E-flat–D; eight-note main identity and a contrasting answer','instruments':'Synthesized hide drums, low toms, wooden impacts, rattles, changing restrained string harmony, clear flute theme, tuned wooden plucks, moving rhythmic bass and brief horn responses','loop':'24-bar circular composition and wrapped reverb tails; WAV intended for looping','implementation':'Private audition only; game soundtrack unchanged','peak_dbfs':float(20*np.log10(np.max(np.abs(mix)))),'rms_dbfs':float(20*np.log10(np.sqrt(np.mean(mix**2)))),'loop_boundary_step':float(np.max(np.abs(mix[0]-mix[-1]))) }
(OUT/'Ancient-Waking-v3-notes.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
print(json.dumps(metadata,indent=2));print(preview.resolve())
