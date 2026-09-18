"""Make tiny original signal sounds for the greybox; no external audio assets."""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RNG = random.Random(504)


def write_sound(name, seconds, sample):
    OUT.mkdir(parents=True, exist_ok=True)
    frames = bytearray()
    for index in range(int(RATE * seconds)):
        moment = index / RATE
        value = max(-1.0, min(1.0, sample(moment, seconds)))
        frames += struct.pack("<h", int(value * 24000))
    with wave.open(str(OUT / name), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(RATE)
        sound.writeframes(frames)


def attach(t, length):
    envelope = (1 - t / length) ** 3
    return envelope * (0.55 * math.sin(2 * math.pi * (620 * t - 900 * t * t)) + 0.13 * RNG.uniform(-1, 1))


def release(t, length):
    envelope = math.sin(math.pi * t / length) ** 1.5
    return envelope * (0.28 * RNG.uniform(-1, 1) + 0.18 * math.sin(2 * math.pi * (290 * t + 1100 * t * t)))


def landing(t, length):
    envelope = (1 - t / length) ** 4
    return envelope * (0.65 * math.sin(2 * math.pi * (125 * t - 80 * t * t)) + 0.15 * RNG.uniform(-1, 1))


if __name__ == "__main__":
    write_sound("attach.wav", 0.11, attach)
    write_sound("release.wav", 0.20, release)
    write_sound("land.wav", 0.14, landing)
