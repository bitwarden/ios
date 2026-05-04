import XCTest

@testable import AuthenticatorBridgeKit

final class AuthenticatorBridgeDataStoreTests: XCTestCase {
    func test_persistedStoreURL_prefersAppGroupContainer() {
        let subject = AuthenticatorBridgeDataStore.persistedStoreURL(
            groupIdentifier: "group.com.8bit.bitwarden",
            bundleIdentifier: "com.8bit.bitwarden",
            bundlePath: "/tmp/Bitwarden.app",
            containerURLProvider: { _, _ in URL(fileURLWithPath: "/tmp/group-container", isDirectory: true) }
        )

        XCTAssertEqual(subject.path, "/tmp/group-container/Bitwarden-Authenticator.sqlite")
    }

    func test_persistedStoreURL_fallsBackForSimulatorAppExtension() {
        let fileManager = FileManager.default
        let subject = AuthenticatorBridgeDataStore.persistedStoreURL(
            fileManager: fileManager,
            groupIdentifier: "group.com.8bit.bitwarden",
            bundleIdentifier: "com.8bit.bitwarden.find-login-action-extension",
            bundlePath: "/tmp/BitwardenActionExtension.appex",
            containerURLProvider: { _, _ in nil }
        )

        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        XCTAssertEqual(
            subject.path,
            applicationSupportURL
                .appendingPathComponent("com.8bit.bitwarden.find-login-action-extension", isDirectory: true)
                .appendingPathComponent("Bitwarden-Authenticator.sqlite")
                .path
        )
    }
}
