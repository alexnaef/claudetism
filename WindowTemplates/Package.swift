// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WindowTemplates",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WindowTemplates", targets: ["WindowTemplates"])
    ],
    targets: [
        .executableTarget(
            name: "WindowTemplates",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "WindowTemplatesTests",
            dependencies: ["WindowTemplates"]
        )
    ]
)
