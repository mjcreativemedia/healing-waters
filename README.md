# 🌊 Healing Waters — True 432 Hz Retune Toolkit

**Tagline:**  
> *Living Paintings tuned to divine frequency.*  
> Convert any 440 Hz audio into true 432 Hz resonance using physics-based time scaling.

---

## 🎧 What It Does

Healing Waters is a **pure-tune** audio converter that retunes any audio file from standard 440 Hz to 432 Hz — not by pitch-shifting, but by adjusting the *playback clock* itself.  
That means your output isn't just perceptually "softer"... it's *actually vibrating* in harmonic alignment with 432 Hz.

---

## ⚙️ Quick Start

### Install dependencies
```bash
pip3 install -r requirements.txt
```

### Retune your first track
```bash
python3 core/retune_432.py /path/to/input /path/to/output
```

- Produces 24-bit WAV output files named `432_<original>.wav`
- Duration becomes ~+1.818% longer (proof of true 432 Hz retuning)

---

## 🧠 Why 432 Hz?

- **440 Hz** (modern tuning) introduces slight dissonance in harmonic ratios
- **432 Hz** aligns with natural resonance patterns — cymatic water experiments show stable geometry under this frequency
- Because our bodies are ~70% water, this shift subtly affects both mind and matter
- Healing Waters performs the purest retune possible: clock-based resampling, not spectral warping

---

## 🧩 File Layout

```
core/
  retune_432.py        # Main retune engine (time/clock scaling)
docs/
  README_432.md        # Technical notes
  HEALING_WATERS_432.md
  styles-library.md    # Visual identity for video loops
  FFmpeg-line.txt      # Alternate FFmpeg retune method
requirements.txt       # Python dependencies
```

---

## 🧱 Advanced Usage

### Batch convert a full folder of mixed formats:
```bash
python3 core/retune_432.py ./input ./output
```

**Supported extensions:** `.wav`, `.mp3`, `.flac`, `.m4a`, `.aiff`, `.aif`

---

## 🪄 Optional Extras

- **macOS Quick Script**: Create a `.command` file to choose folders via Finder and run automatically
- **CLI Tool**: Rename and run as `retune432 input/ output/` from Terminal
- **FFmpeg Line (one-liner)**:
  ```bash
  ffmpeg -i input.wav -af asetrate=44100*432/440,aresample=44100 output.wav
  ```

---

## 🧘‍♂️ Philosophy

> "432 Hz is not a trend. It's the return to original order — harmony between vibration and creation."

Healing Waters is open-source so musicians, engineers, and spiritual creators can build from a clean foundation — retuning the world one waveform at a time.

---

## 📄 License

MIT License © 2025 mjcreativemedia  
Use freely, modify openly, and give credit when possible.

---

## 🌐 Links

**GitHub:** mjcreativemedia/healing-waters
