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


OUT.mkdir(parents=True,exist_ok=True)
t=np.arange(12*SR)/SR
fade=np.minimum(t/.55,1)*np.minimum((12-t)/.9,1)
# Low throaty vowels, distant breath and a slowly beating drone.
hum=np.zeros_like(t)
for fundamental,gain in [(55,.15),(82.407,.07),(110,.04)]:
    phase=2*np.pi*fundamental*t+.07*np.sin(t*2*np.pi*4.1)
    for h in range(1,15):
        formant=np.exp(-((h*fundamental-420)/220)**2)+.4*np.exp(-((h*fundamental-1050)/300)**2)
        hum+=np.sin(phase*h)*formant*gain/h**.8
hum+=(noise(len(t),750)*.025+np.sin(2*np.pi*55*t)*.1)*(.7+.3*np.sin(t*1.9)**2)
hum*=fade*(.6+.4*np.sin(t*1.2)**2)
# Reverberant, wordless ritual hum, with no harsh digital edge.
wet=hum.copy()
for delay,gain in [(.23,.24),(.47,.18),(.79,.12)]:
    n=int(delay*SR);wet[n:]+=hum[:-n]*gain
wav(OUT/'rite_hum.wav',wet)
for variant in range(3):
    t=np.arange(int(.65*SR))/SR
    crunch=noise(len(t),650)*np.exp(-t*15)*.25
    crunch+=noise(len(t),2800)*np.exp(-t*36)*.1
    for at in [.015,.052,.087,.143]:
        crunch+=noise(len(t),1600)*np.exp(-((t-at)/.009)**2)*.24
    crunch+=np.sin(2*np.pi*(78+variant*7)*t)*np.exp(-t*20)*.2
    crunch*=np.minimum(t/.003,1)*np.minimum((.65-t)/.08,1)
    wav(OUT/('rite_crunch'+('' if variant==0 else '_v'+str(variant))+'.wav'),crunch)
# A wordless voiced invocation: breath attack, low impact and vowel harmonics.
t=np.arange(int(1.2*SR))/SR
pulse=noise(len(t),850)*np.exp(-t*13)*.08
pulse+=np.sin(2*np.pi*(65*t+12*(1-np.exp(-t*8))))*np.exp(-t*7)*.24
for h in range(1,18):
    formant=np.exp(-((h*73.416-450)/240)**2)+.35*np.exp(-((h*73.416-1100)/300)**2)
    pulse+=np.sin(2*np.pi*73.416*h*t)*formant/h**.8*.19*np.exp(-t*4)
pulse+=sum(np.sin(2*np.pi*f*t)*np.exp(-t*6)*.035 for f in [293.664,440,587.328])
pulse*=np.minimum(t/.006,1)
wet=pulse.copy()
for delay,gain in [(.17,.3),(.34,.16),(.51,.09)]:
    n=int(delay*SR);wet[n:]+=pulse[:-n]*gain
wav(OUT/'rite_pulse.wav',wet)
t=np.arange(int(.55*SR))/SR
lock=noise(len(t),2100)*np.exp(-t*38)*.2
lock+=np.sin(2*np.pi*146.832*t)*np.exp(-t*11)*.14
lock+=np.sin(2*np.pi*587.328*t)*np.exp(-t*14)*.04
wav(OUT/'rite_lock.wav',lock*np.minimum(t/.003,1))
t=np.arange(int(1.8*SR))/SR
release=noise(len(t),1800)*np.exp(-((t-.15)/.15)**2)*.13
release+=np.sin(2*np.pi*(48*t+8*(1-np.exp(-t*9))))*np.exp(-t*5)*.32
release+=sum(np.sin(2*np.pi*f*t)*np.exp(-t*3)*.08 for f in [110,164.814,220,440])
wav(OUT/'rite_finish.wav',release*np.minimum(t/.008,1))
print('Ritual hum, crunches, voiced pulse, assembly locks and impact release created')
