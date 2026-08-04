import Foundation
import XCTest

@testable import BitwardenShared

final class DataStoreTests: BitwardenTestCase {
    func test_persistedStoreURL_prefersAppGroupContainer() {
        let subject = DataStore.persistedStoreURL(
            groupIdentifier: "group.com.8bit.bitwarden",
            bundleIdentifier: "com.8bit.bitwarden",
            bundlePath: "/tmp/Bitwarden.app",
            containerURLProvider: { _, _ in URL(fileURLWithPath: "/tmp/group-container", isDirectory: true) }
        )

        XCTAssertEqual(subject.path, "/tmp/group-container/Bitwarden.sqlite")
    }

    func test_persistedStoreURL_fallsBackForSimulatorAppExtension() {
        let fileManager = FileManager.default
        let subject = DataStore.persistedStoreURL(
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
                .appendingPathComponent("Bitwarden.sqlite")
                .path
        )
    }

    func test_persistedStoreURL_fallsBackToTemporaryDirectoryForNonExtension() {
        let fileManager = FileManager.default
        let subject = DataStore.persistedStoreURL(
            fileManager: fileManager,
            groupIdentifier: "group.com.8bit.bitwarden",
            bundleIdentifier: "com.8bit.bitwarden",
            bundlePath: "/tmp/Bitwarden.app",
            containerURLProvider: { _, _ in nil }
        )

        XCTAssertEqual(subject.path, fileManager.temporaryDirectory.appendingPathComponent("Bitwarden.sqlite").path)
    }
}
