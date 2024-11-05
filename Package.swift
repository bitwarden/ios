// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "BitwardenShared",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "AuthenticatorBridgeKit",
            targets: [
                "AuthenticatorBridgeKit",
            ]
        ),
    ],
    targets: [
        .target(
            name: "AuthenticatorBridgeKit",
            path: "AuthenticatorBridgeKit",
            exclude: [
                "Tests/",
            ]
        ),
        .testTarget(
            name: "AuthenticatorBridgeKitTests",
            dependencies: ["AuthenticatorBridgeKit"],
            path: "AuthenticatorBridgeKit/Tests/"
        ),
    ]
)
