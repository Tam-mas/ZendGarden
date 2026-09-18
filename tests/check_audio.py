#!/usr/bin/env python3
"""Check loop seams, levels, and import settings for browser-safe ambience."""
from array import array
from pathlib import Path
import wave
root = Path(__file__).resolve().parents[1]
for name in ('garden_music', 'day', 'night', 'rain'):
    path = root / 'assets/audio' / (name + '.wav')
    with wave.open(str(path)) as audio:
        assert audio.getsampwidth() == 2 and audio.getnchannels() == 1
        assert audio.getnframes() >= audio.getframerate() * 30
        samples = array('h', audio.readframes(audio.getnframes()))
    assert 0 < max(abs(x) for x in samples) < 16000, f'{name}: silence or clipping risk'
    assert abs(samples[0] - samples[-1]) < 100, f'{name}: discontinuous loop seam'
    assert max(abs(a-b) for a,b in zip(samples,samples[1:])) < 1000, f'{name}: sharp audio impulse'
    settings = path.with_suffix('.wav.import').read_text()
    assert 'edit/loop_mode=2' in settings, f'{name}: browser loop missing at import'
    assert 'compress/mode=0' in settings, f'{name}: keep source PCM fidelity'
print('AUDIO_CHECK: PASS — four looping tracks, quiet levels, smooth seams, no sharp impulses')
