"""Two original short weapon cues, plus crystal and returning-blade identities."""
from pathlib import Path
import wave
import numpy as np
SR=32000
out=Path(__file__).resolve().parents[1]/'assets/audio'
rng=np.random.default_rng(909)
for name,duration in [('ricochet',.34),('return',.4)]:
    t=np.arange(int(SR*duration))/SR
    if name=='ricochet':
        signal=sum(np.sin(2*np.pi*f*t)*np.exp(-t*k)*a for f,k,a in [(1108,13,.35),(1662,17,.23),(2770,24,.13)])
        signal+=rng.uniform(-1,1,len(t))*np.exp(-t*100)*.17
    else:
        noise=rng.uniform(-1,1,len(t))
        filtered=np.convolve(noise,np.ones(13)/13,mode='same')
        signal=filtered*np.sin(np.pi*t/duration)**2*1.3
        signal+=np.sin(2*np.pi*(520*t-260*t*t))*np.exp(-t*12)*.18
    signal*=np.minimum(t/.004,1)*np.minimum((duration-t)/.025,1)
    stereo=np.stack([signal,np.roll(signal,40)],axis=1)
    with wave.open(str(out/(name+'.wav')),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR)
        f.writeframes((np.clip(stereo,-.95,.95)*32767).astype('<i2').tobytes())
    print(name)
