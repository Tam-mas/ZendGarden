"""Original quiet D/E/A wind-chime one-shot, in the garden's tonal palette."""
from array import array
from pathlib import Path
from math import sin, pi, exp
import wave

def build():
    rate=22050
    samples=array('h')
    for k in range(rate*6):
        t=k/rate;value=0
        for onset,hz,strength in [(0,587.3295,.045),(.43,659.2551,.035),(.94,880,.03)]:
            u=t-onset
            if u<=0:continue
            envelope=(1-exp(-u*32))*exp(-u*1.6)*min(1,max(0,(6-t)/.25))
            value+=strength*envelope*(sin(2*pi*hz*u)+.10*sin(4*pi*hz*u)+.035*sin(6*pi*hz*u))
        samples.append(round(value*32767))
    path=Path(__file__).resolve().parents[1]/'assets/audio/alpine_chime.wav'
    with wave.open(str(path),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate);out.writeframes(samples.tobytes())
    return path

if __name__=='__main__':print(build())
