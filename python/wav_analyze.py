import wave
import sys
import os

def count_pcm16_samples(file_path):
    if not os.path.isfile(file_path):
        print("File does not exist")
        return

    with wave.open(file_path, 'rb') as wav:
        sample_width = wav.getsampwidth()
        if sample_width != 2:
            print("Not a PCM16 file")
            return

        num_frames = wav.getnframes()
        num_channels = wav.getnchannels()
        total_samples = num_frames * num_channels

        print("Channel: " + str(num_channels))
        print("Samples: " + str(total_samples))
        print("Bytes:   " + str(total_samples * 2))
        print("By / Ch: " + str(total_samples))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <file.wav>")
    else:
        count_pcm16_samples(sys.argv[1])
