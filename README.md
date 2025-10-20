# 🌊 Healing Waters — True 432 Hz Retune Toolkit

[![Python Engine](https://github.com/mjcreativemedia/healing-waters/actions/workflows/python.yml/badge.svg)](https://github.com/mjcreativemedia/healing-waters/actions/workflows/python.yml)
[![Swift App](https://github.com/mjcreativemedia/healing-waters/actions/workflows/swift.yml/badge.svg)](https://github.com/mjcreativemedia/healing-waters/actions/workflows/swift.yml)

> *Living paintings tuned to divine frequency.*

Healing Waters converts any standard 440 Hz recording to **true 432 Hz** by stretching time with the exact ratio **432 / 440** (≈ 0.981818). No pitch-warp tricks—just clock-accurate resampling that preserves the original sample rate while producing pristine **24‑bit WAV** output.

---

## ✨ Feature Highlights
- **Pure time/clock retune** using `core/retune_432.py` (librosa + soxr backend)
- **Batch-ready CLI** (`cli/retune432`) and **Finder-friendly script** (`scripts/Retune432.command`)
- **SwiftUI macOS app** wrapping an FFmpeg fallback (Ventura 13.0+)
- **Documentation bundle** explaining the physics, philosophy, and visual branding
- **CI on macOS** to keep the Python engine and Swift app builds healthy

---

## ⚙️ Quick Start (Python Engine)
1. Install dependencies:
   ```bash
   pip3 install -r requirements.txt
   ```
2. Retune an entire folder (mix-and-match formats):
   ```bash
   python3 core/retune_432.py /path/to/input /path/to/output
   ```

- Output files are named `432_<original>.wav`
- Duration becomes **~ +1.852 % longer** — the fingerprint of true 432 Hz resampling
- Supported extensions: `.wav`, `.mp3`, `.flac`, `.m4a`, `.aiff`, `.aif`

### Option A — CLI Wrapper
```bash
./cli/retune432 ./input ./output
```
- Pass through any `--exts` overrides supported by the Python engine:
  ```bash
  ./cli/retune432 ./input ./output --exts .wav .aiff
  ```
- Uses `python3` by default; override with `PYTHON_BIN=/path/to/python ./cli/retune432 …`

### Option B — Finder Script (`Retune432.command`)
1. Double-click `scripts/Retune432.command`
2. Choose input and output folders via native dialogs
3. Receive a macOS notification when processing completes

> 💡 Tip: keep the script inside the repo so it always finds the latest engine.

### Option C — SwiftUI macOS App (FFmpeg Fallback)
- Requirements: macOS 13+, Xcode 15 / Swift 5.9+, `ffmpeg` in `$PATH` (e.g. `brew install ffmpeg`)
- Build & run:
  ```bash
  cd app/Retune432App
  swift build -c release
  open .build/release/Retune432.app
  ```
- Select input/output folders, press **“Retune to 432”**, and watch the live log as FFmpeg runs `asetrate=sample_rate*432/440,aresample=sample_rate` for every supported file.

## 🍎 macOS App (SwiftUI v0.2)
- Live file queue with per-track status (Queued → Running → Done / Failed / Canceled)
- Streaming FFmpeg stderr log with Save Log export and drag-and-drop inputs
- Automatic sample-rate detection per file with `ffprobe`, preserving the original rate
- Preferences remember default bit depth (24-bit PCM by default) and output folder
- Cancel button terminates the active FFmpeg process and marks the rest as canceled

![macOS app file selection placeholder](docs/images/mac-file-selection.png)
![macOS app progress placeholder](docs/images/mac-progress.png)
![macOS duration proof placeholder](docs/images/mac-duration-proof.png)

> Output files are 24-bit WAV by default, keep the original sample rate, and extend duration by ≈ +1.852 % (432/440).

📚 See [`docs/app-usage.md`](docs/app-usage.md) for an illustrated walkthrough (drag-and-drop, cancellation, log export, and preferences).

---

## ✅ Verification Checklist
| Expectation | How to verify |
|-------------|---------------|
| **24‑bit PCM WAV** | `python3 - <<'PY'` / `soundfile.info('432_track.wav').subtype` → `PCM_24` |
| **Duration ≈ +1.852 %** | Compare sample counts: `len(output)/len(input) ≈ 1.01852` |
| **Original sample rate** | Inspect metadata (e.g. `soxi -r 432_track.wav`) |
| **True 432/440 scaling** | Waveform pitch shift calculators report –31.766 cents |

---

## 🧭 Documentation Map
- [`docs/README_432.md`](docs/README_432.md) — extended technical overview
- [`docs/HEALING_WATERS_432.md`](docs/HEALING_WATERS_432.md) — philosophy & tone
- [`docs/styles-library.md`](docs/styles-library.md) — visual palette for video loops
- [`docs/FFmpeg-line.txt`](docs/FFmpeg-line.txt) — raw FFmpeg recipe reference
- [`docs/app-usage.md`](docs/app-usage.md) — SwiftUI app walkthrough with screenshots

Screenshots and waveform comparisons are coming in the v0.1 launch notes (“Living Paintings Edition”).

---

## 🧪 Continuous Integration
- **`python-engine`** workflow synthesizes a 440 Hz tone, retunes it, and asserts sample-count ratio ≈ 1.01852 and PCM_24 output
- **`swift-app`** workflow builds the SwiftUI FFmpeg wrapper on macOS-latest

Both workflows run on every push / pull request to keep the toolkit reproducible on Apple Silicon.

---

## 📦 Release Roadmap
- **v0.1.0 — “Living Paintings Edition”** (in progress): CLI, Finder script, Swift app prototype, refreshed docs, verification notes
- Future milestones: drag-and-drop UI, progress indicators, loudness normalization presets, notarized distribution

---

## 🧘‍♂️ Philosophy
> “432 Hz is not a trend. It’s the return to original order — harmony between vibration and creation.”

Healing Waters is MIT-licensed so musicians, engineers, and meditative artists can bring 432 Hz resonance into every long-form loop, film score, or watercolor soundscape.

---

## 📄 License
MIT License © 2025 mjcreativemedia
