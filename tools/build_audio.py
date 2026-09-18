#!/usr/bin/env python3
"""Render original seamless ambience so browser audio never depends on game frames."""
from array import array
from math import sin, cos, pi, exp
from pathlib import Path
import random
import wave

RATE = 22050
DURATION = 32
ROOT = Path(__file__).resolve().parents[1] / 'assets/audio'
ROOT.mkdir(parents=True, exist_ok=True)

def write(name, values):
    samples = array('h', (round(max(-1, min(1, x)) * 32767) for x in values))
    # Smoothly overlap the loop seam for noise and reverb tails.
    blend = RATE
    for i in range(blend):
        a = i / blend
        samples[len(samples)-blend+i] = round(samples[len(samples)-blend+i]*(1-a)+samples[i]*a)
    samples = samples[blend:]
    with wave.open(str(ROOT / (name+'.wav')), 'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE); f.writeframes(samples.tobytes())

notes = [261.63, 329.63, 392, 440, 392, 329.63, 293.66, 261.63,
         196, 261.63, 329.63, 293.66, 261.63, 196, 220, 293.66]
def music():
    for i in range(RATE*DURATION):
        t=i/RATE; value=0
        for k, frequency in enumerate(notes):
            age=(t-k*2) % DURATION
            if age < 7:
                envelope=(1-exp(-age*8))*exp(-age*.95)*(1-age/7)**2
                value += .075*envelope*(sin(2*pi*frequency*age)+.18*sin(4*pi*frequency*age))
        # Very soft, continuous low accompaniment.
        value += .009*sin(2*pi*130.8125*t)+.006*sin(2*pi*196*t)
        yield value

def nature(kind):
    rng=random.Random(248); low=0; softer=0
    for i in range(RATE*DURATION):
        t=i/RATE
        low += .014*(rng.uniform(-1,1)-low)
        softer += .005*(low-softer)
        value=softer*(.15 if kind=='rain' else .06)
        if kind=='day':
            for onset in (3, 3.45, 12, 12.4, 22, 23):
                age=t-onset
                if 0<age<.24:
                    value += .016*sin(pi*age/.24)**2*sin(2*pi*(1800*age+600*age*age))
        if kind=='night':
            pulse=max(0,sin(t*5))**10
            value+=.002*sin(2*pi*2400*t)*pulse
        yield value

write('garden_music',music())
for name in ('day','night','rain'): write(name,nature(name))
print('Rendered four original seamless garden audio loops')
