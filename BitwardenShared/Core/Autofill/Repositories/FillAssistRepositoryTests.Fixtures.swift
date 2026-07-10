// swiftlint:disable:this file_name

import CryptoKit
import Foundation

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - FillAssistRepositoryTests Fixtures

extension FillAssistRepositoryTests {
    /// Computes the same sorted-keys SHA-256 fingerprint the production code uses, so tests can
    /// pre-populate `keychainRepository` with a value that will pass integrity verification.
    func fingerprint(for data: FillAssistCachedData) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(data).generatedHash(using: SHA256.self)
    }

    /// Pre-populates `appSettingsStore` with `data` and stores its matching fingerprint in
    /// `keychainRepository`, so the cache will pass integrity verification when read.
    func cacheVerifiedData(_ data: FillAssistCachedData, userId: String = "1") throws {
        appSettingsStore.fillAssistCachedDataByUserId[userId] = data
        keychainRepository.getUserAuthKeyValueReturnValue = try fingerprint(for: data)
    }

    /// Returns a `FillAssistManifestResponseModel` fixture with the given content ID.
    func makeManifest(cid: String) -> FillAssistManifestResponseModel {
        let entry = FillAssistManifestEntryModel(
            cid: cid,
            deprecated: false,
            filename: "forms.v1.json",
            schema: "forms.v1.schema.json",
        )
        return FillAssistManifestResponseModel(
            buildId: "v1",
            gitSha: "abc",
            maps: ["forms": ["v1": entry]],
            timestamp: Date(timeIntervalSinceReferenceDate: 0),
        )
    }

    /// Returns a `FormsMapResponseModel` fixture with a single `example.com` host.
    ///
    /// - Parameters:
    ///   - schemaVersion: The schema version string. Defaults to `"1.0.0"`.
    ///   - usernameSelector: The CSS selector for the username field. Defaults to `"input#user"`.
    ///   - hosts: Optional map of hostname to selector string overriding the default host.
    ///
    func makeFormsMap(
        schemaVersion: String = "1.0.0",
        usernameSelector: String = "input#user",
        hosts: [String: String]? = nil,
    ) -> FormsMapResponseModel {
        let content = { (selector: String) in
            FormsMapContent(
                category: "account-login",
                container: nil,
                fields: ["username": [.single(selector)]],
                actions: nil,
            )
        }
        let resolvedHosts: [String: FormsMapHostEntry] = if let hosts {
            hosts.mapValues { FormsMapHostEntry(forms: [content($0)]) }
        } else {
            ["example.com": FormsMapHostEntry(forms: [content(usernameSelector)])]
        }
        return FormsMapResponseModel(hosts: resolvedHosts, schemaVersion: schemaVersion)
    }

    /// Returns a `FormsMapResponseModel` fixture with both top-level and pathname-specific forms
    /// for `example.com`, used to test selector pooling across multiple entry points.
    func makeFormsMapWithPathnames() -> FormsMapResponseModel {
        let loginContent = FormsMapContent(
            category: "account-login",
            container: nil,
            fields: ["username": [.single("input#user1")]],
            actions: nil,
        )
        let pathnameContent = FormsMapContent(
            category: "account-login",
            container: nil,
            fields: ["username": [.single("input#user2")]],
            actions: nil,
        )
        return FormsMapResponseModel(
            hosts: [
                "example.com": FormsMapHostEntry(
                    forms: [loginContent],
                    pathnames: ["/login": FormsMapPathnameEntry(forms: [pathnameContent])],
                ),
            ],
            schemaVersion: "1.0.0",
        )
    }
}
