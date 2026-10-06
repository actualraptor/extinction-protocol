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
TMP = ROOT / 'build/first-rite'
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

duration = 124.0
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


# Slow minor harmonies: quiet dread, a restrained binding swell, then release.
for n,(at,notes) in enumerate([(0,[55,82.407,110]),(28,[58.27,87.31,116.54]),(47,[55,82.407,130.812]),(70,[65.406,98,146.832]),(102,[55,82.407,110,164.814])]):
    length=min(34,duration-at)
    for j,freq in enumerate(notes):place(bowed(freq,length,n+j),at,.045 if j<2 else .024,(j%3-1)*.6)
    t=np.arange(int(length*SR))/SR
    breath=noise(len(t),850)*np.minimum(t/4,1)*np.minimum((length-t)/4,1)
    place(breath,at,.006,(-1 if n%2 else 1)*.7)
for at in [47,70,102,118]:
    t=np.arange(int(5*SR))/SR
    tone=sum(np.sin(2*np.pi*freq*t)*np.exp(-t*.65)*gain for freq,gain in [(146.832,.6),(293.665,.2),(397.1,.1)])
    place(tone*np.minimum(t/.08,1),at,.055,.2)
timeline=np.arange(len(score))/SR
score*=np.minimum(timeline/4,1)[:,None]*np.minimum((duration-timeline)/4,1)[:,None]
wav(TMP/'rite-score.wav',score)
subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-i',str(TMP/'rite-score.wav'),'-c:a','libvorbis','-q:a','5',str(TMP/'score.ogg')],capture_output=True,check=True)
print('First rite: original 124-second haunted score composed')
