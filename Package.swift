// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "BitwardenShared",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "AuthenticatorSyncShared",
            targets: [
                "AuthenticatorSyncShared",
            ]
        ),
    ],
    targets: [
        .target(
            name: "AuthenticatorSyncShared",
            path: "AuthenticatorSyncShared",
            exclude: [
                "Tests/",
            ]
        ),
        .testTarget(
            name: "AuthenticatorSyncSharedTests",
            dependencies: ["AuthenticatorSyncShared"],
            path: "AuthenticatorSyncShared/Tests/"
        ),
    ]
)
