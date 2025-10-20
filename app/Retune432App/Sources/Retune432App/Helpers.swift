import Foundation

@discardableResult
func runFFmpegRetune(input: URL, outputDir: URL, appendLog: @escaping (String)->Void) async -> Bool {
    let sr = probeSampleRate(url: input) ?? 44100
    let bit = UserDefaults.standard.integer(forKey: "bitDepth")
    let codec = (bit == 16) ? "pcm_s16le" : "pcm_s24le"

    let out = outputDir.appendingPathComponent("432_" + input.deletingPathExtension().lastPathComponent)
                       .appendingPathExtension("wav")

    let args = [
        "-y", "-i", input.path,
        "-af", "asetrate=\(sr)*432/440,aresample=\(sr)",
        "-c:a", codec,
        out.path
    ]
    return runProcess(launchPath: "/usr/local/bin/ffmpeg", args: args, appendLog: appendLog)
        || runProcess(launchPath: "/opt/homebrew/bin/ffmpeg", args: args, appendLog: appendLog)
}

func probeSampleRate(url: URL) -> Int? {
    let args = ["-v","error","-show_entries","stream=sample_rate","-of","default=nw=1:nk=1", url.path]
    if let out = capture("/usr/local/bin/ffprobe", args) ?? capture("/opt/homebrew/bin/ffprobe", args),
       let sr = Int(out.trimmingCharacters(in: .whitespacesAndNewlines)) {
        return sr
    }
    return nil
}

func runProcess(launchPath: String, args: [String], appendLog: (String)->Void) -> Bool {
    guard FileManager.default.fileExists(atPath: launchPath) else { return false }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: launchPath)
    p.arguments = args

    let pipe = Pipe()
    p.standardError = pipe
    p.standardOutput = pipe

    do { try p.run() } catch { appendLog("Failed to start \(launchPath): \(error)"); return false }

    let handle = pipe.fileHandleForReading
    handle.readabilityHandler = { fh in
        if let s = String(data: fh.availableData, encoding: .utf8), !s.isEmpty {
            appendLog(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    p.waitUntilExit()
    handle.readabilityHandler = nil
    return p.terminationStatus == 0
}

func capture(_ bin: String, _ args: [String]) -> String? {
    guard FileManager.default.fileExists(atPath: bin) else { return nil }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: bin)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = Pipe()
    do { try p.run() } catch { return nil }
    p.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
}
