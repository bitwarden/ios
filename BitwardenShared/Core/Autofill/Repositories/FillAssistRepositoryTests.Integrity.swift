// swiftlint:disable:this file_name

import BitwardenKit
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - FillAssistRepositoryTests Integrity

extension FillAssistRepositoryTests {
    // MARK: Tests - rules(for:) integrity

    /// `rules(for:)` returns `nil` and clears the cache when the stored fingerprint doesn't
    /// match the cached data (tampered).
    @Test
    func rules_returnsNil_andClearsCache_whenFingerprintMismatched() async {
        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc",
            rules: ["example.com": FillAssistHostRules(fields: ["username": []])],
            sourceUrl: "https://example.com",
        )
        keychainRepository.getUserAuthKeyValueReturnValue = "deadbeef"

        let result = await subject.rules(for: "example.com")

        #expect(result == nil)
        #expect(appSettingsStore.fillAssistCachedDataByUserId["1"] == nil)
        #expect(keychainRepository.deleteUserAuthKeyCalled)
    }

    /// `rules(for:)` returns `nil` and clears the cache when cached data exists but no
    /// fingerprint was ever stored (e.g. a pre-upgrade cache with no integrity data).
    @Test
    func rules_returnsNil_whenFingerprintMissing_cachedDataPresent() async {
        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc",
            rules: ["example.com": FillAssistHostRules(fields: ["username": []])],
            sourceUrl: "https://example.com",
        )
        keychainRepository.getUserAuthKeyValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.fillAssistRulesFingerprint(userId: "1"),
        )

        let result = await subject.rules(for: "example.com")

        #expect(result == nil)
        #expect(appSettingsStore.fillAssistCachedDataByUserId["1"] == nil)
    }

    /// `rules(for:)` returns `nil` and clears any stray fingerprint when no cached data exists,
    /// regardless of whether a fingerprint happens to be present.
    @Test
    func rules_returnsNil_whenCachedDataAbsent() async {
        let result = await subject.rules(for: "example.com")

        #expect(result == nil)
        #expect(keychainRepository.deleteUserAuthKeyCalled)
    }

    // MARK: Tests - syncRules() integrity

    /// `syncRules()` redownloads and recreates the fingerprint when the cache's cid/sourceUrl
    /// would normally short-circuit the sync, but its fingerprint is tampered.
    @Test
    func performSync_tamperedCache_redownloadsAndRecreatesFingerprint() async throws {
        configService.featureFlagsBool[.fillAssistTargetingRules] = true
        let sourceUrl = environmentService.fillAssistRulesURL.absoluteString
        appSettingsStore.fillAssistCachedDataByUserId["1"] = FillAssistCachedData(
            cid: "sha256:abc123",
            rules: [:],
            sourceUrl: sourceUrl,
        )
        keychainRepository.getUserAuthKeyValueReturnValue = "tampered"
        fillAssistAPIService.getManifestReturnValue = makeManifest(cid: "sha256:abc123")
        fillAssistAPIService.getFormsMapReturnValue = makeFormsMap()

        await subject.syncRules()

        #expect(fillAssistAPIService.getManifestCalled)
        #expect(fillAssistAPIService.getFormsMapCalled)
        let cached = try #require(appSettingsStore.fillAssistCachedDataByUserId["1"])
        #expect(cached.cid == "sha256:abc123")
        #expect(keychainRepository.setUserAuthKeyCalled)
        #expect(
            keychainRepository.setUserAuthKeyReceivedArguments?.value
                == dataFingerprintService.fingerprintReturnValue,
        )
    }
}
