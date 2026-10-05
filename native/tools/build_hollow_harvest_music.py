"""Original Hollow Harvest score: nine map/depth-specific chip-fantasy loops.

Composed/synthesized locally. No samples, melodies, or recordings copied.
Run with the bundled Python runtime. Generated WAVs are runtime assets.
"""
from pathlib import Path
import json
import wave
import numpy as np

RATE = 22050
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"

def frequency(note):
    return 440 * 2 ** ((note - 69) / 12)

def voice(note, seconds, kind, velocity=1):
    count = int(seconds * RATE)
    t = np.arange(count) / RATE
    hz = frequency(note)
    phase = t * hz
    if kind == "bell":
        sound = np.sin(2*np.pi*phase) + .36*np.sin(2*np.pi*phase*2.01) + .14*np.sin(2*np.pi*phase*3.98)
        envelope = np.exp(-t*6/max(.2,seconds))
    elif kind == "bass":
        sound = np.sin(2*np.pi*phase) + .25*np.sin(2*np.pi*phase*3) + .1*np.sin(2*np.pi*phase*5)
        envelope = np.minimum(t/.009,1)*np.minimum((seconds-t)/.035,1)*np.exp(-t*.8)
    else:
        duty = .25 if kind == "lead" else .125
        sound = np.zeros(count)
        for harmonic in range(1,9):
            sound += np.sin(np.pi*harmonic*duty)/harmonic * np.sin(2*np.pi*harmonic*phase+.06*np.sin(t*25))
        envelope = np.minimum(t/.007,1)*np.minimum((seconds-t)/.025,1)*np.exp(-t*1.2)
    sound *= np.maximum(envelope,0)*velocity
    return sound

def build(map_index, depth):
    bpm = [136,124,148][map_index] + depth*4
    beat = 60/bpm
    bars = 32
    length = bars*4*beat
    track = np.zeros((int(length*RATE),2),dtype=np.float64)
    rng = np.random.default_rng(1031+map_index*100+depth)
    key = [57,54,59][map_index]
    # Original minor-mode refrain: steps, little tritone surprises and answering phrase.
    refrain = [0,3,7,10,7,3,2,0, 7,10,12,10,7,5,3,2,
               0,3,7,8,7,5,3,2, -1,2,5,7,5,2,-1,0]
    roots = [0,0,8,8,5,5,7,7]
    def add(at, sound, gain, pan=0):
        start = int(at*RATE)
        usable = min(len(sound),len(track)-start)
        if usable <= 0: return
        p = np.clip(pan,-1,1)
        track[start:start+usable,0] += sound[:usable]*gain*(1-p*.3)
        track[start:start+usable,1] += sound[:usable]*gain*(1+p*.3)
    for bar in range(bars):
        at = bar*4*beat
        root = key-12+roots[(bar//2)%8]
        chord = [0,3,7] if (bar//2)%8 not in [6,7] else [0,4,7]
        for step in range(8):
            # Plucked chip arpeggio keeps the groove busy without a piercing alarm tone.
            note = root+12+chord[(step+map_index)%3]
            add(at+step*beat*.5,voice(note,beat*.4,"arp"),.045+depth*.004,(-1 if step%2 else 1)*.6)
            if step%2 == 0:
                add(at+step*beat*.5,voice(root,beat*.72,"bass"),.12)
        for step in range(4):
            t = np.arange(int(beat*.36*RATE))/RATE
            kick = np.sin(2*np.pi*(52*t+19*(1-np.exp(-t*30))/30))*np.exp(-t*24)
            add(at+step*beat,kick,.19 if step%2==0 else .09)
            if step in [1,3]:
                t = np.arange(int(beat*.25*RATE))/RATE
                noise = rng.uniform(-1,1,len(t))
                snare = (.6*noise+.3*np.sin(2*np.pi*170*t))*np.exp(-t*28)
                add(at+step*beat,snare,.085,.1)
        for step in range(8):
            t = np.arange(int(.045*RATE))/RATE
            noise = rng.uniform(-1,1,len(t))
            hat = np.diff(noise,prepend=0)*np.exp(-t*90)
            add(at+step*beat*.5,hat,.018,-.35)
        # Melody breathes in two-bar phrases; middle section trades lead for chiming bells.
        if bar%8 < 6:
            for step in range(4):
                motif = refrain[(bar*4+step)%len(refrain)]
                note = key+12+motif+(12 if depth==2 and bar>=24 else 0)
                kind = "bell" if map_index==1 or 16<=bar<24 else "lead"
                add(at+step*beat,voice(note,beat*.78,kind),.072 if kind=="lead" else .065,.2)
                if depth>0 and step%2==0:
                    add(at+step*beat+beat*.3,voice(note-12,beat*.45,"bell"),.028,-.6)
        if bar%8 in [6,7]:
            for step in [0,1.5,3]:
                add(at+step*beat,voice(key+24+refrain[(bar*4+int(step))%32],beat*.8,"bell"),.08,-.25)
    # Short stereo echoes wrap into the start, preserving seamless authored loops.
    source = track.copy()
    for delay,gain in [(beat*.75,.14),(beat*1.5,.07)]:
        track += np.roll(source,int(delay*RATE),axis=0)[:,::-1]*gain
    # Gentle saturation controls transients and leaves ample headroom for weapons.
    track = np.tanh(track*1.35)
    peak = float(np.max(np.abs(track)))
    track *= .75/max(peak,.01)
    pcm = (track*32767).astype("<i2")
    name = f"hollow_{map_index}_{depth}.wav"
    with wave.open(str(OUTPUT/name),"wb") as wav:
        wav.setnchannels(2);wav.setsampwidth(2);wav.setframerate(RATE);wav.writeframes(pcm.tobytes())
    return {"file":name,"bpm":bpm,"seconds":length,"map":map_index,"depth":depth,"peak":.75,
            "title":["Lanterns in the Lost Canopy","Witches over the Ivory Shelf","Clockwork of the Hollow Sky"][map_index]+f" / movement {depth+1}"}

if __name__ == "__main__":
    OUTPUT.mkdir(parents=True,exist_ok=True)
    scores = [build(m,d) for m in range(3) for d in range(3)]
    (OUTPUT/"hollow-harvest-score.json").write_text(json.dumps(scores,indent=2),encoding="utf8")
    # Pumpkin club: woody impact, wet rind crunch and quick seed rattles.
    rng = np.random.default_rng(31337)
    t = np.arange(int(RATE*.5))/RATE
    hit = .8*np.sin(2*np.pi*(58*t+36*(1-np.exp(-t*45))/45))*np.exp(-t*20)
    noise = rng.uniform(-1,1,len(t))
    hit += .34*noise*np.exp(-t*35)
    for delay in [.024,.048,.072,.101]:
        x = np.maximum(t-delay,0)
        hit += .13*noise*np.exp(-x*80)*(t>=delay)
    hit = np.tanh(hit*1.6)*.8
    with wave.open(str(OUTPUT/"pumpkin_smash.wav"),"wb") as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(RATE)
        wav.writeframes((hit*32767).astype("<i2").tobytes())
    print("Generated nine original stereo Halloween score loops.")
