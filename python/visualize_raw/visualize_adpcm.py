import numpy as np
import matplotlib.pyplot as plt
import argparse

INDEX_TABLE = [
    -1, -1, -1, -1, 2, 4, 6, 8,
    -1, -1, -1, -1, 2, 4, 6, 8
]

STEP_TABLE = [
     7, 8, 9, 10, 11, 12, 13, 14, 16, 17,
    19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
    50, 55, 60, 66, 73, 80, 88, 97, 107, 118,
    130, 143, 157, 173, 190, 209, 230, 253, 279, 307,
    337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
    876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066,
    2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358,
    5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635,
    13899, 15289, 16818, 18500, 20350, 22385, 24623, 27086,
    29794, 32767
]

def decode_mono_ima_adpcm_block(block: bytes):
    if len(block) < 4:
        raise ValueError("Block too small for mono ADPCM")
    predictor = int.from_bytes(block[0:2], 'little', signed=True)

    index = block[2]
    if index >= len(STEP_TABLE):
        raise ValueError(f"Invalid step index {index} in block header")

    step = STEP_TABLE[index]
    out = [predictor]
    data = block[4:]
    for byte in data:
        for nibble in (byte & 0x0F, byte >> 4):
            diff = step >> 3
            if nibble & 1:
                diff += step >> 2
            if nibble & 2:
                diff += step >> 1
            if nibble & 4:
                diff += step
            if nibble & 8:
                predictor -= diff
            else:
                predictor += diff
            predictor = max(-32768, min(32767, predictor))
            index = max(0, min(88, index + INDEX_TABLE[nibble]))
            step = STEP_TABLE[index]
            out.append(predictor)
    return out

def decode_stereo_ima_adpcm_block(block: bytes):
    if len(block) < 8:
        raise ValueError("Block too small for stereo ADPCM")
    # Parse headers for each channel
    pred_l = int.from_bytes(block[0:2], 'little', signed=True)
    idx_l = block[2]
    pred_r = int.from_bytes(block[4:6], 'little', signed=True)
    idx_r = block[6]
    step_l = STEP_TABLE[idx_l]
    step_r = STEP_TABLE[idx_r]
    out_l = [pred_l]
    out_r = [pred_r]
    data = block[8:]
    for byte in data:
        nibble_l = byte & 0x0F
        nibble_r = byte >> 4
        # Decode left channel
        diff = step_l >> 3
        if nibble_l & 1: diff += step_l >> 2
        if nibble_l & 2: diff += step_l >> 1
        if nibble_l & 4: diff += step_l
        pred_l += -diff if nibble_l & 8 else diff
        pred_l = max(-32768, min(32767, pred_l))
        idx_l = max(0, min(88, idx_l + INDEX_TABLE[nibble_l]))
        step_l = STEP_TABLE[idx_l]
        out_l.append(pred_l)
        # Decode right channel
        diff = step_r >> 3
        if nibble_r & 1: diff += step_r >> 2
        if nibble_r & 2: diff += step_r >> 1
        if nibble_r & 4: diff += step_r
        pred_r += -diff if nibble_r & 8 else diff
        pred_r = max(-32768, min(32767, pred_r))
        idx_r = max(0, min(88, idx_r + INDEX_TABLE[nibble_r]))
        step_r = STEP_TABLE[idx_r]
        out_r.append(pred_r)
    return out_l, out_r

def parse_args():
    parser = argparse.ArgumentParser(
        description="Decode and visualize IMA ADPCM data (mono or stereo)"
    )
    parser.add_argument(
        "-f", "--filename",
        type=str,
        default="samples.adpcm",
        help="Input ADPCM file (default: samples.adpcm)"
    )
    parser.add_argument(
        "-b", "--block-size",
        type=int,
        default=72,
        help="ADPCM block size in bytes (default: 72)"
    )
    parser.add_argument(
        "--offset",
        type=int,
        default=2048,
        help="Number of bytes to skip at the start of the file (default: 2048)"
    )
    parser.add_argument(
        "-c", "--channels",
        type=int,
        choices=[1, 2],
        default=2,
        help="Number of channels: 1 (mono) or 2 (stereo); default is 2"
    )
    return parser.parse_args()

# Main
args = parse_args()
filename = args.filename
block_size = args.block_size
channels = args.channels

with open(filename, "rb") as f:
    f.seek(args.offset)
    data = f.read()

samples = []
if channels == 2:
    samples_l = []
    samples_r = []
    for i in range(0, len(data), block_size):
        block = data[i:i+block_size]
        # Skip blocks that are too short
        if len(block) < block_size:
            continue
        l, r = decode_stereo_ima_adpcm_block(block)
        samples_l.extend(l)
        samples_r.extend(r)
    # Plot the left channel for visualization
    plt.figure(figsize=(10, 5))
    plt.plot(samples_l, label="Left Channel", alpha=0.75)
    plt.plot(samples_r, label="Right Channel", alpha=0.75)
    plt.title("Decoded Stereo IMA ADPCM Waveform")
    plt.xlabel("Sample Index")
    plt.ylabel("Amplitude")
    plt.legend()
    plt.grid(True)
else:
    samples_mono = []
    for i in range(0, len(data), block_size):
        block = data[i:i+block_size]
        if len(block) < block_size:
            continue

        try:
            decoded = decode_mono_ima_adpcm_block(block)
            samples_mono.extend(decoded)
        except ValueError as e:
            print(f"Skipping block at offset {i}: {e}")

    plt.figure(figsize=(10, 5))
    plt.plot(samples_mono, label="Mono", alpha=0.75)
    plt.title("Decoded Mono IMA ADPCM Waveform")
    plt.xlabel("Sample Index")
    plt.ylabel("Amplitude")
    plt.legend()
    plt.grid(True)

plt.tight_layout()
plt.show()

