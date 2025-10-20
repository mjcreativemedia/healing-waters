import Foundation

struct StreamingProcessResult {
    let status: Int32
    let reason: Process.TerminationReason
}

func runStreamingFFmpeg(
    input: URL,
    output: URL,
    sampleRate: Int,
    bitDepth: BitDepthOption,
    onLaunch: @escaping (Process) -> Void,
    onLine: @escaping (String) -> Void
) async throws -> StreamingProcessResult {
    try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [
                "ffmpeg",
                "-y",
                "-i", input.path,
                "-af", "asetrate=\(sampleRate)*432/440,aresample=\(sampleRate)",
                "-c:a", bitDepth.ffmpegCodec,
                output.path
            ]

            let stderrPipe = Pipe()
            let stdoutPipe = Pipe()
            process.standardError = stderrPipe
            process.standardOutput = stdoutPipe

            let stderrAggregator = LineAggregator()
            let stdoutAggregator = LineAggregator()

            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
                let sanitized = text.replacingOccurrences(of: "\r", with: "\n")
                stderrAggregator.feed(sanitized, handler: onLine)
            }

            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
                let sanitized = text.replacingOccurrences(of: "\r", with: "\n")
                stdoutAggregator.feed(sanitized, handler: onLine)
            }

            process.terminationHandler = { proc in
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrAggregator.drain(handler: onLine)
                stdoutAggregator.drain(handler: onLine)
                continuation.resume(returning: StreamingProcessResult(status: proc.terminationStatus, reason: proc.terminationReason))
            }

            do {
                onLaunch(process)
                try process.run()
            } catch {
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}

func detectSampleRate(for url: URL) async -> Int? {
    let arguments = [
        "-v", "error",
        "-show_entries", "stream=sample_rate",
        "-of", "default=nw=1:nk=1",
        url.path
    ]

    do {
        let result = try await runCommand("ffprobe", arguments: arguments)
        guard result.status == 0 else { return nil }
        let lines = result.stdout.split(whereSeparator: \.isNewline)
        if let first = lines.first {
            return Int(first.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    } catch {
        return nil
    }

    return nil
}

func probeDuration(for url: URL) async throws -> Double? {
    let arguments = [
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=nw=1:nk=1",
        url.path
    ]

    let result = try await runCommand("ffprobe", arguments: arguments)
    guard result.status == 0 else { return nil }
    let lines = result.stdout.split(whereSeparator: \.isNewline)
    if let first = lines.first {
        return Double(first.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    return nil
}

func toolExists(_ name: String) async -> Bool {
    do {
        let result = try await runCommand(name, arguments: ["-version"])
        return result.status == 0
    } catch {
        return false
    }
}

private struct CommandResult {
    let status: Int32
    let stdout: String
    let stderr: String
}

private func runCommand(_ tool: String, arguments: [String]) async throws -> CommandResult {
    try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [tool] + arguments

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            do {
                try process.run()
                process.waitUntilExit()
                let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: stdoutData, encoding: .utf8) ?? ""
                let errorOutput = String(data: stderrData, encoding: .utf8) ?? ""
                continuation.resume(returning: CommandResult(status: process.terminationStatus, stdout: output, stderr: errorOutput))
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

final class LineAggregator {
    private var buffer = ""
    private let accessQueue = DispatchQueue(label: "retune432.line-aggregator")

    func feed(_ string: String, handler: (String) -> Void) {
        var lines: [String] = []
        accessQueue.sync {
            buffer.append(string)
            while let range = buffer.range(of: "\n") {
                let line = String(buffer[..<range.lowerBound])
                lines.append(line)
                buffer.removeSubrange(..<range.upperBound)
            }
        }

        for line in lines {
            let cleaned = line.replacingOccurrences(of: "\r", with: "")
            if !cleaned.isEmpty {
                handler(cleaned)
            }
        }
    }

    func drain(handler: (String) -> Void) {
        let remaining: String = accessQueue.sync {
            let value = buffer.replacingOccurrences(of: "\r", with: "")
            buffer.removeAll()
            return value
        }

        if !remaining.isEmpty {
            handler(remaining)
        }
    }
}

func formatDuration(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "—" }
    let totalMilliseconds = Int((seconds * 1000).rounded())
    let hours = totalMilliseconds / 3_600_000
    let minutes = (totalMilliseconds % 3_600_000) / 60_000
    let milliseconds = totalMilliseconds % 60_000
    let secondsComponent = Double(milliseconds) / 1000.0

    if hours > 0 {
        return String(format: "%d:%02d:%06.3f", hours, minutes, secondsComponent)
    } else {
        return String(format: "%02d:%06.3f", minutes, secondsComponent)
    }
}
