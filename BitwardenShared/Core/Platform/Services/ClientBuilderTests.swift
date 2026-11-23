import BitwardenKit
import BitwardenKitMocks
import BitwardenSdkMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class ClientBuilderTests: BitwardenTestCase {
    // MARK: Properties

    var appIDService: AppIDService!
    var clientCertificateService: MockClientCertificateService!
    var clientManagedTokens: MockClientManagedTokens!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var subject: DefaultClientBuilder!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        appIDService = AppIDService(appIDSettingsStore: MockAppIDSettingsStore())
        clientCertificateService = MockClientCertificateService()
        clientManagedTokens = MockClientManagedTokens()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        subject = DefaultClientBuilder(
            appIDService: appIDService,
            clientCertificateService: clientCertificateService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            tokenProvider: clientManagedTokens,
            userAgentBuilder: UserAgentBuilder(
                appName: "TestApp",
                appVersion: "1.0",
                systemDevice: MockSystemDevice(),
            ),
        )
    }

    override func tearDown() {
        super.tearDown()

        appIDService = nil
        clientCertificateService = nil
        clientManagedTokens = nil
        environmentService = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `buildClient(for:)` creates a client.
    func test_buildClient() async {
        let builtClient = await subject.buildClient()

        XCTAssertNotNil(builtClient)
    }

    /// `buildClient()` looks up the current environment's client certificate and builds the client
    /// with it.
    func test_buildClient_withClientCertificate() async throws {
        clientCertificateService.getClientCertificateIdentityReturnValue = try TestIdentity.makeSecIdentity()

        let builtClient = await subject.buildClient()

        XCTAssertNotNil(builtClient)
        XCTAssertTrue(clientCertificateService.getClientCertificateIdentityCalled)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `validateSettings(urls:)` accepts self-hosted URLs without a client certificate.
    func test_validateSettings() async {
        await assertAsyncDoesNotThrow {
            try await subject.validateSettings(urls: EnvironmentURLData(base: URL(string: "https://example.com")!))
        }
        XCTAssertFalse(clientCertificateService.getClientCertificateIdentityFingerprintCalled)
    }

    /// `validateSettings(urls:)` looks up the client certificate by fingerprint and accepts a usable one.
    func test_validateSettings_withClientCertificate() async throws {
        clientCertificateService.getClientCertificateIdentityFingerprintReturnValue = try TestIdentity.makeSecIdentity()

        await assertAsyncDoesNotThrow {
            try await subject.validateSettings(urls: EnvironmentURLData(
                base: URL(string: "https://example.com")!,
                clientCertificateFingerprint: "abc123",
            ))
        }
        XCTAssertEqual(clientCertificateService.getClientCertificateIdentityFingerprintReceivedFingerprint, "abc123")
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `validateSettings(urls:)` throws `invalidCertificate` when the Keychain has no identity for the
    /// fingerprint.
    func test_validateSettings_clientCertificateMissing() async {
        clientCertificateService.getClientCertificateIdentityFingerprintReturnValue = nil

        await assertAsyncThrows(error: ClientCertificateError.invalidCertificate) {
            try await subject.validateSettings(urls: EnvironmentURLData(
                base: URL(string: "https://example.com")!,
                clientCertificateFingerprint: "abc123",
            ))
        }
    }

    /// `validateSettings(urls:)` logs the Keychain error and throws `invalidCertificate` when the
    /// identity lookup fails.
    func test_validateSettings_clientCertificateLookupThrows() async {
        clientCertificateService.getClientCertificateIdentityFingerprintThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: ClientCertificateError.invalidCertificate) {
            try await subject.validateSettings(urls: EnvironmentURLData(
                base: URL(string: "https://example.com")!,
                clientCertificateFingerprint: "abc123",
            ))
        }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }
}
