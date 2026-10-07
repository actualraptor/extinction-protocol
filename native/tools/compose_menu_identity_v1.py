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
BPM = 64
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
    duration = {'hide':2.5, 'tom':1.1, 'wood':.3, 'rattle':.55}[kind]
    t = np.arange(round(SR*duration))/SR
    if kind in ['hide', 'tom']:
        fundamental = (57 if kind=='hide' else 113)*(1+variation*.035)
        sig = sum(np.sin(2*np.pi*fundamental*ratio*t + .8*(1-np.exp(-t*25))) * gain * np.exp(-t*decay)
                  for ratio, gain, decay in [(1,1,2.1),(1.59,.32,4.0),(2.14,.18,6.0),(2.65,.10,9)])
        sig += filtered_noise(len(t), 100, 1800)*np.exp(-t*45)*.13
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
        attack, release = .45, 1.1
    elif kind=='horn':
        sig = sum(np.sin(phase*k)*np.exp(-k*.6)/k for k in range(1,9))
        attack, release = .8, 1.7
    else:
        # Bowed harmonics with slow instability and low-level rosin friction.
        sig = sum(np.sin(phase*k + .12*np.sin(t*(.7+k*.13)))*np.exp(-k*.3)/k for k in range(1,13))
        sig += filtered_noise(len(t), 150, 1600)*.015
        attack, release = 2.6, 3.8
    envelope = np.sin(np.minimum(t/attack,1)*np.pi/2)**2 * np.sin(np.minimum((duration-t)/release,1)*np.pi/2)**2
    return sig*envelope*(.9+.1*np.sin(t*2*np.pi*.19))

# Quiet D/A drone: frequencies have integral periods across the complete loop.
t = np.arange(N)/SR
for channel in range(2):
    atmosphere = np.zeros(N)
    for frequency,gain in [(36.7,.048),(55,.023),(73.4,.020),(110,.008)]:
        frequency=round(frequency*DURATION)/DURATION
        atmosphere += np.sin(2*np.pi*frequency*t + channel*.16)*gain*(.8+.2*np.sin(2*np.pi*t/DURATION*3+frequency))
    wind = filtered_noise(N, 80, 1100)
    atmosphere += wind*(.014+.006*np.sin(2*np.pi*t/DURATION*4+channel))
    stems['atmosphere'][:,channel] = atmosphere

# Three eight-bar sections: sparse opening, slightly fuller middle, quiet return.
for bar in range(24):
    intensity = .8 if bar<8 else 1.0 if bar<16 else .73
    place('percussion',drum('hide',bar%3),bar*4+.04,.22*intensity,-.08)
    if bar%2==1:
        place('percussion',drum('tom',bar%3),bar*4+2.62,.09*intensity,.3)
    if bar%4 in [1,2]:
        place('percussion',drum('wood'),bar*4+1.55,.11*intensity,-.48)
    if 8<=bar<16 or bar%4==3:
        place('percussion',drum('rattle'),bar*4+3.2,.08*intensity,.55)
    if bar in [3,11,19]:
        place('percussion',drum('hide',-1),bar*4+3.42,.10,-.2)

for phrase in [0,32,64]:
    # Identity motif D–A–E-flat–G–D. Silence gives the semitone room to unsettle.
    for offset,midi,length in [(3,62,3.8),(7.5,69,3.1),(12,63,4.2),(17,67,3.8),(22,62,5.7)]:
        place('motif',voice(midi,length*BEAT,'flute'),phrase+offset,.070 if phrase!=32 else .083,-.22)
    for offset,midi in [(1,38),(12,46),(22,45)]:
        place('atmosphere',voice(midi,11*BEAT,'bow'),phrase+offset,.055,.26)
    place('motif',voice(50,5.8*BEAT,'horn'),phrase+27,.047,.48)

# Circular diffuse reverb wraps all tails across the loop boundary.
for name, dry in stems.items():
    wet = np.zeros_like(dry)
    for channel in range(2):
        length=round(SR*3.7)
        ir=filtered_noise(length,120,3100)*np.exp(-np.arange(length)/SR*2.15)*.00032
        for delay,gain in [(0.09,.09),(.19,.055),(.31,.04),(.53,.025)]:
            ir[round((delay+channel*.017)*SR)]+=gain
        ir[:round(.065*SR)]=0
        wet[:,channel]=np.fft.irfft(np.fft.rfft(dry[:,channel])*np.fft.rfft(ir,n=N),n=N)
    stems[name] = dry+wet*(1.25 if name=='motif' else .7)

mix=sum(stems.values())
mix-=mix.mean(axis=0)
mix=np.tanh(mix*1.25)/1.25
gain=10**(-2/20)/np.max(np.abs(mix))
mix*=gain

def save(path, samples):
    pcm=(np.clip(samples,-1,1)*32767).astype('<i2')
    with wave.open(str(path),'wb') as wav:
        wav.setnchannels(2);wav.setsampwidth(2);wav.setframerate(SR);wav.writeframes(pcm.tobytes())

master=OUT/'Extinction-Protocol-Ancient-Waking-Menu-Sketch-v1.wav'
save(master,mix)
for name,stem in stems.items():save(OUT/f'Ancient-Waking-v1-{name}.wav',stem*gain)
ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
preview=master.with_suffix('.mp3')
subprocess.run([ffmpeg,'-y','-i',str(master),'-c:a','libmp3lame','-b:a','256k',str(preview)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
metadata={'title':'Ancient Waking','game':'Extinction Protocol','version':1,'role':'Idle main menu audition','duration_seconds':DURATION,'bpm':BPM,'motif':'D–A–E-flat–G–D','instruments':'Synthesized hide drums, low toms, wooden impacts, rattles, bowed drones, breathy flute and distant horn','loop':'90-second circular composition and wrapped reverb tails; WAV intended for looping','implementation':'Private audition only; game soundtrack unchanged','peak_dbfs':float(20*np.log10(np.max(np.abs(mix)))),'rms_dbfs':float(20*np.log10(np.sqrt(np.mean(mix**2)))),'loop_boundary_step':float(np.max(np.abs(mix[0]-mix[-1]))) }
(OUT/'Ancient-Waking-v1-notes.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
print(json.dumps(metadata,indent=2));print(preview.resolve())
