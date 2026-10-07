"""Deterministic layered creature sound design; no voice or third-party samples."""
from pathlib import Path
import numpy as np
import wave
OUT=Path(__file__).resolve().parents[1]/'assets/audio'
rate=22050
for index,id in enumerate(['thorn','basalt','hunt','aurora','warden','bloom']):
 for category,duration in [('step',.38),('windup',.65),('attack',.45),('impact',.48),('roar',1.65),('death',1.7)]:
  rng=np.random.default_rng(710+index*13+len(category));t=np.arange(int(rate*duration))/rate
  noise=rng.normal(0,1,len(t));low=np.convolve(noise,np.ones(36+index*8)/(36+index*8),'same')
  base=[51,32,89,45,76,39][index]
  if category=='roar' or category=='death':
   pitch=base*(1+.5*np.sin(t/duration*np.pi))*(1-.35*t/duration)
   phase=np.cumsum(pitch)*2*np.pi/rate
   signal=(np.sin(phase)+.5*np.sin(phase*1.97)+.22*np.sin(phase*3.1))*.35+low*2.0
   signal*=np.minimum(1,t/.09)*np.maximum(0,1-t/duration)**.7*(.82+.18*np.sin(t*21+index))
  elif category=='step' or category=='impact':
   signal=np.sin(2*np.pi*(base*1.1*t-20*t*t))*np.exp(-t*15)+low*3*np.exp(-t*9)+noise*.1*np.exp(-t*45)
  else:
   signal=low*2.4+np.sin(2*np.pi*(base*1.6*t-25*t*t))*.22
   signal*=np.sin(np.pi*t/duration)**.7
  signal=np.tanh(signal*1.4);signal/=max(1.0,float(np.max(np.abs(signal))))
  signal*=.55 if category=='step' else .74
  with wave.open(str(OUT/f'dino_{id}_{category}.wav'),'wb') as out:
   out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate);out.writeframes((signal*32767).astype('<i2').tobytes())
print('36 distinct layered dinosaur cues generated')
