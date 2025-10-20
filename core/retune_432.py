# retune_432_pure.py
# True 432 Hz retune (time/clock method only) — no pitch mode.
# Usage:
#   python retune_432_pure.py /path/to/input /path/to/output
# Deps: pip install librosa soundfile numpy

import argparse, os, glob, sys
import numpy as np
import soundfile as sf
import librosa

RATIO = 432.0 / 440.0  # exact ratio (0.981818...)

def retune_to_432(y, sr):
    """
    Pure 'speed' retune:
    Conceptually set the source to a lower virtual sample rate (sr*RATIO),
    then resample back to the original sr. This bakes in ~+1.818% duration,
    lowering every vibration by the exact 432/440 proportion.
    """
    virtual_sr = sr * RATIO
    # High-quality resample to bake the slowdown into the waveform at original sr
    y_out = librosa.resample(y, orig_sr=virtual_sr, target_sr=sr, res_type="kaiser_best")
    return y_out

def process_file(src, dst):
    # Preserve native sr; keep channels
    y, sr = librosa.load(src, sr=None, mono=False)
    if y.ndim == 1:
        y = y[np.newaxis, :]

    # Process each channel independently
    chans = [retune_to_432(ch, sr) for ch in y]
    # Make channels same length (minor off-by-sample differences can occur)
    maxlen = max(len(ch) for ch in chans)
    chans = [np.pad(ch, (0, maxlen - len(ch))) for ch in chans]
    y_out = np.vstack(chans).T  # [samples, channels]

    # Write 24-bit WAV at the original sr (standard-friendly for YouTube)
    sf.write(dst, y_out, sr, subtype="PCM_24")

def main():
    ap = argparse.ArgumentParser(description="True 432 Hz retune (time/clock method only)")
    ap.add_argument("in_dir", help="Folder with input audio files")
    ap.add_argument("out_dir", help="Folder to write 432 Hz WAV files")
    ap.add_argument("--exts", nargs="+", default=[".wav",".mp3",".flac",".m4a",".aiff",".aif"])
    args = ap.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)
    files = [p for ext in args.exts for p in glob.glob(os.path.join(args.in_dir, f"*{ext}"))]
    if not files:
        print("No audio files found. Check your folder and extensions.", file=sys.stderr)
        sys.exit(1)

    for f in files:
        base = os.path.splitext(os.path.basename(f))[0]
        out = os.path.join(args.out_dir, f"432_{base}.wav")
        print(f"[pure] {os.path.basename(f)} -> {os.path.basename(out)}")
        process_file(f, out)

if __name__ == "__main__":
    main()