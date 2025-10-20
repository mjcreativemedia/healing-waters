// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Retune432App",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .app(name: "Retune432", targets: ["Retune432App"])
    ],
    targets: [
        .executableTarget(
            name: "Retune432App",
            path: "Sources/Retune432App"
        )
    ]
)
