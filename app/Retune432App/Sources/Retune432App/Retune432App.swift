import SwiftUI
import AppKit
import Foundation

@main
struct Retune432App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var inputURL: URL?
    @State private var outputURL: URL?
    @State private var log: String = ""
    @State private var isProcessing = false

    private let supportedExtensions: Set<String> = ["wav", "mp3", "flac", "m4a", "aiff", "aif"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Retune to True 432 Hz")
                    .font(.title2)
                    .bold()
                Text("FFmpeg fallback · asetrate=sample_rate*432/440 → aresample=sample_rate")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            GroupBox(label: Text("Input")) {
                HStack {
                    Button("Select Folder") {
                        inputURL = selectFolder()
                    }
                    .disabled(isProcessing)
                    Text(inputURL?.path ?? "— none selected —")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            GroupBox(label: Text("Output")) {
                HStack {
                    Button("Select Folder") {
                        outputURL = selectFolder()
                    }
                    .disabled(isProcessing)
                    Text(outputURL?.path ?? "— none selected —")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await processFolder()
                    }
                }) {
                    Label(isProcessing ? "Processing…" : "Retune to 432", systemImage: "sparkles")
                }
                .disabled(isProcessing || inputURL == nil || outputURL == nil)

                Button("FFmpeg Install Guide") {
                    if let url = URL(string: "https://ffmpeg.org/download.html#build-mac") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .disabled(isProcessing)
            }

            ScrollView {
                Text(log)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            .frame(minHeight: 200)
            .background(Color(NSColor.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 420)
    }

    private func selectFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.title = "Select Folder"
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func processFolder() async {
        guard let inputURL, let outputURL else { return }

        await MainActor.run {
            isProcessing = true
            log = ""
        }

        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }

        guard await ffmpegIsAvailable() else {
            await MainActor.run {
                log += "⚠️ FFmpeg not found. Install via `brew install ffmpeg`.\n"
            }
            return
        }

        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        } catch {
            await MainActor.run {
                log += "❌ Unable to create output folder: \(error.localizedDescription)\n"
            }
            return
        }

        guard let enumerator = FileManager.default.enumerator(
            at: inputURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            await MainActor.run {
                log += "❌ Unable to read input folder.\n"
            }
            return
        }

        var processedCount = 0

        for case let fileURL as URL in enumerator {
            if (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                continue
            }

            if !supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                continue
            }

            processedCount += 1
            let outputName = "432_" + fileURL.deletingPathExtension().lastPathComponent + ".wav"
            let destination = outputURL.appendingPathComponent(outputName)

            await MainActor.run {
                log += "→ \(fileURL.lastPathComponent)\n"
            }

            let (status, output) = await runFFmpeg(input: fileURL, output: destination)

            if !output.isEmpty {
                await MainActor.run {
                    log += output
                }
            }

            await MainActor.run {
                if status == 0 {
                    log += "   ✅ Wrote \(destination.lastPathComponent)\n"
                } else {
                    log += "   ❌ FFmpeg exited with code \(status)\n"
                }
            }
        }

        await MainActor.run {
            if processedCount == 0 {
                log += "⚠️ No supported audio files found.\n"
            } else {
                log += "\nFinished processing \(processedCount) file(s).\n"
            }
        }
    }

    private func ffmpegIsAvailable() async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = ["ffmpeg", "-version"]
                process.standardOutput = Pipe()
                process.standardError = Pipe()
                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func runFFmpeg(input: URL, output: URL) async -> (Int32, String) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = [
                    "ffmpeg",
                    "-y",
                    "-i", input.path,
                    "-af", "asetrate=sample_rate*432/440,aresample=sample_rate",
                    output.path
                ]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                do {
                    try process.run()
                } catch {
                    continuation.resume(returning: (-1, "Failed to launch ffmpeg: \(error.localizedDescription)\n"))
                    return
                }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                let text = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: (process.terminationStatus, text))
            }
        }
    }
}
