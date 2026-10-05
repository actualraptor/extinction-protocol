"""Original layered, repeat-friendly starter audio; leaves previous WAVs intact."""
from pathlib import Path
import hashlib,json,shutil,wave
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'native/assets/audio'
BACKUP=ROOT/'backups/audio-0113'
SR=32000

def read(path):
 with wave.open(str(path),'rb') as f:
  return np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(float)/32768,f.getframerate(),f.getnchannels()

def noise(rng,n,width):
 return np.convolve(rng.normal(0,1,n),np.ones(width)/width,mode='same')

def synth(kind,index):
 rng=np.random.default_rng(11300+index+{'revolver':0,'lightning':100,'chain_tick':200}[kind])
 duration={'revolver':.265,'lightning':.36,'chain_tick':.115}[kind]
 t=np.arange(round(duration*SR))/SR;n=len(t)
 white=rng.normal(0,1,n)
 warm=noise(rng,n,15);crisp=noise(rng,n,4)-noise(rng,n,19)
 detune=1+(index-1)*.022
 if kind=='revolver':
  # Rounded explosive attack, low chamber punch, then dry mechanical click.
  x=crisp*np.exp(-t*95)*.65+warm*np.exp(-t*38)*.8
  phase=2*np.pi*detune*(72*t+2.7*(1-np.exp(-t*42)))
  x+=np.sin(phase)*np.exp(-t*29)*.55
  x+=np.sin(2*np.pi*detune*310*t)*np.exp(-t*60)*.11
  for at,gain in [(.048,.18),(.089,.075)]:
   x+=crisp*np.exp(-((t-at)/.0035)**2)*gain
 elif kind=='lightning':
  # Thunder body plus short irregular electrical branches, no piercing whistle.
  phase=2*np.pi*detune*(63*t+1.9*(1-np.exp(-t*35)))
  x=np.sin(phase)*np.exp(-t*18)*.40+warm*np.exp(-t*20)*.85
  x+=crisp*np.exp(-t*120)*.50
  for at,gain in [(.025,.30),(.053,.21),(.092,.13),(.147,.055)]:
   x+=crisp*np.exp(-((t-at)/.0028)**2)*gain
  # Very soft harmonically related glow, quickly fading rather than alarm pitch.
  x+=np.sin(2*np.pi*detune*392*t)*np.exp(-t*34)*.055
  x+=np.sin(2*np.pi*detune*588*t)*np.exp(-t*40)*.025
 else:
  x=crisp*np.exp(-t*85)*.40+warm*np.exp(-t*45)*.40
  x+=np.sin(2*np.pi*detune*165*t)*np.exp(-t*48)*.13
  for at in [.017,.039]:x+=crisp*np.exp(-((t-at)/.002)**2)*.11
 # Smooth sub-millisecond start and last 18ms prevent edge clicks; soft saturation.
 x*=np.minimum(t/.0007,1)*np.minimum((duration-t)/.018,1)
 x=np.tanh(x*1.4)
 stereo=np.stack([x,x],axis=1)
 shift=round(.013*SR)
 stereo[shift:,0]+=x[:-shift]*.045
 stereo[shift+19:,1]+=x[:-(shift+19)]*.045
 old,_,_=read(OUT/f'{kind}_08.wav')
 # Integrated RMS no louder than the existing sound despite shorter, warmer body.
 target=min(np.sqrt(np.mean(old**2))*.92,{'revolver':.13,'lightning':.105,'chain_tick':.065}[kind])
 stereo*=target/max(np.sqrt(np.mean(stereo**2)),1e-8)
 stereo*=min(1,.82/np.max(np.abs(stereo)))
 return stereo

def main():
 BACKUP.mkdir(parents=True,exist_ok=True);report={}
 for kind in ['revolver','lightning','chain_tick']:
  original=OUT/f'{kind}_08.wav'
  backup=BACKUP/original.name
  if not backup.exists():shutil.copy2(original,backup)
  report[original.name]={'original_sha256':hashlib.sha256(original.read_bytes()).hexdigest(),'backup_sha256':hashlib.sha256(backup.read_bytes()).hexdigest()}
  assert report[original.name]['original_sha256']==report[original.name]['backup_sha256']
  for i in range(3):
   samples=synth(kind,i);filename=f'{kind}_0113'+('' if i==0 else f'_v{i}')+'.wav'
   with wave.open(str(OUT/filename),'wb') as f:
    f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes(np.rint(samples*32767).astype('<i2').tobytes())
   peak=float(np.max(np.abs(samples)));rms=float(np.sqrt(np.mean(samples**2)))
   assert peak<=.821 and .005<rms<.15
   assert np.max(np.abs(samples[:1]))<.001 and np.max(np.abs(samples[-1:]))<.01
   report[filename]={'duration':len(samples)/SR,'peak':peak,'rms':rms,'clip_samples':int(np.count_nonzero(np.abs(samples)>=.999))}
 (BACKUP/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
 # Sparse high-haste listening preview: ordinary gun and chain casts, several repeats.
 preview=np.zeros((SR*8,2))
 for kind,start,spacing,count in [('revolver',.2,.38,6),('lightning',3.0,.52,6),('chain_tick',3.11,.17,15)]:
  for i in range(count):
   sound=synth(kind,i%3);at=round((start+i*spacing)*SR)
   preview[at:at+len(sound)]+=sound*.72
 with wave.open(str(BACKUP/'starter-preview-0113.wav'),'wb') as f:
  f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes(np.rint(preview*32767).astype('<i2').tobytes())
 print(json.dumps(report,indent=2))

if __name__=='__main__':main()
