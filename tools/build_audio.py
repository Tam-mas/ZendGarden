#!/usr/bin/env python3
"""Render original, softly voiced loops using only the Python standard library.

All four themes share D/E/G/A/B at A4=440 Hz. Notes and their room tails
wrap onto a 64-second timeline, preserving both tuning and phrase length.
"""
from array import array
from math import sin, cos, pi, exp
from pathlib import Path
import random
import wave

RATE = 22050
MUSIC_DURATION = 64
NATURE_DURATION = 32
ROOT = Path(__file__).resolve().parents[1] / 'assets/audio'
MUSIC_NAMES = ('garden_music', 'water_music', 'woodland_music', 'terrace_music')
NATURE_NAMES = ('day', 'night', 'rain', 'bath_birds', 'waterside', 'woodland')
# MIDI pitches: a suspended pentatonic palette, with no competing major/minor thirds.
PALETTE = (50, 52, 55, 57, 59, 62, 64, 67, 69, 71)
# Onset seconds, MIDI pitch, relative strength. Each theme has its own phrasing.
SCORES = (
    ((2, 62, 1), (6, 64, .70), (10, 69, .65), (17, 67, .85),
     (23, 64, .65), (28, 62, .80), (35, 59, .70), (41, 62, .80),
     (46, 64, .65), (52, 57, .75), (58, 62, .65)),
    ((3, 57, 1), (8, 62, .75), (14, 64, .70), (21, 59, .80),
     (27, 57, .60), (34, 55, .85), (40, 59, .70), (47, 62, .75),
     (54, 64, .60), (60, 57, .65)),
    ((4, 55, .85), (12, 57, .70), (22, 62, .75), (32, 59, .80),
     (42, 57, .65), (53, 55, .80)),
    ((1, 62, .80), (11, 69, .65), (23, 67, .75),
     (35, 64, .70), (46, 59, .70), (57, 62, .75)),
)
# Integer harmonics only: no detuned oscillators, metallic partials or pitch bends.
VOICES = (
    (.16, 1.8, 7.5, .34, (1, .12, .025)),  # Rounded felt-style keys.
    (.12, 2.0, 8.0, .42, (1, .20, .035)),  # Soft wooden/nylon plucks.
    (1.1, 2.2, 8.0, .08, (1, .055, .012)), # Airy, low flute-like swells.
    (1.8, 3.8, 13.0, .09, (1, .09, .015)), # Warm sustained tones.
)


def frequency(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def write(name, values):
    values = array('d', values)
    expected = RATE * (MUSIC_DURATION if name in MUSIC_NAMES else NATURE_DURATION)
    if len(values) != expected:
        raise ValueError(f'{name}: wrong loop length: {len(values)} != {expected}')
    if max(abs(x) for x in values) >= .25:
        raise ValueError(f'{name}: insufficient mix headroom')
    samples = array('h', (round(x * 32767) for x in values))
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(samples.tobytes())


def add_note(target, onset, midi, strength, profile):
    attack, release, duration, decay, partials = VOICES[profile]
    hz = frequency(midi)
    note = array('d')
    for i in range(round(duration * RATE)):
        age = i / RATE
        rise = .5 - .5 * cos(pi * min(1, age / attack))
        fall = .5 - .5 * cos(pi * min(1, (duration - age) / release))
        envelope = rise * fall * exp(-age * decay)
        if profile == 2:
            envelope *= .96 + .04 * sin(2 * pi * .7 * age)
        tone = sum(weight * sin(2 * pi * hz * (harmonic + 1) * age)
                   for harmonic, weight in enumerate(partials))
        note.append(.042 * strength * envelope * tone)
    # A small, dark room tail. Copy the waveform without changing its pitch.
    for delay, gain in ((0, 1), (.23, .13), (.47, .07), (.79, .035)):
        start = round((onset + delay) * RATE)
        for i, value in enumerate(note):
            target[(start + i) % len(target)] += value * gain


def music(profile=0):
    result = array('d', [0.0]) * (RATE * MUSIC_DURATION)
    # Very quiet D/A foundation. Quantize only these continuous oscillators to
    # a whole cycle count (<0.1 cent error), so the loop boundary stays continuous.
    for midi, level, phase in ((50, .0055, 0), (57, .0035, .9)):
        hz = round(frequency(midi) * MUSIC_DURATION) / MUSIC_DURATION
        for i in range(len(result)):
            t = i / RATE
            breath = .82 + .18 * cos(2 * pi * t / MUSIC_DURATION + phase)
            result[i] += level * breath * sin(2 * pi * hz * t)
    for onset, midi, strength in SCORES[profile]:
        add_note(result, onset, midi, strength, profile)
    return result


def noise_layer(target, rng, knot_rate, level):
    # Circular, smoothly interpolated noise: no seam splice or tonal water drone.
    count = round(NATURE_DURATION * knot_rate)
    knots = [rng.uniform(-1, 1) for _ in range(count)]
    for i in range(len(target)):
        pos = i * count / len(target)
        index = int(pos)
        blend = .5 - .5 * cos(pi * (pos - index))
        target[i] += level * (knots[index] * (1 - blend) + knots[(index + 1) % count] * blend)


def nature(kind):
    # Separate seeds/onsets avoid identical bird calls stacking across layers.
    rng = random.Random(248 + NATURE_NAMES.index(kind) * 97)
    result = array('d', [0.0]) * (RATE * NATURE_DURATION)
    level = {'day': .0012, 'night': .0008, 'rain': .011,
             'bath_birds': .0006, 'waterside': .006, 'woodland': .0025}[kind]
    for knot_rate, weight in ((90, .65), (430, .25), (1600, .10)):
        noise_layer(result, rng, knot_rate, level * weight)
    if kind in ('day', 'bath_birds', 'woodland'):
        onsets = {'day': (4, 4.5, 18, 25), 'bath_birds': (7, 7.4, 21, 21.6),
                  'woodland': (10, 10.6, 28)}[kind]
        for onset in onsets:
            duration = rng.uniform(.23, .34)
            hz = rng.uniform(1450, 1750)
            level = .014 if kind == 'bath_birds' else .006
            for i in range(round(duration * RATE)):
                age = i / RATE
                value = level * sin(pi * age / duration) ** 2
                value *= sin(2 * pi * (hz * age + 210 * age * age))
                result[(round(onset * RATE) + i) % len(result)] += value
    if kind == 'waterside':
        for i in range(len(result)):
            result[i] *= .78 + .22 * sin(2 * pi * 3 * i / len(result))
    if kind == 'night':
        # Low-level, rounded insect texture instead of a prominent repeating beep.
        for i in range(len(result)):
            t = i / RATE
            pulse = max(0, sin(2 * pi * 24 * t / NATURE_DURATION)) ** 6
            result[i] += .0007 * sin(2 * pi * 1600 * t) * pulse
    return result


def render_all():
    ROOT.mkdir(parents=True, exist_ok=True)
    for profile, name in enumerate(MUSIC_NAMES):
        write(name, music(profile))
        print(f'Rendered {name}: {MUSIC_DURATION}s', flush=True)
    for name in NATURE_NAMES:
        write(name, nature(name))
    print('Rendered ten original calm loops; exact phrase lengths and concert tuning')


if __name__ == '__main__':
    render_all()
