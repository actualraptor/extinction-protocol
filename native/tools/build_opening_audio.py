"""Original atmospheric opening score and short layered companion attack Foley.

No square-wave/chiptune oscillators. Bowed harmonic beds, breathy formants,
low drums and reverberant bells support the narration's measured cues.
"""
from pathlib import Path
import subprocess
import wave
import sys
import numpy as np
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio'
TMP = ROOT / 'build/intro'
TMP.mkdir(parents=True, exist_ok=True)
SR = 32000
rng = np.random.default_rng(78104)

def wav(path, data):
    if data.ndim == 1:
        data = np.column_stack([data, data])
    with wave.open(str(path), 'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes((np.clip(data, -.96, .96)*32767).astype('<i2').tobytes())

def noise(n, cutoff):
    raw = rng.normal(0, 1, n)
    frequencies = np.fft.rfftfreq(n, 1/SR)
    colored = np.fft.irfft(np.fft.rfft(raw)/(1+(frequencies/cutoff)**4), n)
    return colored / max(.001, np.std(colored))

duration = 64.0
score = np.zeros((int(duration*SR), 2))
def place(signal, at, gain=.1, pan=0, reverb=True):
    gains = np.sqrt(np.array([1-pan,1+pan])/2)*gain
    for delay, level in ([(0,1),(.19,.14),(.37,.12),(.61,.1),(1.1,.07),(1.7,.04)] if reverb else [(0,1)]):
        start = int((at+delay)*SR)
        count = min(len(signal),len(score)-start)
        if count>0:
            score[start:start+count] += signal[:count,None]*gains*level

def bowed(freq, seconds, seed):
    t = np.arange(int(seconds*SR))/SR
    envelope = np.minimum(t/2.5,1)*np.minimum((seconds-t)/3,1)
    vibrato = .003*np.sin(t*2*np.pi*4.2+seed)
    phase = 2*np.pi*freq*t+.15*np.sin(t*2*np.pi*.18+seed)
    sound = np.zeros_like(t)
    for h in range(1,9):
        sound += np.sin(phase*h+vibrato*h)/(h**1.55)
    return sound*envelope*(.8+.2*np.sin(t*.47+seed))

# Dread gives way to a suspended, hopeful D-minor/add-sixth champion theme,
# before the descending bass returns for the threat beyond the breach.
sections = [(0,17,[73.416,110,146.832]),(12,18,[65.406,98,130.812]),
            (26.25,15,[73.416,110,146.832,220,246.942]),(38.52,13,[58.27,87.31,146.832]),
            (47.16,16.84,[55,82.407,110,146.832,155.563])]
for k,(at,length,notes) in enumerate(sections):
    for j,freq in enumerate(notes):
        place(bowed(freq,length,k+j),at,.055 if j<2 else .025,(j%3-1)*.55)
    t = np.arange(int(length*SR))/SR
    breath = noise(len(t),580)*np.minimum(t/3,1)*np.minimum((length-t)/3,1)
    # A filtered breath bed behaves like a distant choir without fake syllables.
    place(breath*(.65+.35*np.sin(t*.29+k)),at,.009,(-1 if k%2 else 1)*.7)

def horn(freq, seconds):
    """Soft brass formant with a breath attack and human vibrato, no hard edge."""
    t=np.arange(int(seconds*SR))/SR
    phase=2*np.pi*freq*t+.035*np.sin(2*np.pi*4.7*t)*np.minimum(t,1)
    envelope=np.minimum(t/.28,1)*np.minimum((seconds-t)/.65,1)
    tone=sum(np.sin(phase*h)*np.exp(-((h*freq-650)/1100)**2)/h**1.3 for h in range(1,12))
    return (tone+.018*noise(len(t),1100))*envelope

# A single restrained theme enters exactly as the three champions appear.
# The rising sixth suggests hope; its final unresolved fifth hands back to dread.
for at, freq, length in [(26.25,293.665,2.6),(28.65,349.228,2.5),
                         (31.0,440.0,3.0),(33.7,493.883,2.5),
                         (36.0,440.0,2.4),(38.2,293.665,3.4)]:
    place(horn(freq,length),at,.065,-.12)
    place(bowed(freq/2,length+1.5,at),at,.025,.42)

def bell(freq, seconds=5):
    t=np.arange(int(seconds*SR))/SR
    return sum(np.sin(2*np.pi*freq*ratio*t)*np.exp(-t*decay)*gain
               for ratio,decay,gain in [(1,.65,.6),(2.01,1.1,.23),(2.71,1.6,.15),(4.12,2,.08)])*np.minimum(t/.012,1)
for at,freq in [(4.08,293.665),(12.01,261.626),(26.25,349.228),(34.25,440),(47.16,220),(55.38,146.832),(60.45,73.416)]:
    place(bell(freq),at,.08 if at<47 else .14,.22)
for at in [12.01,26.25,38.52,43.76,47.16,51.8,55.38,60.45]:
    t=np.arange(int(2.8*SR))/SR
    drum=np.sin(2*np.pi*(42*t+2*(1-np.exp(-t*18))))*np.exp(-t*3.3)
    drum+=noise(len(t),180)*np.exp(-t*7)*.22
    place(drum,at,.16 if at<47 else .27,-.15)
# A gentle riser leads into the final warning, not a loud hit over the voice.
t=np.arange(int(8.22*SR))/SR
place(noise(len(t),1800)*(t/t[-1])**2*.13,47.16,.13,.45)
timeline=np.arange(len(score))/SR
score*=np.minimum(timeline/2,1)[:,None]*np.minimum((duration-timeline)/2.5,1)[:,None]
score*=.88/max(.88,float(np.max(np.abs(score))))
wav(TMP/'score.wav',score)
ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
subprocess.run([ffmpeg,'-y','-i',str(TMP/'score.wav'),'-c:a','libvorbis','-q:a','5',str(ROOT/'assets/intro/score.ogg')],capture_output=True,check=True)
print(f'Opening theme: {duration:.0f}s, peak {np.max(np.abs(score)):.3f}, RMS {np.sqrt(np.mean(score**2)):.3f}')
if '--score-only' in sys.argv:
    raise SystemExit(0)

# Five attack signatures; three fixed variants cycle without touching game RNG.
for role in ['blade','guard','bow','wraith','heavy']:
    for variant in range(3):
        seconds=.44 if role not in ['wraith','heavy'] else .68
        t=np.arange(int(seconds*SR))/SR
        low=noise(len(t),350); air=noise(len(t),2600)
        if role in ['blade','guard']:
            signal=air*np.exp(-((t-.06)/.033)**2)*.24
            impact=np.maximum(0,t-.085)
            gate=(t>=.085)
            signal+=gate*(low*np.exp(-impact*35)*.43+np.sin(2*np.pi*(155+variant*11)*impact)*np.exp(-impact*18)*.37)
            for f in [1320,2381,3514]:signal+=gate*np.sin(2*np.pi*f*impact)*np.exp(-impact*25)*(.055 if role=='blade' else .1)
        elif role=='bow':
            signal=air*np.exp(-((t-.035)/.025)**2)*.25
            signal+=np.sin(2*np.pi*(360+variant*30)*t)*np.exp(-t*36)*.37
            signal+=low*np.exp(-t*50)*.18
        elif role=='wraith':
            signal=air*np.sin(t*9)*np.exp(-((t-.18)/.13)**2)*.23
            signal+=sum(np.sin(2*np.pi*f*t)*np.exp(-t*7)*.05 for f in [180,271,397])
        else:
            signal=air*np.exp(-((t-.08)/.05)**2)*.2
            impact=np.maximum(0,t-.11);gate=t>=.11
            signal+=gate*(low*np.exp(-impact*11)*.39+np.sin(2*np.pi*(49*impact+2*(1-np.exp(-impact*28))))*np.exp(-impact*7)*.6)
            for at in [.135,.17,.225]:signal+=air*np.exp(-((t-at)/.01)**2)*.2
        signal*=np.minimum(t/.003,1)*np.minimum((seconds-t)/.04,1)
        signal*=.82/max(.82,float(np.max(np.abs(signal))))
        wav(OUT/('unit_'+role+('' if variant==0 else '_v'+str(variant))+'.wav'),signal)
print('Original 64-second atmospheric score and 15 companion attack variants written')
