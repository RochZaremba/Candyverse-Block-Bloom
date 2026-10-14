"""Original Candyverse SFX, reproducible PCM synthesis; no external samples."""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
CUES = {'place': [(660, 0), (990, .025)],
        'clear': [(523.25, 0), (659.25, .065), (783.99, .13)],
        'upgrade': [(659.25, 0), (783.99, .085), (1046.5, .17)]}
for name, notes in CUES.items():
    duration = max(start for _, start in notes) + .18
    samples = []
    for i in range(int(duration * RATE)):
        t = i / RATE
        value = 0
        for frequency, start in notes:
            age = t - start
            if 0 <= age < .18:
                envelope = min(age / .006, 1) * (1 - age / .18) ** 3
                value += .20 * envelope * (math.sin(2 * math.pi * frequency * age) + .2 * math.sin(4 * math.pi * frequency * age))
        samples.append(struct.pack('<h', int(max(-1, min(1, value)) * 32767)))
    path = Path('assets/audio') / f'{name}.wav'
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b''.join(samples))
