import matplotlib.pyplot as plt
import numpy as np
import argparse
import os
import glob
import sounddevice as sd
import threading
from matplotlib.widgets import Button, CheckButtons

def parse_args():
    parser = argparse.ArgumentParser(
        description="Visualize and play multiple stereo PCM16 files with channel selection"
    )

    parser.add_argument(
        "-f", "--files",
        type=str,
        nargs="*",
        help="List of PCM files to visualize"
    )

    parser.add_argument(
        "-d", "--directory",
        type=str,
        help="Directory containing PCM files"
    )

    parser.add_argument(
        "--samplerate",
        type=int,
        default=48000,
        help="Sample rate of PCM data (default: 48000)"
    )

    return parser.parse_args()

def get_pcm_files(files, directory):
    if directory:
        if not os.path.isdir(directory):
            raise NotADirectoryError(f"{directory} is not a valid directory")
        files_in_dir = sorted(glob.glob(os.path.join(directory, "*.raw")))
        if not files_in_dir:
            raise FileNotFoundError(f"No .raw files found in directory {directory}")
        return files_in_dir
    if files:
        for f in files:
            if not os.path.exists(f):
                raise FileNotFoundError(f"File not found: {f}")
        return files
    raise ValueError("Either --files or --directory must be provided")

def load_samples(file_list):
    channel_data = []

    for f in file_list:
        raw = np.fromfile(f, dtype=np.int16)
        stereo = raw.reshape(-1, 2)
        channel_data.append(stereo[:, 0])
        channel_data.append(stereo[:, 1])

    min_len = min(len(ch) for ch in channel_data)
    trimmed = [ch[:min_len] for ch in channel_data]
    stacked = np.stack(trimmed, axis=-1)

    return stacked

args = parse_args()
file_list = get_pcm_files(args.files, args.directory)
samplerate = args.samplerate

samples = load_samples(file_list)
normalized = samples.astype(np.float32) / 32768.0

channel_labels = []
for f in file_list:
    base = os.path.basename(f)
    channel_labels.append(f"{base} (L)")
    channel_labels.append(f"{base} (R)")

channel_states = [i < 2 for i in range(len(channel_labels))]

height_per_channel = 2
max_height = 10
fig_height = min(height_per_channel * len(channel_labels), max_height)
fig, axes = plt.subplots(len(channel_labels), 1, figsize=(12, fig_height), sharex=True)

if len(channel_labels) == 1:
    axes = [axes]

for idx, (ax, label) in enumerate(zip(axes, channel_labels)):
    ax.plot(normalized[:, idx], label=label)
    ax.set_ylabel("Amplitude")
    ax.grid(True)
    ax.legend(loc="upper right")

axes[-1].set_xlabel("Sample Index")
fig.suptitle("Stereo PCM16 Waveforms per Channel", fontsize=14)
plt.subplots_adjust(left=0.40, right=0.95, top=0.92, bottom=0.1)

checkbox_ax = fig.add_axes([0.03, 0.3, 0.25, 0.6])
checkbox = CheckButtons(checkbox_ax, labels=channel_labels, actives=channel_states)

def checkbox_handler(label):
    idx = channel_labels.index(label)
    channel_states[idx] = not channel_states[idx]

checkbox.on_clicked(checkbox_handler)

button_ax = fig.add_axes([0.4, 0.01, 0.2, 0.05])
button = Button(button_ax, "Play Selected Channels")

def play_audio(event):
    def playback():
        selected_indices = [i for i, state in enumerate(channel_states) if state]

        if not selected_indices:
            print("No channels selected.")
            return

        selected_data = normalized[:, selected_indices]

        if selected_data.shape[1] > 2:
            left = np.mean(selected_data[:, ::2], axis=1)
            right = np.mean(selected_data[:, 1::2], axis=1)
            stereo = np.stack((left, right), axis=-1)
        elif selected_data.shape[1] == 1:
            stereo = np.repeat(selected_data, 2, axis=1)
        else:
            stereo = selected_data

        print(f"Playing audio with shape: {stereo.shape}")
        sd.play(stereo, samplerate=samplerate)
        sd.wait()

    threading.Thread(target=playback, daemon=True).start()

button.on_clicked(play_audio)
plt.show()
