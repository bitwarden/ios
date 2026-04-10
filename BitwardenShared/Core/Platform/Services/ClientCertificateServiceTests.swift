import BitwardenKit
import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct ClientCertificateServiceTests {
    // MARK: Properties

    var environmentService: MockEnvironmentService
    var errorReporter: MockErrorReporter
    var keychainRepository: MockKeychainRepository
    var stateService: MockStateService
    var subject: DefaultClientCertificateService

    // MARK: Initialization

    init() {
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        keychainRepository = MockKeychainRepository()
        stateService = MockStateService()
        subject = DefaultClientCertificateService(
            environmentService: environmentService,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            stateService: stateService,
        )
    }

    // MARK: Tests - getClientCertificateIdentity()

    /// `getClientCertificateIdentity()` returns nil when the fingerprint is set but the keychain
    /// identity is missing.
    @Test
    func getClientCertificateIdentity_fingerprintSetButKeychainMissing_returnsNil() async {
        environmentService.clientCertificateFingerprint = "missing-from-keychain"

        let result = await subject.getClientCertificateIdentity()

        #expect(result == nil)
    }

    /// `getClientCertificateIdentity()` returns nil and logs an error when the keychain throws an
    /// unexpected error.
    @Test
    func getClientCertificateIdentity_keychainThrows_logsErrorAndReturnsNil() async {
        let error = BitwardenTestError.example
        environmentService.clientCertificateFingerprint = "some-fingerprint"
        keychainRepository.getClientCertificateIdentityThrowableError = error

        let result = await subject.getClientCertificateIdentity()

        #expect(result == nil)
        #expect(errorReporter.errors as? [BitwardenTestError] == [error])
    }

    /// `getClientCertificateIdentity()` returns nil when no fingerprint is in the environment.
    @Test
    func getClientCertificateIdentity_noFingerprint_returnsNil() async {
        environmentService.clientCertificateFingerprint = nil

        let result = await subject.getClientCertificateIdentity()

        #expect(result == nil)
    }

    // MARK: Tests - removeCertificate(fingerprint:)

    /// `removeCertificate(fingerprint:)` deletes the keychain identity when no other account
    /// references the given fingerprint.
    @Test
    func removeCertificate_fingerprint_deletesKeychainIdentity() async throws {
        let fingerprint = "current-env-fingerprint"

        stateService.accounts = []

        try await subject.removeCertificate(fingerprint: fingerprint)

        #expect(keychainRepository.deleteClientCertificateIdentityReceivedFingerprint == fingerprint)
    }

    /// `removeCertificate(fingerprint:)` keeps the keychain identity when another account
    /// references the same fingerprint.
    @Test
    func removeCertificate_fingerprint_sharedFingerprint_doesNotDeleteKeychainIdentity() async throws {
        let user1 = "1"
        let fingerprint = "shared-fingerprint"

        stateService.accounts = [.fixture(profile: .fixture(userId: user1))]
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            clientCertificateAlias: "Cert A",
            clientCertificateFingerprint: fingerprint,
        )

        try await subject.removeCertificate(fingerprint: fingerprint)

        #expect(!keychainRepository.deleteClientCertificateIdentityCalled)
    }

    // MARK: Tests - removeCertificate(userId:)

    /// `removeCertificate(userId:)` deletes the keychain identity when the removed user is the
    /// last reference to the certificate fingerprint.
    @Test
    func removeCertificate_lastFingerprintReference_deletesKeychainIdentity() async throws {
        let user1 = "1"
        let fingerprint = "only-fingerprint"

        stateService.accounts = [
            .fixture(profile: .fixture(userId: user1)),
        ]
        stateService.activeAccount = .fixture(profile: .fixture(userId: user1))
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            clientCertificateAlias: "Cert A",
            clientCertificateFingerprint: fingerprint,
        )

        try await subject.removeCertificate(userId: user1)

        #expect(keychainRepository.deleteClientCertificateIdentityReceivedFingerprint == fingerprint)
    }

    /// `removeCertificate(userId:)` succeeds gracefully when no certificate is configured.
    @Test
    func removeCertificate_noCertConfigured_succeeds() async throws {
        let user1 = "1"

        stateService.accounts = [
            .fixture(profile: .fixture(userId: user1)),
        ]
        stateService.activeAccount = .fixture(profile: .fixture(userId: user1))
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
        )

        try await subject.removeCertificate(userId: user1)

        #expect(!keychainRepository.deleteClientCertificateIdentityCalled)
    }

    /// `removeCertificate(userId:)` keeps the keychain identity when another account references
    /// the same certificate fingerprint in its environment URLs.
    @Test
    func removeCertificate_sharedFingerprintAcrossAccounts_doesNotDeleteKeychainIdentity() async throws {
        let user1 = "1"
        let user2 = "2"
        let fingerprint = "shared-fingerprint"

        stateService.accounts = [
            .fixture(profile: .fixture(userId: user1)),
            .fixture(profile: .fixture(userId: user2)),
        ]
        stateService.activeAccount = .fixture(profile: .fixture(userId: user1))
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            clientCertificateAlias: "Cert A",
            clientCertificateFingerprint: fingerprint,
        )
        stateService.environmentURLs[user2] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            clientCertificateAlias: "Cert B",
            clientCertificateFingerprint: fingerprint,
        )

        try await subject.removeCertificate(userId: user1)

        #expect(!keychainRepository.deleteClientCertificateIdentityCalled)
    }

    /// `removeCertificate(userId:)` keeps the keychain identity when the pre-auth environment URLs
    /// still reference the same certificate fingerprint.
    @Test
    func removeCertificate_sharedWithPreAuth_doesNotDeleteKeychainIdentity() async throws {
        let user1 = "1"
        let fingerprint = "shared-with-preauth"

        stateService.accounts = [
            .fixture(profile: .fixture(userId: user1)),
        ]
        stateService.activeAccount = .fixture(profile: .fixture(userId: user1))
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            clientCertificateAlias: "Cert A",
            clientCertificateFingerprint: fingerprint,
        )
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            clientCertificateAlias: "PreAuth Cert",
            clientCertificateFingerprint: fingerprint,
        )

        try await subject.removeCertificate(userId: user1)

        #expect(!keychainRepository.deleteClientCertificateIdentityCalled)
    }
}
