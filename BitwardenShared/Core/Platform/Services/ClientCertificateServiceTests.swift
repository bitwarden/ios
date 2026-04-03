import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

final class ClientCertificateServiceTests: BitwardenTestCase {
    // MARK: Properties

    var environmentService: MockEnvironmentService!
    var keychainRepository: MockKeychainRepository!
    var stateService: MockStateService!
    var subject: DefaultClientCertificateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        environmentService = MockEnvironmentService()
        keychainRepository = MockKeychainRepository()
        stateService = MockStateService()
        subject = DefaultClientCertificateService(
            environmentService: environmentService,
            keychainRepository: keychainRepository,
            stateService: stateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        environmentService = nil
        keychainRepository = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests - removeCertificate(userId:)

    /// `removeCertificate(userId:)` keeps the keychain identity when another account references
    /// the same certificate fingerprint in its environment URLs.
    func test_removeCertificate_sharedFingerprintAcrossAccounts_doesNotDeleteKeychainIdentity() async throws {
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

        XCTAssertEqual(keychainRepository.deleteClientCertIdentityFingerprints, [])
    }

    /// `removeCertificate(userId:)` deletes the keychain identity when the removed user is the
    /// last reference to the certificate fingerprint.
    func test_removeCertificate_lastFingerprintReference_deletesKeychainIdentity() async throws {
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

        XCTAssertEqual(keychainRepository.deleteClientCertIdentityFingerprints, [fingerprint])
    }

    /// `removeCertificate(userId:)` keeps the keychain identity when the pre-auth environment URLs
    /// still reference the same certificate fingerprint.
    func test_removeCertificate_sharedWithPreAuth_doesNotDeleteKeychainIdentity() async throws {
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

        XCTAssertEqual(keychainRepository.deleteClientCertIdentityFingerprints, [])
    }

    /// `removeCertificate(userId:)` succeeds gracefully when no certificate is configured.
    func test_removeCertificate_noCertConfigured_succeeds() async throws {
        let user1 = "1"

        stateService.accounts = [
            .fixture(profile: .fixture(userId: user1)),
        ]
        stateService.activeAccount = .fixture(profile: .fixture(userId: user1))
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
        )

        try await subject.removeCertificate(userId: user1)

        XCTAssertEqual(keychainRepository.deleteClientCertIdentityFingerprints, [])
    }

    // MARK: Tests - removeCertificate(fingerprint:)

    /// `removeCertificate(fingerprint:)` deletes the keychain identity when no other account
    /// references the given fingerprint.
    func test_removeCertificate_fingerprint_deletesKeychainIdentity() async throws {
        let fingerprint = "current-env-fingerprint"

        stateService.accounts = []

        try await subject.removeCertificate(fingerprint: fingerprint)

        XCTAssertEqual(keychainRepository.deleteClientCertIdentityFingerprints, [fingerprint])
    }

    /// `removeCertificate(fingerprint:)` keeps the keychain identity when another account
    /// references the same fingerprint.
    func test_removeCertificate_fingerprint_sharedFingerprint_doesNotDeleteKeychainIdentity() async throws {
        let user1 = "1"
        let fingerprint = "shared-fingerprint"

        stateService.accounts = [.fixture(profile: .fixture(userId: user1))]
        stateService.environmentURLs[user1] = EnvironmentURLData(
            base: URL(string: "https://example.com"),
            clientCertificateAlias: "Cert A",
            clientCertificateFingerprint: fingerprint,
        )

        try await subject.removeCertificate(fingerprint: fingerprint)

        XCTAssertEqual(keychainRepository.deleteClientCertIdentityFingerprints, [])
    }

    // MARK: Tests - getClientCertificateIdentity()

    /// `getClientCertificateIdentity()` returns nil when no fingerprint is in the environment.
    func test_getClientCertificateIdentity_noFingerprint_returnsNil() async {
        environmentService.clientCertificateFingerprint = nil

        let result = await subject.getClientCertificateIdentity()

        XCTAssertNil(result)
    }

    /// `getClientCertificateIdentity()` returns nil when the fingerprint is set but the keychain
    /// identity is missing.
    func test_getClientCertificateIdentity_fingerprintSetButKeychainMissing_returnsNil() async {
        environmentService.clientCertificateFingerprint = "missing-from-keychain"

        let result = await subject.getClientCertificateIdentity()

        XCTAssertNil(result)
    }

    // MARK: Tests - getCertificateAlias()

    /// `getCertificateAlias()` returns nil when no alias is in the environment.
    func test_getCertificateAlias_noAlias_returnsNil() async {
        environmentService.clientCertificateAlias = nil

        let result = await subject.getCertificateAlias()

        XCTAssertNil(result)
    }

    /// `getCertificateAlias()` returns nil when the alias is set but the keychain identity is missing.
    func test_getCertificateAlias_aliasSetButKeychainMissing_returnsNil() async {
        environmentService.clientCertificateAlias = "My Cert"
        environmentService.clientCertificateFingerprint = "missing-from-keychain"

        let result = await subject.getCertificateAlias()

        XCTAssertNil(result)
    }
}
