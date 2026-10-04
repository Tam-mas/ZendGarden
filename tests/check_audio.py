#!/usr/bin/env python3
"""Check loop seams, levels, and import settings for browser-safe ambience."""
from array import array
from math import cos, pi, sqrt, log10
from pathlib import Path
import importlib.util
import wave
root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('build_audio', root / 'tools/build_audio.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


def tone_power(samples, frequency, rate):
    """Windowed Goertzel power, to check the actual rendered fundamental."""
    coefficient = 2 * cos(2 * pi * frequency / rate)
    previous = earlier = 0.0
    for i, value in enumerate(samples):
        window = .5 - .5 * cos(2 * pi * i / (len(samples) - 1))
        current = value * window + coefficient * previous - earlier
        earlier, previous = previous, current
    return previous * previous + earlier * earlier - coefficient * previous * earlier


music_rms = []
for name in ('garden_music','water_music','woodland_music','terrace_music','day','night','rain','waterside','woodland','bath_birds'):
    path = root / 'assets/audio' / (name + '.wav')
    with wave.open(str(path)) as audio:
        assert audio.getsampwidth() == 2 and audio.getnchannels() == 1
        rate = audio.getframerate()
        expected_duration = builder.MUSIC_DURATION if name in builder.MUSIC_NAMES else builder.NATURE_DURATION
        assert audio.getnframes() == rate * expected_duration, f'{name}: phrase shortened at loop seam'
        samples = array('h', audio.readframes(audio.getnframes()))
    assert 0 < max(abs(x) for x in samples) < 16000, f'{name}: silence or clipping risk'
    assert abs(samples[0] - samples[-1]) < 100, f'{name}: discontinuous loop seam'
    assert max(abs(a-b) for a,b in zip(samples,samples[1:])) < 1000, f'{name}: sharp audio impulse'
    assert abs(sum(samples) / len(samples)) < 20, f'{name}: excessive DC offset'
    if name in builder.MUSIC_NAMES:
        profile = builder.MUSIC_NAMES.index(name)
        score = builder.SCORES[profile]
        assert all(note in builder.PALETTE for _, note, _ in score), f'{name}: incompatible pitch palette'
        assert min(b[0]-a[0] for a,b in zip(score,score[1:])) >= 4, f'{name}: crowded melody'
        onset, midi, _ = score[0]
        # The first exposed note must peak at its concert pitch, not a bent or
        # accidentally transposed frequency. Check PCM, not just score metadata.
        excerpt = samples[round((onset+1)*rate):round((onset+3)*rate)]
        hz = builder.frequency(midi)
        power = tone_power(excerpt,hz,rate)
        assert power > 2 * max(tone_power(excerpt,hz*.98,rate),tone_power(excerpt,hz*1.02,rate)), f'{name}: fundamental out of tune'
        rms = sqrt(sum((value/32768)**2 for value in samples) / len(samples))
        music_rms.append(20 * log10(rms))
        # A continuous low C is the old incompatible accompaniment.
        assert tone_power(samples,builder.frequency(50),rate) > 20 * tone_power(samples,builder.frequency(48),rate), f'{name}: wrong drone key'
    settings = path.with_suffix('.wav.import').read_text()
    assert 'edit/loop_mode=2' in settings, f'{name}: browser loop missing at import'
    expected_mode=2 if name in builder.MUSIC_NAMES or name=='rain' else 0
    assert f'compress/mode={expected_mode}' in settings, f'{name}: quality-preserving runtime compression policy changed'
assert max(music_rms)-min(music_rms)<3, 'Music changes noticeably in level between areas'
print('AUDIO_CHECK: PASS — ten exact-length loops, compatible concert pitches, balanced music, smooth seams, no sharp impulses')
