"""Generate cozy minimal sound effects for Paws & Paths using pure Python standard library.
"""
import math
import os
import struct
import wave

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        packed = bytearray()
        for s in samples:
            # Clamp between -1.0 and 1.0
            clamped = max(-1.0, min(1.0, s))
            int_val = int(clamped * 32767.0)
            packed.extend(struct.pack('<h', int_val))
        wav_file.writeframes(packed)
    print(f"Generated: {filename} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.3f}s)")

def make_wood_click():
    # Warm marimba / wooden block knock
    duration = 0.09
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    freq = 460.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 65.0)
        # Fundamental + woody overtone + short attack thud
        val = 0.7 * math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(2.0 * math.pi * (freq * 2.3) * t)
        if t < 0.008:
            val += 0.4 * (1.0 - t / 0.008) * (math.sin(2.0 * math.pi * 120.0 * t))
        samples.append(val * env * 0.8)
    return samples

def make_cross_tap():
    # Soft chalk / quiet cross tap
    duration = 0.05
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    freq = 720.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 90.0)
        val = math.sin(2.0 * math.pi * freq * t)
        samples.append(val * env * 0.45)
    return samples

def make_chime():
    # Gentle wind chime when clue is satisfied (E5 + G5 harmonic)
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 10.0)
        val = 0.5 * math.sin(2.0 * math.pi * 659.25 * t) + \
              0.35 * math.sin(2.0 * math.pi * 783.99 * t) + \
              0.15 * math.sin(2.0 * math.pi * 1318.5 * t)
        samples.append(val * env * 0.65)
    return samples

def make_victory():
    # Joyful harp / glockenspiel arpeggio (C5 - E5 - G5 - C6)
    duration = 1.1
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    notes = [
        (0.00, 523.25),  # C5
        (0.12, 659.25),  # E5
        (0.24, 783.99),  # G5
        (0.36, 1046.50), # C6
        (0.48, 1318.51)  # E6
    ]
    for start_t, freq in notes:
        start_idx = int(start_t * SAMPLE_RATE)
        note_len = int(0.55 * SAMPLE_RATE)
        for j in range(note_len):
            idx = start_idx + j
            if idx >= num_samples:
                break
            t = j / SAMPLE_RATE
            env = math.exp(-t * 7.0)
            val = (0.6 * math.sin(2.0 * math.pi * freq * t) +
                   0.3 * math.sin(2.0 * math.pi * (freq * 2.0) * t) +
                   0.1 * math.sin(2.0 * math.pi * (freq * 3.0) * t)) * env * 0.35
            samples[idx] += val
    return samples

def make_button_pop():
    # Cozy UI bubble pop
    duration = 0.06
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 380.0 + (t / duration) * 320.0
        env = math.sin(math.pi * (t / duration)) ** 1.5
        val = math.sin(2.0 * math.pi * freq * t)
        samples.append(val * env * 0.6)
    return samples

if __name__ == '__main__':
    dest = os.path.join(os.path.dirname(__file__), '..', 'Nonogram', 'Resources', 'Sounds')
    write_wav(os.path.join(dest, 'sfx_tile_click.wav'), make_wood_click())
    write_wav(os.path.join(dest, 'sfx_cross.wav'), make_cross_tap())
    write_wav(os.path.join(dest, 'sfx_clue_chime.wav'), make_chime())
    write_wav(os.path.join(dest, 'sfx_victory.wav'), make_victory())
    write_wav(os.path.join(dest, 'sfx_button.wav'), make_button_pop())
