import matplotlib.pyplot as plt
import numpy as np
import argparse
import os
import glob
import sounddevice as sd
import threading
import time

from matplotlib.widgets import Button, CheckButtons

def parse_args():
    parser = argparse.ArgumentParser(
        description="Visualize and play multiple mono PCM16 files with channel selection"
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
    arrays = [np.fromfile(f, dtype=np.int16) for f in file_list]
    min_len = min(len(arr) for arr in arrays)
    trimmed = [arr[:min_len] for arr in arrays]
    stacked = np.stack(trimmed, axis=-1)
    return stacked

args = parse_args()
file_list = get_pcm_files(args.files, args.directory)
num_channels = len(file_list)
samplerate = args.samplerate

samples = load_samples(file_list)
normalized = samples.astype(np.float32) / 32768.0

channel_labels = [os.path.basename(f) for f in file_list]
channel_states = [i < 2 for i in range(num_channels)]

height_per_channel = 2
max_height = 10
fig_height = min(height_per_channel * num_channels, max_height)

fig, axes = plt.subplots(num_channels, 1, figsize=(12, fig_height), sharex=True)
if num_channels == 1:
    axes = [axes]

for idx, (ax, label) in enumerate(zip(axes, channel_labels)):
    ax.plot(normalized[:, idx], label=label)
    ax.set_ylabel("Amplitude")
    ax.grid(True)
    ax.legend(loc="upper right")

axes[-1].set_xlabel("Sample Index")
fig.suptitle("PCM16 Waveforms per Channel", fontsize=14)

plt.subplots_adjust(left=0.40, right=0.95, top=0.92, bottom=0.1)

checkbox_ax = fig.add_axes([0.03, 0.3, 0.25, 0.6])
checkbox = CheckButtons(checkbox_ax, labels=channel_labels, actives=channel_states)

def checkbox_handler(label):
    idx = channel_labels.index(label)
    channel_states[idx] = not channel_states[idx]

checkbox.on_clicked(checkbox_handler)

button_ax = fig.add_axes([0.4, 0.01, 0.2, 0.05])
button = Button(button_ax, "Play Selected Channels")

# Create playback position lines (one per axis)
playback_lines = [ax.axvline(x=0, color='red', linewidth=1, visible=False) for ax in axes]

# Playback state
playback_start_time = None
playback_active = False

def update_playback_position(frame):
    global playback_active, playback_start_time
    
    if playback_active and playback_start_time is not None:
        elapsed = time.time() - playback_start_time
        current_sample = int(elapsed * samplerate)
        
        if current_sample >= len(normalized):
            # Playback finished
            playback_active = False
            for line in playback_lines:
                line.set_visible(False)
        else:
            for line in playback_lines:
                line.set_xdata([current_sample, current_sample])
                line.set_visible(True)
    
    return playback_lines

# Use animation for smooth updates
from matplotlib.animation import FuncAnimation
ani = FuncAnimation(fig, update_playback_position, interval=50, blit=True, cache_frame_data=False)

def play_audio(event):
    global playback_start_time, playback_active
    
    def playback():
        global playback_start_time, playback_active
        
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
        
        playback_start_time = time.time()
        playback_active = True
        
        sd.play(stereo, samplerate=samplerate)
        sd.wait()
        
        playback_active = False

    threading.Thread(target=playback, daemon=True).start()

button.on_clicked(play_audio)

plt.show()