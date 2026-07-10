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
        #expect(try keychainRepository.setUserAuthKeyReceivedArguments?.value == fingerprint(for: cached))
    }

    // MARK: Tests - fingerprint determinism

    /// The sorted-keys fingerprint is deterministic across an encode-decode-encode round trip,
    /// regardless of dictionary iteration order — a false positive here would incorrectly treat
    /// legitimate, unmodified data as tampered.
    @Test
    func fingerprint_encodingDeterminism_noFalsePositiveAcrossRoundTrip() throws {
        for iteration in 0 ..< 10 {
            let data = FillAssistCachedData(
                cid: "sha256:abc\(iteration)",
                rules: [
                    "example.com": FillAssistHostRules(fields: [
                        "username": [.init(id: "user", name: "user", role: nil, tagName: "input", type: "text")],
                        "password": [.init(id: "pass", name: "pass", role: nil, tagName: "input", type: "password")],
                    ]),
                    "other.com": FillAssistHostRules(fields: [
                        "username": [.init(id: "u2", name: nil, role: nil, tagName: "input", type: nil)],
                        "email": [.init(id: "e2", name: nil, role: nil, tagName: "input", type: nil)],
                    ]),
                    "third.com": FillAssistHostRules(fields: [
                        "otp": [.init(id: "o3", name: nil, role: nil, tagName: nil, type: nil)],
                    ]),
                ],
                sourceUrl: "https://cdn.example.com/rules.json",
            )

            let originalFingerprint = try fingerprint(for: data)
            let roundTripped = try JSONDecoder().decode(FillAssistCachedData.self, from: JSONEncoder().encode(data))
            let roundTrippedFingerprint = try fingerprint(for: roundTripped)

            #expect(originalFingerprint == roundTrippedFingerprint)
        }
    }
}
