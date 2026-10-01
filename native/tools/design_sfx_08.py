from pathlib import Path
import numpy as np, wave, json
out=Path('native/assets/audio');sr=32000;rng=np.random.default_rng(8031)
ids='revolver shotgun frost fire lightning club spear orbital mortar pyre winter miasma dread aegis stasis thunderstorm thunder_hit chain_tick ricochet return harpoon lantern glacier sunbow thorns breakable impact_frost impact_fire impact_metal'.split()
manifest=[]
for k,id in enumerate(ids):
 duration={'mortar':.32,'thunderstorm':.43,'dread':.42,'stasis':.38,'breakable':.28,'glacier':.18,'chain_tick':.065}.get(id,.20+(k%3)*.035)
 t=np.arange(int(sr*duration))/sr;n=len(t);noise=rng.normal(0,1,n);sm=np.convolve(noise,np.ones(13)/13,'same');high=noise-np.convolve(noise,np.ones(5)/5,'same')
 def chirp(a,b,decay=24): return np.sin(2*np.pi*(a*t+(b-a)*t*t/(2*duration)))*np.exp(-t*decay)
 def body(f,decay=22):return np.sin(2*np.pi*f*t)*np.exp(-t*decay)
 if id in ['glacier','frost','winter','impact_frost']:
  # Airy slice and broken ice grains: no sustained pitched warning tone.
  sig=high*np.exp(-t*(33 if id=='glacier' else 20))*.32+sm*np.sin(np.pi*np.minimum(1,t/.07))*np.exp(-t*22)*1.5
  for j,f in enumerate([2317,3791,5123]):sig+=body(f+(k%4)*117,45+j*9)*.09
 elif id in ['lightning','thunder_hit','chain_tick','thunderstorm']:
  pulses=(.28+.72*np.maximum(0,np.sin(2*np.pi*(54+k*4)*t))**8)
  sig=high*pulses*np.exp(-t*22)*.44+chirp(180,45,14)*.55+sm*np.exp(-t*9)*.45
 elif id in ['revolver','shotgun','sunbow','harpoon']:
  sig=high*np.exp(-t*65)*.65+chirp(180+k*4,42,30)*.7+sm*np.exp(-t*28)*.45
  if id=='sunbow':sig+=chirp(2100,550,34)*.15
 elif id in ['club','spear','thorns','breakable','impact_metal']:
  sig=sm*np.exp(-t*18)*1.8+chirp(125+k*2,38,24)*.65+high*np.exp(-t*60)*.18
  for j in range(4):sig+=body(650+j*421+k*23,30+j*12)*.07
 elif id in ['fire','mortar','pyre','impact_fire']:
  sig=sm*np.exp(-t*15)*2.1+chirp(145,35,19)*.65+high*np.exp(-t*48)*.16
 elif id in ['orbital','return','ricochet']:
  sig=high*np.sin(np.pi*np.minimum(1,t/.09))*np.exp(-t*24)*.32+chirp(1400+k*30,280,28)*.18+sm*np.exp(-t*24)*1.1
 else:
  sig=sm*np.exp(-t*15)*.8+chirp(370+k*9,170+k*3,15)*.3+body(940+k*43,23)*.13+high*np.exp(-t*45)*.1
 sig*=np.minimum(1,t/.0015)*np.minimum(1,(duration-t)/.012)
 sig=np.tanh(sig*1.5);sig*=.78/max(.001,np.max(np.abs(sig)))
 right=np.roll(sig,37);right[:37]=0
 stereo=np.stack([sig,right*.94],axis=1)
 path=out/(id+'_08.wav')
 with wave.open(str(path),'wb') as f:
  f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr);f.writeframes((stereo*32767).astype('<i2').tobytes())
 manifest.append({'id':id,'seconds':duration,'peak':float(abs(stereo).max()),'rms':float(np.sqrt((stereo**2).mean()))})
(out/'sfx-08.json').write_text(json.dumps(manifest,indent=2))
print('Rendered',len(ids),'original weapon and impact sounds')
