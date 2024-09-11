// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "BitwardenShared",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "AuthenticatorSyncKit",
            targets: [
                "AuthenticatorSyncKit",
            ]
        ),
    ],
    targets: [
        .target(
            name: "AuthenticatorSyncKit",
            path: "AuthenticatorSyncKit",
            exclude: [
                "Tests/",
            ]
        ),
        .testTarget(
            name: "AuthenticatorSyncKitTests",
            dependencies: ["AuthenticatorSyncKit"],
            path: "AuthenticatorSyncKit/Tests/"
        ),
    ]
)
