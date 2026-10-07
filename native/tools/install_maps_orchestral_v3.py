"""Install reviewed map revisions without changing the exported v15 playtest."""
from music_cue import OUT, ROOT
import subprocess,json,wave
import numpy as np
import imageio_ffmpeg
names={'cradle':'The-Lost-Cradle','frostbreak':'Frostbreak-Expanse','observatory':'The-Sunken-Observatory'}
report={}
for identity,title in names.items():
    name='Extinction-Protocol-'+title+'-Map-v3'
    review=json.loads((OUT/(name+'-review.json')).read_text())
    assert review['notes_closed'] and review['seam_after']<1e-5 and review['true_peak_dbfs']<-1
    with wave.open(str(OUT/(name+'.wav'))) as w:
        rate=w.getframerate();samples=np.frombuffer(w.readframes(w.getnframes()),'<i2').reshape(-1,2)/32768
    rms=[]
    bpm={'cradle':116,'frostbreak':100,'observatory':120}[identity]
    for begin,end in [(0,40),(40,72),(72,96),(96,120),(120,160),(160,192)]:
        section=samples[round(begin*60/bpm*rate):round(end*60/bpm*rate)]
        rms.append(round(float(20*np.log10(np.sqrt(np.mean(section**2)))),2))
    assert rms[3]<rms[2], 'Breakdown must measurably withdraw energy'
    target=ROOT/'native/assets/audio/soundtrack'/ (identity+'.ogg')
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-i',str(OUT/(name+'.wav')),
                    '-c:a','libvorbis','-q:a','6',str(target)],capture_output=True,check=True)
    report[identity]={'source':name,'seconds':review['seconds'],'section_rms_dbfs':rms,
                      'master_review':review,'runtime_asset':str(target),'status':'Preview pending user listening; integrated in source.'}
(OUT/'map-orchestral-v3-validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
