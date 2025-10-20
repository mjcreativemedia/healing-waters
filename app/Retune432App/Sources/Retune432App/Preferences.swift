import SwiftUI
import AppKit

enum BitDepthOption: String, CaseIterable, Identifiable {
    case pcm_s24le
    case pcm_s16le

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pcm_s24le:
            return "24-bit PCM"
        case .pcm_s16le:
            return "16-bit PCM"
        }
    }

    var detailText: String {
        switch self {
        case .pcm_s24le:
            return "High fidelity 24-bit WAV output (pcm_s24le)"
        case .pcm_s16le:
            return "Compact 16-bit WAV output (pcm_s16le)"
        }
    }

    var ffmpegCodec: String {
        rawValue
    }
}

final class PreferencesStore: ObservableObject {
    private enum Keys {
        static let bitDepth = "retune432.bitDepth"
        static let output = "retune432.outputDirectory"
    }

    @Published var bitDepth: BitDepthOption {
        didSet {
            userDefaults.set(bitDepth.rawValue, forKey: Keys.bitDepth)
        }
    }

    @Published var defaultOutputFolder: URL? {
        didSet {
            if let url = defaultOutputFolder {
                userDefaults.set(url.path, forKey: Keys.output)
            } else {
                userDefaults.removeObject(forKey: Keys.output)
            }
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let storedDepth = userDefaults.string(forKey: Keys.bitDepth),
           let option = BitDepthOption(rawValue: storedDepth) {
            bitDepth = option
        } else {
            bitDepth = .pcm_s24le
        }

        if let path = userDefaults.string(forKey: Keys.output) {
            defaultOutputFolder = URL(fileURLWithPath: path)
        } else {
            defaultOutputFolder = nil
        }
    }
}

struct PreferencesView: View {
    @ObservedObject var preferences: PreferencesStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Preferences")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 12) {
                Text("Default bit depth")
                    .font(.headline)
                Picker("Default bit depth", selection: $preferences.bitDepth) {
                    ForEach(BitDepthOption.allCases) { option in
                        Text(option.displayName)
                            .tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Text(preferences.bitDepth.detailText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Default output folder")
                    .font(.headline)
                Text(preferences.defaultOutputFolder?.path ?? "Use last selected output folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)

                HStack(spacing: 12) {
                    Button("Choose…") {
                        if let url = openFolderPanel(title: "Select Default Output Folder") {
                            preferences.defaultOutputFolder = url
                        }
                    }
                    if preferences.defaultOutputFolder != nil {
                        Button("Clear") {
                            preferences.defaultOutputFolder = nil
                        }
                    }
                    Spacer()
                }

                Text("When empty, the app remembers the last output folder you pick during export.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 300)
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
}
