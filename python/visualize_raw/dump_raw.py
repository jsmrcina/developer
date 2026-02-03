import argparse

def parse_args():
    parser = argparse.ArgumentParser(
        description="Dump ADPCM data to human-readable text"
    )

    parser.add_argument(
        "-f", "--filename",
        type=str,
        required=True,
        help="Input raw ADPCM file"
    )

    parser.add_argument(
        "--offset",
        type=int,
        default=0,
        help="Number of bytes to skip at the start of the file (default: 0)"
    )

    parser.add_argument(
        "-n", "--num-bytes",
        type=int,
        default=None,
        help="Number of bytes to dump (default: all)"
    )

    parser.add_argument(
        "-o", "--output",
        type=str,
        help="Output text file (if omitted, prints to stdout)"
    )

    return parser.parse_args()

def dump_bytes(data, out):
    for i, byte in enumerate(data):
        out.write(f"{i:04}: 0x{byte:02X}  |  {byte:08b}\n")

def main():
    args = parse_args()

    with open(args.filename, "rb") as f:
        f.seek(args.offset)
        data = f.read(args.num_bytes)

    out_stream = open(args.output, "w") if args.output else None
    out = out_stream if out_stream else sys.stdout

    out.write(f"Dumping {len(data)} byte(s) from {args.filename} (offset: {args.offset}):\n\n")
    dump_bytes(data, out)

    if out_stream:
        out_stream.close()

if __name__ == "__main__":
    main()

