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
BPM = 76
BEAT = 60 / BPM
DURATION = 96 * BEAT
N = round(DURATION * SR)
OUT = Path(__file__).resolve().parents[1] / 'build/music-review'
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(710064)
stems = {name: np.zeros((N, 2), dtype=np.float64) for name in ['atmosphere', 'percussion', 'motif']}

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

# No continuous wind or sub-bass bed. Harmony breathes between phrases.
# Eight-bar melody with a rhythmic opening hook and answering phrase.
melody=[(0,62,1.3),(1.5,69,.65),(2.5,72,.85),(4,70,1.3),
        (5.5,69,.85),(7,65,1.5),(9,67,.9),(10.5,63,.85),(12,62,2.6),
        (16,62,1.3),(17.5,69,.65),(18.5,72,.85),(20,74,1.3),
        (21.5,72,.85),(23,70,1.3),(25,69,.9),(26.5,67,.7),(28,63,.8),(29.5,62,1.5)]
for bar in range(24):
    intensity=.83 if bar<8 else 1.0 if bar<16 else .78
    place('percussion',drum('hide',bar%3),bar*4+.02,.25*intensity,-.12)
    if bar%2==0:place('percussion',drum('hide',-1),bar*4+2.52,.10*intensity,.12)
    for at,gain,pan in [(1.48,.13,-.4),(3.05,.11,.4)]:
        place('percussion',drum('wood'),bar*4+at,gain*intensity,pan)
    if bar%2==1:place('percussion',drum('tom',bar%3),bar*4+2.7,.15*intensity,.28)
    if 8<=bar<16:place('percussion',drum('rattle'),bar*4+3.5,.075,.5)
    if bar%8==7:
        for at,gain in [(2,.07),(2.75,.10),(3.5,.12)]:place('percussion',drum('tom'),bar*4+at,gain,-.24)
for phrase in [0,32,64]:
    for offset,midi,length in melody:
        place('motif',voice(midi,length*BEAT,'flute'),phrase+offset,.155 if phrase!=32 else .17,-.12)
    # Low strings change harmony: D minor, B-flat, G minor, E-flat/D tension.
    for offset,notes in [(0,[50,57,65]),(8,[46,53,62]),(16,[43,50,58]),(24,[51,58,62])]:
        for k,note in enumerate(notes):
            place('atmosphere',voice(note,5.2*BEAT,'bow'),phrase+offset+.22,.022,(-.36 if k%2 else .36))
    # A quiet, human-sounding lower response, never a sustained engine note.
    for offset,midi,length in [(14.7,50,1.1),(15.8,57,.8),(30.8,50,1.0)]:
        place('motif',voice(midi,length*BEAT,'horn'),phrase+offset,.060,.32)

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

master=OUT/'Extinction-Protocol-Ancient-Waking-Menu-Sketch-v2.wav'
save(master,mix)
for name,stem in stems.items():save(OUT/f'Ancient-Waking-v2-{name}.wav',stem*gain)
ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
preview=master.with_suffix('.mp3')
subprocess.run([ffmpeg,'-y','-i',str(master),'-c:a','libmp3lame','-b:a','256k',str(preview)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
metadata={'title':'Ancient Waking — Theme Revision','game':'Extinction Protocol','version':2,'role':'Idle main menu audition','duration_seconds':DURATION,'bpm':BPM,'motif':'D–A–C–B-flat–A / F–G–E-flat–D, with an answering eight-bar phrase','instruments':'Synthesized hide drums, low toms, wooden impacts, rattles, changing restrained string harmony, clear flute theme and brief low horn responses','loop':'24-bar circular composition and wrapped reverb tails; WAV intended for looping','implementation':'Private audition only; game soundtrack unchanged','peak_dbfs':float(20*np.log10(np.max(np.abs(mix)))),'rms_dbfs':float(20*np.log10(np.sqrt(np.mean(mix**2)))),'loop_boundary_step':float(np.max(np.abs(mix[0]-mix[-1]))) }
(OUT/'Ancient-Waking-v2-notes.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
print(json.dumps(metadata,indent=2));print(preview.resolve())
