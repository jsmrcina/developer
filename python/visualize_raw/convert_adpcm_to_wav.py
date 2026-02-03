import argparse
import os
import struct
import subprocess
import sys
import tempfile

def parse_args():
    parser = argparse.ArgumentParser(description="Convert raw IMA ADPCM blocks to WAV")

    parser.add_argument("-i", "--inputfile", required=True, help="Input raw ADPCM file")
    parser.add_argument("-o", "--outputfile", default="output.wav", help="Output WAV file")
    parser.add_argument("-c", "--channels", type=int, choices=[1, 2], default=2, help="Number of channels (1=mono, 2=stereo)")
    parser.add_argument("-r", "--rate", type=int, default=44100, help="Sample rate (default: 44100)")
    parser.add_argument("--skip-bytes", type=int, default=0, help="Bytes to skip at the beginning of the file")
    parser.add_argument("--block-size", type=int, default=72, help="Block size in bytes (default: 72)")
    return parser.parse_args()

def make_wav_header(channels, sample_rate, block_align, num_blocks):
    samples_per_block = ((block_align - (4 * channels)) * 2) // channels + 1
    bits_per_sample = 4
    data_size = block_align * num_blocks
    byte_rate = (sample_rate * block_align) // samples_per_block
    fmt_chunk_size = 20
    riff_chunk_size = 4 + (8 + fmt_chunk_size) + (8 + data_size)

    header = b"RIFF"
    header += struct.pack("<I", riff_chunk_size)
    header += b"WAVE"

    header += b"fmt "
    header += struct.pack("<I", fmt_chunk_size)
    header += struct.pack("<H", 0x11)
    header += struct.pack("<H", channels)
    header += struct.pack("<I", sample_rate)
    header += struct.pack("<I", byte_rate)
    header += struct.pack("<H", block_align)
    header += struct.pack("<H", bits_per_sample)
    header += struct.pack("<H", 2)
    header += struct.pack("<H", samples_per_block)

    header += b"data"
    header += struct.pack("<I", data_size)

    return header

def decode_adpcm(input_path, output_path, skip_bytes, block_size, rate, channels):
    with open(input_path, "rb") as f:
        f.seek(skip_bytes)
        raw_data = f.read()

    if len(raw_data) % block_size != 0:
        print("Warning: raw data is not aligned to block size")

    num_blocks = len(raw_data) // block_size

    header = make_wav_header(channels, rate, block_size, num_blocks)

    wrapped_path = tempfile.NamedTemporaryFile(delete=False, suffix=".wav").name

    try:
        with open(wrapped_path, "wb") as f:
            f.write(header)
            f.write(raw_data)

        cmd = [
            "ffmpeg",
            "-y",
            "-i", wrapped_path,
            output_path
        ]

        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        if result.returncode != 0:
            print("FFmpeg failed:")
            print(result.stderr.decode())
            sys.exit(1)

    finally:
        try:
            os.unlink(wrapped_path)
        except Exception as e:
            print(f"Warning: failed to delete temp file: {e}")

def main():
    args = parse_args()

    decode_adpcm(
        input_path=args.inputfile,
        output_path=args.outputfile,
        skip_bytes=args.skip_bytes,
        block_size=args.block_size,
        rate=args.rate,
        channels=args.channels
    )

    print(f"Decoded WAV written to {args.outputfile}")

if __name__ == "__main__":
    main()

