from pathlib import Path
import subprocess
import imageio_ffmpeg
import numpy as np

root = Path(__file__).resolve().parents[1]
movie = root / 'build/minion-remake-review/Individual-Minions-Ritual-v6.mp4'
reader = imageio_ffmpeg.read_frames(str(movie), pix_fmt='rgb24')
meta = next(reader)
width, height = meta['size']
largest = 0
count = 0
for frame in reader:
    rgb = np.frombuffer(frame, np.uint8).reshape(height, width, 3)
    white = ((rgb[:,:,0]>245)&(rgb[:,:,1]>245)&(rgb[:,:,2]>245)).sum()
    largest = max(largest, int(white))
    assert white < 3000, f'Opaque white region in frame {count}: {white} pixels'
    count += 1
print(f'WHITE-BOX CHECK: {count} frames, maximum {largest} near-white pixels; no opaque rectangle')
subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-y', '-ss', '8.3', '-i', str(movie), '-frames:v', '1', str(movie.with_name('Ritual-Fog-Review-v6.png'))], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
