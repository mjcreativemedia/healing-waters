import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct Retune432App: App {
    @StateObject private var preferencesStore: PreferencesStore
    @StateObject private var viewModel: AppViewModel

    init() {
        let preferences = PreferencesStore()
        _preferencesStore = StateObject(wrappedValue: preferences)
        _viewModel = StateObject(wrappedValue: AppViewModel(preferences: preferences))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel, preferences: preferencesStore)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") {
                    viewModel.showingPreferences = true
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject var preferences: PreferencesStore

    @State private var isDropTarget = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            selectionRow

            controlRow

            queueSection

            progressSection

            logSection
        }
        .padding(20)
        .frame(minWidth: 820, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onDrop(of: [.fileURL], isTargeted: $isDropTarget, perform: handleDrop(providers:))
        .sheet(isPresented: $viewModel.showingPreferences) {
            PreferencesView(preferences: preferences)
        }
        .alert(item: $viewModel.alertItem) { item in
            switch item.kind {
            case .missingFFmpeg, .missingFFprobe:
                return Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    primaryButton: .default(Text("Open Homebrew")) {
                        if let url = URL(string: "https://brew.sh") {
                            NSWorkspace.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .info:
                return Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
            }
        }
        .onAppear {
            viewModel.applyDefaultOutput(preferences.defaultOutputFolder)
        }
        .onChange(of: preferences.defaultOutputFolder) { newValue in
            viewModel.applyDefaultOutput(newValue)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Retune to True 432 Hz")
                .font(.title2)
                .bold()
            Text("FFmpeg · asetrate=sample_rate*432/440 → aresample=sample_rate")
                .font(.callout)
                .foregroundColor(.secondary)
            Text("Default bit depth: \(preferences.bitDepth.displayName)")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var selectionRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox(label: Text("Input")) {
                HStack(spacing: 12) {
                    Button("Select Folder") {
                        if let url = openFolderPanel(title: "Select Input Folder") {
                            viewModel.setInput(url)
                        }
                    }
                    .disabled(viewModel.isProcessing)

                    Text(viewModel.inputURL?.path ?? "— none selected —")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
            }

            GroupBox(label: Text("Output")) {
                HStack(spacing: 12) {
                    Button("Select Folder") {
                        if let url = openFolderPanel(title: "Select Output Folder") {
                            viewModel.setOutput(url)
                            preferences.defaultOutputFolder = url
                        }
                    }
                    .disabled(viewModel.isProcessing)

                    Text((viewModel.outputURL ?? preferences.defaultOutputFolder)?.path ?? "— none selected —")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.startProcessing()
                }
            } label: {
                Label(viewModel.isProcessing ? "Processing…" : "Retune to 432", systemImage: "sparkles")
            }
            .disabled(viewModel.startDisabled)

            Button("Cancel") {
                viewModel.cancelProcessing()
            }
            .disabled(!viewModel.isProcessing)

            Button("Save Log") {
                viewModel.saveLog()
            }
            .disabled(viewModel.logLines.isEmpty)

            Spacer()

            Button("Preferences…") {
                viewModel.showingPreferences = true
            }
        }
    }

    private var queueSection: some View {
        GroupBox(label: Text("Files to Process")) {
            if viewModel.queue.isEmpty {
                VStack(alignment: .center) {
                    Text("Drag audio files or folders here to queue them.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(24)
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(viewModel.queue) { item in
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.sourceURL.lastPathComponent)
                                    .font(.body)
                                if let detail = item.detailDisplay {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Text(item.statusDisplay)
                                .font(.caption)
                                .foregroundColor(item.statusColor)
                                .frame(minWidth: 96, alignment: .trailing)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(InsetListStyle())
                .frame(minHeight: 180, maxHeight: 260)
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: viewModel.progressFraction, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())

            HStack {
                Text(viewModel.progressSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.remainingSummary)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var logSection: some View {
        GroupBox(label: Text("Session Log")) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(viewModel.logLines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .id(index)
                        }
                    }
                    .padding(8)
                }
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: viewModel.logLines.count) { _ in
                    if let last = viewModel.logLines.indices.last {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
                .frame(minHeight: 200)
            }
        }
    }

    private func openFolderPanel(title: String) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.title = title
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !viewModel.isProcessing else { return false }

        let fileIdentifier = UTType.fileURL.identifier
        let lock = NSLock()
        var collected: [URL] = []
        var handled = false
        let group = DispatchGroup()

        for provider in providers where provider.hasItemConforming(toTypeIdentifier: fileIdentifier) {
            handled = true
            group.enter()
            provider.loadItem(forTypeIdentifier: fileIdentifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    lock.lock()
                    collected.append(url)
                    lock.unlock()
                } else if let url = item as? URL {
                    lock.lock()
                    collected.append(url)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            viewModel.addDroppedItems(collected)
        }

        return handled
    }
}

enum AlertKind {
    case info
    case missingFFmpeg
    case missingFFprobe
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let kind: AlertKind
}

@MainActor
final class AppViewModel: ObservableObject {
    struct FileJob: Identifiable {
        enum Status: Equatable {
            case queued
            case running
            case done
            case failed
            case canceled

            var isFinished: Bool {
                switch self {
                case .queued, .running:
                    return false
                case .done, .failed, .canceled:
                    return true
                }
            }
        }

        let id = UUID()
        let sourceURL: URL
        var status: Status = .queued
        var detail: String?

        var statusDisplay: String {
            switch status {
            case .queued:
                return "Queued"
            case .running:
                return "Running"
            case .done:
                return "Done"
            case .failed:
                return "Failed"
            case .canceled:
                return "Canceled"
            }
        }

        var detailDisplay: String? {
            detail
        }

        var statusColor: Color {
            switch status {
            case .queued:
                return .secondary
            case .running:
                return .accentColor
            case .done:
                return .green
            case .failed:
                return .red
            case .canceled:
                return .orange
            }
        }
    }

    private let preferences: PreferencesStore
    @Published var inputURL: URL?
    @Published var outputURL: URL?
    @Published var queue: [FileJob] = []
    @Published var logLines: [String] = []
    @Published var isProcessing = false
    @Published var showingPreferences = false
    @Published var alertItem: AlertItem?

    private var cancelRequested = false
    private var currentProcess: Process?
    private let supportedExtensions: Set<String> = ["wav", "mp3", "flac", "m4a", "aiff", "aif", "ogg", "aac", "alac", "wma"]

    init(preferences: PreferencesStore) {
        self.preferences = preferences
        self.outputURL = preferences.defaultOutputFolder
    }

    var startDisabled: Bool {
        isProcessing || queue.isEmpty || effectiveOutputFolder == nil
    }

    var progressFraction: Double {
        guard !queue.isEmpty else { return 0 }
        let finished = queue.filter { $0.status.isFinished }.count
        return Double(finished) / Double(queue.count)
    }

    var progressSummary: String {
        guard !queue.isEmpty else { return "No files queued" }
        let finished = queue.filter { $0.status.isFinished }.count
        return "Processed \(finished) of \(queue.count) (\(progressPercentage))"
    }

    var remainingSummary: String {
        guard !queue.isEmpty else { return "" }
        let finished = queue.filter { $0.status.isFinished }.count
        let remaining = max(queue.count - finished, 0)
        if isProcessing {
            return "Remaining: \(remaining)"
        }
        return remaining == queue.count ? "Ready: \(queue.count)" : "Queued: \(remaining)"
    }

    private var progressPercentage: String {
        String(format: "%.0f%%", progressFraction * 100)
    }

    private var effectiveOutputFolder: URL? {
        outputURL ?? preferences.defaultOutputFolder
    }

    func applyDefaultOutput(_ url: URL?) {
        guard outputURL == nil, let url else { return }
        outputURL = url
    }

    func setInput(_ url: URL) {
        inputURL = url
        let files = gatherAudioFiles(from: [url])
        queue = files.map { FileJob(sourceURL: $0) }
    }

    func setOutput(_ url: URL) {
        outputURL = url
    }

    func addDroppedItems(_ urls: [URL]) {
        let files = gatherAudioFiles(from: urls)
        guard !files.isEmpty else { return }

        var existing = Set(queue.map { $0.sourceURL.standardizedFileURL })
        for file in files {
            let standardized = file.standardizedFileURL
            if existing.contains(standardized) { continue }
            queue.append(FileJob(sourceURL: file))
            existing.insert(standardized)
        }

        queue.sort { lhs, rhs in
            lhs.sourceURL.lastPathComponent.localizedCaseInsensitiveCompare(rhs.sourceURL.lastPathComponent) == .orderedAscending
        }
    }

    func saveLog() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "Retune432-Session-Log.txt"
        panel.directoryURL = effectiveOutputFolder ?? inputURL

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try logLines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
                alertItem = AlertItem(title: "Log saved", message: "Saved to \(url.path)", kind: .info)
            } catch {
                alertItem = AlertItem(title: "Unable to save log", message: error.localizedDescription, kind: .info)
            }
        }
    }

    func cancelProcessing() {
        guard isProcessing else { return }
        if !cancelRequested {
            appendLog("⚠️ Cancel requested — stopping after current file")
        }
        cancelRequested = true
        currentProcess?.terminate()
    }

    func startProcessing() async {
        guard !isProcessing else { return }
        guard !queue.isEmpty else {
            alertItem = AlertItem(title: "No files queued", message: "Select or drop audio files before starting.", kind: .info)
            return
        }
        guard let outputFolder = effectiveOutputFolder else {
            alertItem = AlertItem(title: "Select an output folder", message: "Choose an output destination or set a default in Preferences.", kind: .info)
            return
        }

        do {
            try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        } catch {
            alertItem = AlertItem(title: "Unable to create output folder", message: error.localizedDescription, kind: .info)
            return
        }

        queue = queue.map { job in
            var updated = job
            updated.status = .queued
            updated.detail = nil
            return updated
        }

        isProcessing = true
        cancelRequested = false
        logLines.removeAll()
        appendLog("🎧 Retune session started — \(timestampString())")
        appendLog("Bit depth: \(preferences.bitDepth.displayName) · Output: \(outputFolder.path)")

        let hasFFmpeg = await toolExists("ffmpeg")
        guard hasFFmpeg else {
            alertItem = AlertItem(title: "FFmpeg not found", message: "FFmpeg not found. Install via: brew install ffmpeg", kind: .missingFFmpeg)
            appendLog("❌ FFmpeg not available")
            isProcessing = false
            return
        }

        let hasFFprobe = await toolExists("ffprobe")
        guard hasFFprobe else {
            alertItem = AlertItem(title: "FFprobe not found", message: "FFprobe not found. Install FFmpeg via: brew install ffmpeg", kind: .missingFFprobe)
            appendLog("❌ FFprobe not available")
            isProcessing = false
            return
        }

        var canceledIndex: Int?
        for index in queue.indices {
            if cancelRequested {
                canceledIndex = index
                break
            }

            let result = await processItem(at: index, outputFolder: outputFolder)
            if result == .canceled {
                canceledIndex = index
                break
            }
        }

        if let canceledIndex {
            let start = queue.indices.contains(canceledIndex) && queue[canceledIndex].status == .canceled ? canceledIndex : canceledIndex + 1
            markRemainingCanceled(startingAt: start)
            appendLog("⏹️ Processing canceled")
        } else {
            let finished = queue.filter { $0.status == .done }.count
            appendLog("🎉 Finished processing \(finished) of \(queue.count) file(s)")
        }

        currentProcess = nil
        cancelRequested = false
        isProcessing = false
    }

    private func processItem(at index: Int, outputFolder: URL) async -> ProcessingResult {
        guard index < queue.count else { return .finished }
        let source = queue[index].sourceURL
        var job = queue[index]
        job.status = .running
        job.detail = nil
        queue[index] = job

        appendLog("→ \(source.lastPathComponent)")

        let detectedSampleRate = await detectSampleRate(for: source)
        let sampleRate = detectedSampleRate ?? 44100
        appendLog("   Sample rate: \(sampleRate) Hz")

        var runningJob = queue[index]
        runningJob.detail = "Sample rate: \(sampleRate) Hz"
        queue[index] = runningJob

        let outputName = "432_" + source.deletingPathExtension().lastPathComponent + ".wav"
        let destination = outputFolder.appendingPathComponent(outputName)

        let result: StreamingProcessResult
        do {
            result = try await runStreamingFFmpeg(
                input: source,
                output: destination,
                sampleRate: sampleRate,
                bitDepth: preferences.bitDepth,
                onLaunch: { [weak self] process in
                    Task { @MainActor in
                        self?.currentProcess = process
                    }
                },
                onLine: { [weak self] line in
                    Task { @MainActor in
                        self?.appendLog(line)
                    }
                }
            )
        } catch {
            appendLog("   ❌ Failed to launch ffmpeg: \(error.localizedDescription)")
            queue[index].status = .failed
            queue[index].detail = error.localizedDescription
            try? FileManager.default.removeItem(at: destination)
            return .finished
        }

        currentProcess = nil

        if result.reason == .uncaughtSignal {
            queue[index].status = .canceled
            queue[index].detail = nil
            try? FileManager.default.removeItem(at: destination)
            return .canceled
        }

        guard result.status == 0 else {
            appendLog("   ❌ FFmpeg exited with code \(result.status)")
            queue[index].status = .failed
            queue[index].detail = "Exit code \(result.status)"
            try? FileManager.default.removeItem(at: destination)
            return .finished
        }

        appendLog("   ✅ Wrote \(destination.lastPathComponent)")

        do {
            if let inputDuration = try await probeDuration(for: source),
               let outputDuration = try await probeDuration(for: destination),
               inputDuration > 0 {
                let info = DurationInfo(inputSeconds: inputDuration, outputSeconds: outputDuration)
                queue[index].status = .done
                queue[index].detail = info.summary
                appendLog("   Δ duration: \(info.logLine)")
                if !info.withinTolerance {
                    appendLog("   ⚠️ Outside expected +1.852% tolerance")
                }
            } else {
                queue[index].status = .done
                queue[index].detail = "Output saved"
                appendLog("   Δ duration: unable to measure")
            }
        } catch {
            queue[index].status = .done
            queue[index].detail = "Output saved"
            appendLog("   Δ duration: measurement failed — \(error.localizedDescription)")
        }

        if cancelRequested {
            return .canceled
        }

        return .finished
    }

    private func markRemainingCanceled(startingAt index: Int) {
        guard index < queue.count else { return }
        for idx in index..<queue.count {
            if queue[idx].status == .queued || queue[idx].status == .running {
                queue[idx].status = .canceled
                queue[idx].detail = nil
            }
        }
    }

    private func gatherAudioFiles(from urls: [URL]) -> [URL] {
        var collected: [URL] = []
        for url in urls {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { continue }
            if isDirectory.boolValue {
                if let enumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                ) {
                    for case let file as URL in enumerator {
                        if supportedExtensions.contains(file.pathExtension.lowercased()) {
                            collected.append(file)
                        }
                    }
                }
            } else if supportedExtensions.contains(url.pathExtension.lowercased()) {
                collected.append(url)
            }
        }

        return collected.sorted {
            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
        }
    }

    private func appendLog(_ line: String) {
        logLines.append(line)
    }

    private func timestampString() -> String {
        DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
    }

    enum ProcessingResult {
        case finished
        case canceled
    }
}

struct DurationInfo: Equatable {
    let inputSeconds: Double
    let outputSeconds: Double

    var ratio: Double {
        guard inputSeconds > 0 else { return 1 }
        return outputSeconds / inputSeconds
    }

    var percentDelta: Double {
        (ratio - 1) * 100
    }

    var withinTolerance: Bool {
        abs(ratio - 1.018518) < 0.005
    }

    var summary: String {
        "\(formattedPercent) (\(formatDuration(inputSeconds)) → \(formatDuration(outputSeconds))) \(withinTolerance ? "✓" : "⚠️")"
    }

    var logLine: String {
        "\(formattedPercent) — \(formatDuration(inputSeconds)) → \(formatDuration(outputSeconds))"
    }

    private var formattedPercent: String {
        String(format: "%+.3f%%", percentDelta)
    }
}
