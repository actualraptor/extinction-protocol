"""Project-local Windows MIDI/SoundFont renderer. No global installs required."""
from pathlib import Path
import sys, argparse, subprocess, json, wave
import numpy as np
import imageio_ffmpeg
ROOT=Path(__file__).resolve().parents[2]
TOOLS=ROOT/'tools/music'
sys.path.insert(0,str(TOOLS/'python-packages'))
import mido
ENGINE=TOOLS/'fluidsynth/fluidsynth-v2.6.1-win10-x64-cpp11/bin/fluidsynth.exe'
FONT=TOOLS/'GeneralUser-GS.sf2'

def render(source,target):
    assert ENGINE.is_file() and FONT.is_file(), 'Missing local MIDI renderer or SoundFont'
    target.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run([str(ENGINE),'-ni','-g','0.6','-r','44100','-o','synth.chorus.active=0','-F',str(target),str(FONT),str(source)],check=True)
    with wave.open(str(target),'rb') as wav:
        channels=wav.getnchannels();rate=wav.getframerate()
        samples=np.frombuffer(wav.readframes(wav.getnframes()),'<i2').reshape(-1,channels)/32768
    # FluidSynth can append a long silent timeout after the last MIDI event.
    samples=samples[:round((mido.MidiFile(str(source)).length+3.0)*rate)]
    with wave.open(str(target),'wb') as wav:
        wav.setnchannels(channels);wav.setsampwidth(2);wav.setframerate(rate)
        wav.writeframes((samples*32768).astype('<i2').tobytes())
    assert channels==2 and rate==44100 and np.max(abs(samples))>.001
    assert np.max(abs(samples))<.999, 'Clipping in rendered mix; lower gain or MIDI velocities'
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-i',str(target),'-c:a','libmp3lame','-b:a','256k',str(target.with_suffix('.mp3'))],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    return {'sample_rate':rate,'channels':channels,'seconds':len(samples)/rate,'peak_dbfs':float(20*np.log10(np.max(abs(samples)))),'midi':str(source),'wav':str(target)}

def audition():
    out=ROOT/'native/build/music-review';out.mkdir(parents=True,exist_ok=True)
    midi=mido.MidiFile(ticks_per_beat=480)
    meta=mido.MidiTrack();midi.tracks.append(meta)
    meta.append(mido.MetaMessage('set_tempo',tempo=mido.bpm2tempo(120)))
    for channel,program,notes,start,velocity in [(0,75,[62,69,65,63,62],0,75),(1,42,[50,53,57],10,57),(2,32,[38,38,45,38],16,72),(9,0,[41,45,50,76,41,45],22,85)]:
        track=mido.MidiTrack();midi.tracks.append(track)
        if channel!=9:track.append(mido.Message('program_change',channel=channel,program=program))
        track.append(mido.Message('control_change',channel=channel,control=7,value=100))
        track.append(mido.Message('control_change',channel=channel,control=91,value=22))
        for i,note in enumerate(notes):
            track.append(mido.Message('note_on',channel=channel,note=note,velocity=velocity,time=start*480 if i==0 else 120))
            track.append(mido.Message('note_off',channel=channel,note=note,velocity=0,time=360))
    source=out/'Sampled-Instrument-Setup-Check.mid';midi.save(source)
    report=render(source,out/'Sampled-Instrument-Setup-Check.wav')
    (out/'sampled-renderer-check.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');parser.add_argument('--test',action='store_true');parser.add_argument('midi',nargs='?');parser.add_argument('wav',nargs='?');args=parser.parse_args()
    if args.check:
        assert ENGINE.is_file() and FONT.is_file()
        subprocess.run([str(ENGINE),'--version'],check=True)
        print('MIDI library, portable renderer, sampled soundbank and MP3 encoder available')
    elif args.test:audition()
    elif args.midi and args.wav:print(render(Path(args.midi).resolve(),Path(args.wav).resolve()))
    else:parser.error('Use --check, --test, or input.mid output.wav')
