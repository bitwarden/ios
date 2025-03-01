// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]
        ),
    ],
    targets: [
        .target(name: "Networking",
                // TODO: PM-11195
                // This package can be updated to Swift 6, and this feature enablement removed
                swiftSettings: [
                    .enableExperimentalFeature("StrictConcurrency"),
                ]),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"]
        ),
    ]
)
