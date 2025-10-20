import SwiftUI

struct PreferencesView: View {
    @AppStorage("bitDepth") private var bitDepth: Int = 24
    @AppStorage("rememberOutput") private var rememberOutput: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences").font(.title3).bold()

            Picker("Bit depth", selection: $bitDepth) {
                Text("24-bit PCM").tag(24)
                Text("16-bit PCM").tag(16)
            }
            .pickerStyle(.segmented)

            Toggle("Remember last output folder", isOn: $rememberOutput)

            Spacer()
        }
        .padding(20)
        .frame(width: 380, height: 200)
    }
}
