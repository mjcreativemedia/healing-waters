# 432 Hz Pure Retune

This tool performs a *true* 432 Hz conversion using the time/clock method only
(≈ +1.818% duration). It applies the exact ratio 432/440 across the entire
waveform, baking the slowdown and keeping output at your original sample rate.

Quick start:
  python -m venv .venv
  source .venv/bin/activate      # Windows: .venv\Scripts\activate
  pip install --upgrade pip
  pip install librosa soundfile numpy
  python retune_432_pure.py /input /output

Output: 24-bit WAV files prefixed with `432_...`, ready for YouTube.