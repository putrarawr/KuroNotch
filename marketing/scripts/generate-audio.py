#!/usr/bin/env python3
"""
generate-audio.py
Synthesizes crisp sound effects (SFX) and background music loop for Kuro Island marketing video.
Uses only Python standard libraries (wave, math, struct, random).
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'w') as wf:
        wf.setnchannels(1)  # Mono
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(SAMPLE_RATE)
        # Clamp samples to [-1.0, 1.0] and convert to 16-bit signed integer
        data = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            ival = int(clamped * 32767.0)
            data.extend(struct.pack('<h', ival))
        wf.writeframes(data)
    print(f"Generated: {filename} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

def generate_chime():
    # Ascending harmonious chime: C5 (523.25), E5 (659.25), G5 (783.99), C6 (1046.5)
    notes = [523.25, 659.25, 783.99, 1046.5]
    duration = 1.4
    total_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * total_samples
    
    note_delay = 0.08  # delay between note starts in seconds
    for i, freq in enumerate(notes):
        start_sample = int(i * note_delay * SAMPLE_RATE)
        for t in range(total_samples - start_sample):
            cur = start_sample + t
            time_sec = t / SAMPLE_RATE
            # Envelope: fast attack (5ms), exponential decay
            attack = min(1.0, time_sec / 0.005)
            decay = math.exp(-3.5 * time_sec)
            env = attack * decay
            # Fundamental + soft harmonics
            sine = (
                math.sin(2.0 * math.pi * freq * time_sec) * 0.7 +
                math.sin(2.0 * math.pi * freq * 2.0 * time_sec) * 0.2 +
                math.sin(2.0 * math.pi * freq * 3.0 * time_sec) * 0.1
            )
            samples[cur] += sine * env * 0.35

    # Normalize
    max_val = max(abs(s) for s in samples) or 1.0
    return [s / max_val * 0.85 for s in samples]

def generate_pop():
    # Organic bubble pop: pitch drops from 700Hz to 180Hz over 90ms
    duration = 0.12
    total_samples = int(duration * SAMPLE_RATE)
    samples = []
    phase = 0.0
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        # Frequency sweep
        freq = 750.0 * (1.0 - progress * 0.75)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        # Envelope: punchy peak at 10ms, decay
        env = math.exp(-35.0 * t) if t > 0.008 else (t / 0.008)
        val = math.sin(phase) * env
        # Add slight resonant body
        val += math.sin(phase * 0.5) * env * 0.3
        samples.append(val * 0.9)
    return samples

def generate_click():
    # Tactile mechanical click: 25ms impulse + sharp snap
    duration = 0.04
    total_samples = int(duration * SAMPLE_RATE)
    samples = []
    random.seed(42)
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-120.0 * t)
        noise = (random.random() * 2.0 - 1.0) * 0.4
        tone = math.sin(2.0 * math.pi * 1800.0 * t) * 0.6
        samples.append((tone + noise) * env * 0.85)
    return samples

def generate_whoosh():
    # Smooth airy whoosh transition: 0.45s shaped white noise
    duration = 0.45
    total_samples = int(duration * SAMPLE_RATE)
    samples = []
    random.seed(1337)
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        progress = t / duration
        # Gaussian-like bell curve envelope for whoosh swell
        env = math.exp(-((progress - 0.4) ** 2) / 0.035)
        # Swept noise tone
        sweep_freq = 300.0 + 800.0 * math.sin(progress * math.pi)
        noise = (random.random() * 2.0 - 1.0)
        tone = math.sin(2.0 * math.pi * sweep_freq * t)
        samples.append((noise * 0.65 + tone * 0.35) * env * 0.75)
    return samples

def generate_lofi_beat():
    # Upbeat lo-fi groove: 120 BPM (2 beats/sec, 0.5s per beat, 2s per 4/4 bar).
    # 4 bars = 8.0s seamless loop.
    bpm = 120
    beat_dur = 60.0 / bpm
    bar_dur = beat_dur * 4.0
    total_duration = bar_dur * 4.0  # 8.0 seconds total loop
    total_samples = int(total_duration * SAMPLE_RATE)
    samples = [0.0] * total_samples

    # Chord progression: Dm7 (D4, F4, A4, C5), G7 (G3, B3, D4, F4), Cmaj7 (C4, E4, G4, B4), Am7 (A3, C4, E4, G4)
    chords = [
        [293.66, 349.23, 440.00, 523.25], # Dm7
        [196.00, 246.94, 293.66, 349.23], # G7
        [261.63, 329.63, 392.00, 493.88], # Cmaj7
        [220.00, 261.63, 329.63, 392.00]  # Am7
    ]

    for bar_idx, chord in enumerate(chords):
        bar_start = bar_idx * bar_dur
        # Electric piano Rhodes chord strum
        for note_idx, freq in enumerate(chord):
            strum_delay = note_idx * 0.02
            note_start_sample = int((bar_start + strum_delay) * SAMPLE_RATE)
            chord_len = int((bar_dur - strum_delay) * SAMPLE_RATE)
            for t_samp in range(chord_len):
                idx = note_start_sample + t_samp
                if idx >= total_samples:
                    break
                t_sec = t_samp / SAMPLE_RATE
                env = math.exp(-1.4 * t_sec) * min(1.0, t_sec / 0.01)
                # Rhodes-like harmonics
                sound = (
                    math.sin(2.0 * math.pi * freq * t_sec) * 0.5 +
                    math.sin(2.0 * math.pi * freq * 2.0 * t_sec) * 0.25 +
                    math.sin(2.0 * math.pi * freq * 3.0 * t_sec) * 0.1
                )
                samples[idx] += sound * env * 0.18

    # Drum Pattern for each bar (Kick on beat 1, beat 2.5; Snare on beat 2, beat 4; Hi-hat on every 8th note)
    for bar_idx in range(4):
        bar_start = bar_idx * bar_dur
        # Hi-Hats every 0.25s (8th notes)
        for step in range(8):
            hat_time = bar_start + step * (beat_dur / 2.0)
            hat_start = int(hat_time * SAMPLE_RATE)
            for s in range(int(0.04 * SAMPLE_RATE)):
                idx = hat_start + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-90.0 * t)
                noise = (random.random() * 2.0 - 1.0)
                samples[idx] += noise * env * (0.09 if step % 2 == 0 else 0.05)

        # Kick on 1 and 2.5
        for kick_beat in [0.0, 1.5, 2.75]:
            kick_time = bar_start + kick_beat * beat_dur
            k_start = int(kick_time * SAMPLE_RATE)
            for s in range(int(0.18 * SAMPLE_RATE)):
                idx = k_start + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                f = 130.0 * math.exp(-25.0 * t) + 45.0
                env = math.exp(-12.0 * t)
                samples[idx] += math.sin(2.0 * math.pi * f * t) * env * 0.32

        # Snare on 2 and 4
        for snare_beat in [1.0, 3.0]:
            snare_time = bar_start + snare_beat * beat_dur
            sn_start = int(snare_time * SAMPLE_RATE)
            for s in range(int(0.14 * SAMPLE_RATE)):
                idx = sn_start + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-25.0 * t)
                noise = (random.random() * 2.0 - 1.0) * 0.6
                body = math.sin(2.0 * math.pi * 210.0 * t) * 0.4
                samples[idx] += (noise + body) * env * 0.22

    # Bassline (deep sine)
    bass_notes = [146.83, 98.00, 130.81, 110.00] # D3, G2, C3, A2
    for bar_idx, b_freq in enumerate(bass_notes):
        bar_start = bar_idx * bar_dur
        for b_beat in [0.0, 1.5, 2.5]:
            b_time = bar_start + b_beat * beat_dur
            b_start = int(b_time * SAMPLE_RATE)
            for s in range(int(0.4 * SAMPLE_RATE)):
                idx = b_start + s
                if idx >= total_samples:
                    break
                t = s / SAMPLE_RATE
                env = math.exp(-5.0 * t) * min(1.0, t / 0.01)
                samples[idx] += math.sin(2.0 * math.pi * b_freq * t) * env * 0.25

    # Normalize entire track nicely
    max_val = max(abs(s) for s in samples) or 1.0
    return [s / max_val * 0.78 for s in samples]

def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "public", "audio")
    os.makedirs(out_dir, exist_ok=True)
    
    print("Generating sound effects & lo-fi beat...")
    write_wav(os.path.join(out_dir, "chime.wav"), generate_chime())
    write_wav(os.path.join(out_dir, "pop.wav"), generate_pop())
    write_wav(os.path.join(out_dir, "click.wav"), generate_click())
    write_wav(os.path.join(out_dir, "whoosh.wav"), generate_whoosh())
    write_wav(os.path.join(out_dir, "beat.wav"), generate_lofi_beat())
    print("Audio assets generated successfully!")

if __name__ == "__main__":
    main()
