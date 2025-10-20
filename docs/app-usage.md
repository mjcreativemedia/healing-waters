# Healing Waters macOS App — Usage Guide

This walkthrough highlights the SwiftUI app experience introduced in v0.2. Each step includes a screenshot placeholder you can replace with real captures once the UI is finalized.

## 1. Launch the app
Open the `Retune432` app from Xcode or Finder. The home view summarises the 432 → 440 physics and shows your default bit depth.

![Launch screen placeholder](images/mac-step1-launch.png)

## 2. Choose input and output locations
Use the **Select Folder** buttons to point to the source material and destination. The output defaults to the last saved folder or the preference you set.

![Folder selection placeholder](images/mac-step2-folders.png)

## 3. Drag-and-drop to build the queue
Drop individual files or entire folders onto the window. The table lists every supported track with its current status.

![Queue placeholder](images/mac-step3-queue.png)

## 4. Start the retune and watch progress
Press **Retune to 432** to run FFmpeg. Live stderr lines stream into the log while the progress view tracks how many files are complete.

![Progress placeholder](images/mac-step4-progress.png)

## 5. Inspect per-file results
Each row reports when it finishes, including the measured duration delta. Expect ≈ +1.852 % once the 432/440 ratio is verified within tolerance.

![Duration proof placeholder](images/mac-step5-duration.png)

## 6. Cancel or export logs when needed
Use **Cancel** to terminate the current FFmpeg process and mark remaining items as canceled. The **Save Log** button exports the session log as a `.txt` file for support or archival.

![Log export placeholder](images/mac-step6-log.png)

## 7. Adjust preferences
Open **Preferences…** to switch between 24-bit and 16-bit WAV output or to set a default export folder. These settings persist between sessions via `UserDefaults`.

![Preferences placeholder](images/mac-step7-preferences.png)

## 8. Confirm FFmpeg availability
If FFmpeg is missing, the app shows an actionable alert with a Homebrew link. Install with `brew install ffmpeg` and relaunch to continue.

![FFmpeg alert placeholder](images/mac-step8-alert.png)

> ✨ Outputs remain 24-bit WAV by default, preserve the original sample rate, and increase in duration by ≈ +1.852 % — the fingerprint of true 432 Hz resampling.
