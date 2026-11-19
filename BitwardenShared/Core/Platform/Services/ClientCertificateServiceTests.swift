import BitwardenKit
import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct ClientCertificateServiceTests {
    // MARK: Type Properties

    // A base64-encoded PKCS#12 (password: "testpassword") containing a client leaf certificate,
    // its private key, and one intermediate CA certificate. Used to exercise the chain-extraction
    // path in `importCertificate(data:password:alias:)` and to build a `SecIdentity` for
    // `getClientCertificate()` tests.
    // swiftlint:disable:next line_length
    static let testChainP12Base64 = "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"

    // A base64-encoded, DER-encoded self-signed X.509 certificate used to exercise the
    // `SecCertificate` decoding path in `getClientCertificate()`.
    // swiftlint:disable:next line_length
    static let testCertificateDER = "MIIDLTCCAhWgAwIBAgIUKLVeVHwoIoz0vbzJIDkMrnrzIWwwDQYJKoZIhvcNAQELBQAwJjEkMCIGA1UEAwwbQml0d2FyZGVuIFRlc3QgSW50ZXJtZWRpYXRlMB4XDTI2MDYyNTE1MDYxMFoXDTM2MDYyMjE1MDYxMFowJjEkMCIGA1UEAwwbQml0d2FyZGVuIFRlc3QgSW50ZXJtZWRpYXRlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0jaQhKUblgbDRTfb2nXH+gGY7usCpV19XKRf9y0MSpf3E5XnJ+SlQgZP8L27JzNkyJ/MZNpJXSxIuT/bINoW+pdMxZj0ROqt149XdSfhtIxCSVLAVwVGCMRxeFKVRuo0XH3NGztrTP2kdFGqWNZE6QE43ajqfCrf55kaP7PYWuSY1Kst/+vrX8m8mt6/8fzX8i3CdCVkAUCuCStr1HPFXVJMoopND4DxbtFeqT+FsjFECM1GvS4pGWHzEqeS+dXnpr5lEc6MI16rvAOuyUz1S22h3domiA2icFZIj3D6MMYwVNug0DpMQgw7KuyCtzxz+Dg4uR9rvYkFqSffSCMlqwIDAQABo1MwUTAdBgNVHQ4EFgQUM9mUBrX6Ai1O7a0OXu0gQtnwzLcwHwYDVR0jBBgwFoAUM9mUBrX6Ai1O7a0OXu0gQtnwzLcwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEArdMVgUV/D0hnP8tickNNbVkZl1ahGQp/JkiLvpaX6v8mic+CiLQx07veBLNC2TYQWo/Sa20w584oQznFpiVeLKLr7dpCbnxwia6EvbB4Qcw7JRy5+60ET6eYMmlzTBEKlWO9cvtVq8V1rl/dnOONPnChw4InR4ZNsphG+1xvs9MRITuh46RJlhiZHJjqwqOcr8dcFFIe/KHsLxm2zNt8seUcR+R3A1yr/7QAQFCqmo4fWBtesYVoMbWUUIUmSa06m28vvbCXNUtw1sLjr2EiLhPFTEQCCEvlo6+gGDJEY4B9YHVLOMVlyXCIp7elGbMlj3dOeYRgRUQKVtOtyTXTuQ=="

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

    // MARK: Tests - getClientCertificate()

    /// `getClientCertificate()` returns nil when no fingerprint is in the environment, without
    /// touching the keychain.
    @Test
    func getClientCertificate_noFingerprint_returnsNil() async {
        environmentService.clientCertificateFingerprint = nil

        let result = await subject.getClientCertificate()

        #expect(result == nil)
        #expect(!keychainRepository.getClientCertificateIdentityCalled)
    }

    /// `getClientCertificate()` returns nil when the fingerprint is empty, without touching the
    /// keychain.
    @Test
    func getClientCertificate_emptyFingerprint_returnsNil() async {
        environmentService.clientCertificateFingerprint = ""

        let result = await subject.getClientCertificate()

        #expect(result == nil)
        #expect(!keychainRepository.getClientCertificateIdentityCalled)
    }

    /// `getClientCertificate()` returns nil when the fingerprint is set but the keychain identity
    /// is missing, and does not attempt to read the chain.
    @Test
    func getClientCertificate_identityMissing_returnsNil() async {
        environmentService.clientCertificateFingerprint = "missing-from-keychain"
        keychainRepository.getClientCertificateIdentityReturnValue = nil

        let result = await subject.getClientCertificate()

        #expect(result == nil)
        #expect(!keychainRepository.getClientCertificateChainCalled)
    }

    /// `getClientCertificate()` returns nil and logs an error when reading the identity throws.
    @Test
    func getClientCertificate_identityKeychainThrows_logsErrorAndReturnsNil() async {
        let error = BitwardenTestError.example
        environmentService.clientCertificateFingerprint = "some-fingerprint"
        keychainRepository.getClientCertificateIdentityThrowableError = error

        let result = await subject.getClientCertificate()

        #expect(result == nil)
        #expect(errorReporter.errors as? [BitwardenTestError] == [error])
    }

    /// `getClientCertificate()` returns the identity with empty intermediates when no chain is
    /// stored (e.g. a legacy certificate that has only an identity in the keychain).
    @Test
    func getClientCertificate_noChain_returnsCertificateWithEmptyIntermediates() async throws {
        environmentService.clientCertificateFingerprint = "some-fingerprint"
        keychainRepository.getClientCertificateIdentityReturnValue = try makeTestIdentity()
        keychainRepository.getClientCertificateChainReturnValue = nil

        let result = await subject.getClientCertificate()

        #expect(result != nil)
        #expect(result?.intermediates.isEmpty == true)
    }

    /// `getClientCertificate()` still returns the identity (degrading to leaf-only) and logs an
    /// error when reading the chain throws, so configurations that don't need the chain keep working.
    @Test
    func getClientCertificate_chainKeychainThrows_logsErrorAndDegradesToLeaf() async throws {
        let error = BitwardenTestError.example
        environmentService.clientCertificateFingerprint = "some-fingerprint"
        keychainRepository.getClientCertificateIdentityReturnValue = try makeTestIdentity()
        keychainRepository.getClientCertificateChainThrowableError = error

        let result = await subject.getClientCertificate()

        #expect(result != nil)
        #expect(result?.intermediates.isEmpty == true)
        #expect(errorReporter.errors as? [BitwardenTestError] == [error])
    }

    /// `getClientCertificate()` filters out stored chain data that is not a valid certificate.
    @Test
    func getClientCertificate_invalidChainData_returnsCertificateWithEmptyIntermediates() async throws {
        environmentService.clientCertificateFingerprint = "some-fingerprint"
        keychainRepository.getClientCertificateIdentityReturnValue = try makeTestIdentity()
        keychainRepository.getClientCertificateChainReturnValue = [Data([0x00, 0x01, 0x02])]

        let result = await subject.getClientCertificate()

        #expect(result != nil)
        #expect(result?.intermediates.isEmpty == true)
    }

    /// `getClientCertificate()` decodes stored DER chain data into `SecCertificate`s alongside the
    /// identity for the current environment fingerprint.
    @Test
    func getClientCertificate_validChain_returnsCertificateWithIntermediates() async throws {
        let fingerprint = "some-fingerprint"
        let der = try #require(Data(base64Encoded: Self.testCertificateDER))
        environmentService.clientCertificateFingerprint = fingerprint
        keychainRepository.getClientCertificateIdentityReturnValue = try makeTestIdentity()
        keychainRepository.getClientCertificateChainReturnValue = [der]

        let result = await subject.getClientCertificate()

        #expect(result?.intermediates.count == 1)
        #expect(keychainRepository.getClientCertificateChainReceivedFingerprint == fingerprint)
    }

    // MARK: Tests - importCertificate(data:password:alias:)

    /// `importCertificate(data:password:alias:)` stores the identity and the intermediate chain
    /// (excluding the leaf) when importing a PKCS#12 that contains an intermediate certificate.
    @Test
    func importCertificate_storesIdentityAndIntermediateChain() async throws {
        let p12 = try #require(Data(base64Encoded: Self.testChainP12Base64))

        let fingerprint = try await subject.importCertificate(data: p12, password: "testpassword", alias: "Chain Cert")

        // The identity (leaf + private key) is stored under the fingerprint.
        #expect(keychainRepository.setClientCertificateIdentityCalled)
        #expect(keychainRepository.setClientCertificateIdentityReceivedArguments?.fingerprint == fingerprint)

        // The intermediate (but not the leaf) is stored as the chain.
        #expect(keychainRepository.setClientCertificateChainReceivedArguments?.fingerprint == fingerprint)
        #expect(keychainRepository.setClientCertificateChainReceivedArguments?.chain.count == 1)
    }

    /// `importCertificate(data:password:alias:)` throws `invalidPassword` when the PKCS#12 password
    /// is incorrect, and stores nothing.
    @Test
    func importCertificate_invalidPassword_throws() async throws {
        let p12 = try #require(Data(base64Encoded: Self.testChainP12Base64))

        await #expect(throws: ClientCertificateError.invalidPassword) {
            _ = try await subject.importCertificate(data: p12, password: "wrong-password", alias: "Chain Cert")
        }
        #expect(!keychainRepository.setClientCertificateIdentityCalled)
        #expect(!keychainRepository.setClientCertificateChainCalled)
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
        #expect(keychainRepository.deleteClientCertificateChainReceivedFingerprint == fingerprint)
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
        #expect(keychainRepository.deleteClientCertificateChainReceivedFingerprint == fingerprint)
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

    // MARK: Private

    /// Imports the embedded test chain PKCS#12 and returns its `SecIdentity` (leaf + private key).
    private func makeTestIdentity() throws -> SecIdentity {
        guard let p12 = Data(base64Encoded: Self.testChainP12Base64) else {
            throw BitwardenTestError.example
        }
        var importResult: CFArray?
        let status = SecPKCS12Import(
            p12 as CFData,
            [kSecImportExportPassphrase: "testpassword"] as CFDictionary,
            &importResult,
        )
        guard status == errSecSuccess,
              let items = importResult as? [[String: Any]],
              let identityRef = items.first?[kSecImportItemIdentity as String] else {
            throw BitwardenTestError.example
        }
        // swiftlint:disable:next force_cast
        return identityRef as! SecIdentity
    }
}
