// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Spellbreak",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Spellbreak",
            targets: ["Spellbreak"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Spellbreak",
            path: "Sources/Eyedrop",
            exclude: [
                "Resources/Info.plist"
            ],
            resources: [
                .process("Resources/Sounds"),
                .process("Resources/Assets.xcassets")
            ],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"])
            ]
        )
    ]
)