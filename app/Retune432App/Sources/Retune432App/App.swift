import SwiftUI

@main
struct Retune432App: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") { model.showPrefs = true }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

final class AppModel: ObservableObject {
    @Published var showPrefs = false
    @Published var log: String = ""
    @Published var queue: [URL] = []
    @Published var outputDir: URL? = nil
}

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @State private var isProcessing = false
    private let supportedExtensions: Set<String> = ["wav", "mp3", "flac", "m4a", "aiff", "aif"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Retune to 432 Hz")
                .font(.title2).bold()

            HStack {
                Button("Choose Input…") { pickInput() }
                Button("Choose Output…") { pickOutput() }
                Spacer()
                Button(isProcessing ? "Processing…" : "Start") {
                    runBatch()
                }
                .disabled(isProcessing || model.queue.isEmpty || model.outputDir == nil)
            }

            List(model.queue, id: \.self) { url in
                Text(url.lastPathComponent)
            }
            .frame(minHeight: 160)

            TextEditor(text: $model.log)
                .font(.system(.footnote, design: .monospaced))
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))

        }
        .padding(16)
        .sheet(isPresented: $model.showPrefs) {
            PreferencesView()
                .environmentObject(model)
        }
    }

    private func pickInput() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            let fm = FileManager.default
            var inputs: [URL] = []
            var emptyDirectories: [URL] = []

            for url in panel.urls {
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }

                if isDir.boolValue {
                    var foundSupportedFile = false
                    if let enumerator = fm.enumerator(at: url,
                                                     includingPropertiesForKeys: [.isRegularFileKey],
                                                     options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                                     errorHandler: nil) {
                        for case let fileURL as URL in enumerator {
                            if let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                               values.isRegularFile == true,
                               isSupportedAudio(fileURL) {
                                inputs.append(fileURL)
                                foundSupportedFile = true
                            }
                        }
                    }
                    if !foundSupportedFile {
                        emptyDirectories.append(url)
                    }
                } else if isSupportedAudio(url) {
                    inputs.append(url)
                }
            }

            if !emptyDirectories.isEmpty {
                for directory in emptyDirectories {
                    model.log += "No supported audio files found in \(directory.lastPathComponent)\n"
                }
            }

            model.queue = inputs
        }
    }

    private func pickOutput() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.title = "Select Output Folder"
        panel.canCreateDirectories = true
        if panel.runModal() == .OK {
            model.outputDir = panel.url
        }
    }

    private func runBatch() {
        guard let out = model.outputDir else { return }
        isProcessing = true
        Task.detached {
            let fm = FileManager.default
            for input in model.queue {
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: input.path, isDirectory: &isDir), isDir.boolValue {
                    DispatchQueue.main.async {
                        self.model.log += "Skipping directory: \(input.lastPathComponent)\n"
                    }
                    continue
                }

                let ok = await runFFmpegRetune(input: input, outputDir: out, appendLog: { line in
                    DispatchQueue.main.async { self.model.log += line + "\n" }
                })
                DispatchQueue.main.async {
                    self.model.log += (ok ? "✓ " : "✗ ") + input.lastPathComponent + "\n"
                }
            }
            DispatchQueue.main.async { self.isProcessing = false }
        }
    }

    private func isSupportedAudio(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return !ext.isEmpty && supportedExtensions.contains(ext)
    }
}
