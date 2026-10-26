// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AgentAccessSdk",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "AgentAccessSdk", targets: ["AgentAccessSdk"]),
    ],
    targets: [
        .binaryTarget(
            name: "ap_uniffiBinary",
            path: "Frameworks/ap_uniffiFFI.xcframework",
        ),
        .target(
            name: "ap_uniffiFFI",
            dependencies: ["ap_uniffiBinary"],
            path: "Sources/ap_uniffiFFI",
        ),
        .target(
            name: "AgentAccessSdk",
            dependencies: ["ap_uniffiFFI"],
            path: "Sources/AgentAccessSdk",
            linkerSettings: [
                .linkedFramework("Security"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("SystemConfiguration"),
                .linkedLibrary("resolv"),
            ],
        ),
    ],
    swiftLanguageVersions: [.v5],
)
