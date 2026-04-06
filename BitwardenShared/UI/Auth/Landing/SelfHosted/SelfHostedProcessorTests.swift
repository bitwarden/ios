import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class SelfHostedProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var clientCertificateService: MockClientCertificateService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var delegate: MockSelfHostedProcessorDelegate!
    var errorReporter: MockErrorReporter!
    var services: ServiceContainer!
    var subject: SelfHostedProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        clientCertificateService = MockClientCertificateService()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        delegate = MockSelfHostedProcessorDelegate()
        errorReporter = MockErrorReporter()
        services = ServiceContainer.withMocks(
            clientCertificateService: clientCertificateService,
            errorReporter: errorReporter,
        )
        subject = SelfHostedProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: SelfHostedState(),
        )

        super.setUp()
    }

    override func tearDown() {
        clientCertificateService = nil
        coordinator = nil
        delegate = nil
        errorReporter = nil
        services = nil
        subject = nil

        super.tearDown()
    }

    // MARK: Tests

    /// `perform(_:)` with `.saveEnvironment` notifies the delegate that the user saved the URLs.
    @MainActor
    func test_perform_saveEnvironment() async throws {
        subject.state.serverUrl = "vault.bitwarden.com"

        await subject.perform(.saveEnvironment)

        XCTAssertEqual(
            delegate.savedUrls,
            EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com")!),
        )
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// `perform(_:)` with `.saveEnvironment` notifies the delegate that the user saved the URLs.
    @MainActor
    func test_perform_saveEnvironment_multipleURLs() async throws {
        subject.state.apiServerUrl = "vault.bitwarden.com/api"
        subject.state.iconsServerUrl = "icons.bitwarden.com"
        subject.state.identityServerUrl = "https://vault.bitwarden.com/identity"
        subject.state.serverUrl = "vault.bitwarden.com"
        subject.state.webVaultServerUrl = "https://vault.bitwarden.com"

        await subject.perform(.saveEnvironment)

        XCTAssertEqual(
            delegate.savedUrls,
            EnvironmentURLData(
                api: URL(string: "https://vault.bitwarden.com/api")!,
                base: URL(string: "https://vault.bitwarden.com")!,
                events: nil,
                icons: URL(string: "https://icons.bitwarden.com")!,
                identity: URL(string: "https://vault.bitwarden.com/identity"),
                notifications: nil,
                webVault: URL(string: "https://vault.bitwarden.com")!,
            ),
        )
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// `perform(_:)` with `.saveEnvironment` includes certificate alias and fingerprint from state.
    @MainActor
    func test_perform_saveEnvironment_withCertificate() async throws {
        subject.state.serverUrl = "vault.bitwarden.com"
        subject.state.keyAlias = "My Cert"
        subject.state.keyFingerprint = "abc123"

        await subject.perform(.saveEnvironment)

        XCTAssertEqual(
            delegate.savedUrls,
            EnvironmentURLData(
                base: URL(string: "https://vault.bitwarden.com")!,
                clientCertificateAlias: "My Cert",
                clientCertificateFingerprint: "abc123",
            ),
        )
    }

    /// `perform(_:)` with `.saveEnvironment` displays an alert if any of the URLs are invalid.
    @MainActor
    func test_perform_saveEnvironment_invalidURLs() async throws {
        subject.state.serverUrl = "a<b>c"

        await subject.perform(.saveEnvironment)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.environmentPageUrlsError,
            ),
        )
    }

    /// Receiving `.apiUrlChanged` updates the state.
    @MainActor
    func test_receive_apiUrlChanged() {
        subject.receive(.apiUrlChanged("api url"))

        XCTAssertEqual(subject.state.apiServerUrl, "api url")
    }

    /// Receiving `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// Receiving `.iconsUrlChanged` updates the state.
    @MainActor
    func test_receive_iconsUrlChanged() {
        subject.receive(.iconsUrlChanged("icons url"))

        XCTAssertEqual(subject.state.iconsServerUrl, "icons url")
    }

    /// Receiving `.identityUrlChanged` updates the state.
    @MainActor
    func test_receive_identityUrlChanged() {
        subject.receive(.identityUrlChanged("identity url"))

        XCTAssertEqual(subject.state.identityServerUrl, "identity url")
    }

    /// Receiving `.serverUrlChanged` updates the state.
    @MainActor
    func test_receive_serverUrlChanged() {
        subject.receive(.serverUrlChanged("server url"))

        XCTAssertEqual(subject.state.serverUrl, "server url")
    }

    /// Receiving `.webVaultUrlChanged` updates the state.
    @MainActor
    func test_receive_webVaultUrlChanged() {
        subject.receive(.webVaultUrlChanged("web vault url"))

        XCTAssertEqual(subject.state.webVaultServerUrl, "web vault url")
    }

    // MARK: Certificate Tests

    /// `perform(_:)` with `.importClientCertificate` cleans up the replaced certificate's keychain
    /// entry when the new fingerprint differs from the previous one.
    @MainActor
    func test_perform_importClientCertificate_replacesOldCert() async throws {
        subject.state.keyAlias = "Old Cert"
        subject.state.keyFingerprint = "old-fingerprint"
        clientCertificateService.importCertificateReturnValue = "new-fingerprint"

        await subject.perform(.importClientCertificate(data: Data([0x01]), alias: "New Cert", password: "pass"))

        XCTAssertEqual(subject.state.keyAlias, "New Cert")
        XCTAssertEqual(subject.state.keyFingerprint, "new-fingerprint")
        XCTAssertEqual(clientCertificateService.removeCertificateFingerprintReceivedFingerprint, "old-fingerprint")
    }

    /// `perform(_:)` with `.importClientCertificate` logs an error when cleaning up the replaced
    /// certificate fails, but still updates state with the new certificate.
    @MainActor
    func test_perform_importClientCertificate_replacesOldCert_removeThrows_logsError() async {
        let removeError = BitwardenTestError.example
        subject.state.keyFingerprint = "old-fingerprint"
        clientCertificateService.importCertificateReturnValue = "new-fingerprint"
        clientCertificateService.removeCertificateFingerprintThrowableError = removeError

        await subject.perform(.importClientCertificate(data: Data([0x01]), alias: "New Cert", password: "pass"))

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [removeError])
        XCTAssertEqual(subject.state.keyFingerprint, "new-fingerprint")
        XCTAssertNil(subject.state.dialog)
    }

    /// `perform(_:)` with `.importClientCertificate` updates alias and fingerprint in state on success.
    @MainActor
    func test_perform_importClientCertificate_success() async throws {
        let data = Data([0x01, 0x02])
        clientCertificateService.importCertificateReturnValue = "fingerprint-xyz"

        await subject.perform(.importClientCertificate(data: data, alias: "My Cert", password: "pass"))

        XCTAssertEqual(subject.state.keyAlias, "My Cert")
        XCTAssertEqual(subject.state.keyFingerprint, "fingerprint-xyz")
        XCTAssertNil(subject.state.dialog)
        XCTAssertNil(subject.state.pendingCertificateData)
        // No previous cert to clean up.
        XCTAssertFalse(clientCertificateService.removeCertificateFingerprintCalled)
    }

    /// `perform(_:)` with `.removeClientCertificate` shows an alert on failure.
    @MainActor
    func test_perform_removeClientCertificate_failure() async throws {
        subject.state.keyAlias = "My Cert"
        subject.state.keyFingerprint = "fp-123"
        clientCertificateService.removeCertificateFingerprintThrowableError =
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Remove failed"])

        await subject.perform(.removeClientCertificate)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(alert.title, Localizations.anErrorHasOccurred)
    }

    /// `perform(_:)` with `.removeClientCertificate` clears alias and fingerprint from state.
    @MainActor
    func test_perform_removeClientCertificate_success() async throws {
        subject.state.keyAlias = "My Cert"
        subject.state.keyFingerprint = "fp-123"

        await subject.perform(.removeClientCertificate)

        XCTAssertEqual(subject.state.keyAlias, "")
        XCTAssertEqual(subject.state.keyFingerprint, "")
        XCTAssertEqual(clientCertificateService.removeCertificateFingerprintReceivedFingerprint, "fp-123")
    }

    /// Receiving `.certificateFileSelected` with a failure shows an error dialog.
    @MainActor
    func test_receive_certificateFileSelected_failure() {
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "File error"])

        subject.receive(.certificateFileSelected(.failure(error)))

        if case let .error(message) = subject.state.dialog {
            XCTAssertTrue(message.contains("File error"))
        } else {
            XCTFail("Expected error dialog")
        }
    }

    /// Receiving `.certificateInfoSubmitted` when alias already exists shows overwrite confirmation dialog.
    @MainActor
    func test_receive_certificateInfoSubmitted_aliasConflict() {
        let data = Data([0x01])
        subject.state.pendingCertificateData = data
        subject.state.keyAlias = "existing"

        subject.receive(.certificateInfoSubmitted(alias: "existing", password: "pass123"))

        if case let .confirmOverwriteAlias(alias, _, _) = subject.state.dialog {
            XCTAssertEqual(alias, "existing")
        } else {
            XCTFail("Expected confirmOverwriteAlias dialog")
        }
    }

    /// Receiving `.certificateInfoSubmitted` with empty alias shows error dialog.
    @MainActor
    func test_receive_certificateInfoSubmitted_emptyAlias() {
        subject.state.pendingCertificateData = Data([0x01])

        subject.receive(.certificateInfoSubmitted(alias: "", password: "pass123"))

        XCTAssertEqual(
            subject.state.dialog,
            .error(message: Localizations.validationFieldRequired(Localizations.alias)),
        )
    }

    /// Receiving `.certificateInfoSubmitted` with empty password shows error dialog.
    @MainActor
    func test_receive_certificateInfoSubmitted_emptyPassword() {
        subject.state.pendingCertificateData = Data([0x01])

        subject.receive(.certificateInfoSubmitted(alias: "test", password: ""))

        XCTAssertEqual(
            subject.state.dialog,
            .error(message: Localizations.validationFieldRequired(Localizations.password)),
        )
    }

    /// Receiving `.dialogDismiss` clears the dialog state.
    @MainActor
    func test_receive_dialogDismiss() {
        subject.state.dialog = .error(message: "test error")

        subject.receive(.dialogDismiss)

        XCTAssertNil(subject.state.dialog)
    }

    /// Receiving `.dismissCertificateImporter` hides the certificate importer.
    @MainActor
    func test_receive_dismissCertificateImporter() {
        subject.state.showingCertificateImporter = true

        subject.receive(.dismissCertificateImporter)

        XCTAssertFalse(subject.state.showingCertificateImporter)
    }

    /// Receiving `.importCertificateTapped` shows the certificate importer.
    @MainActor
    func test_receive_importCertificateTapped() {
        subject.receive(.importCertificateTapped)

        XCTAssertTrue(subject.state.showingCertificateImporter)
    }

    /// `perform(_:)` with `.importClientCertificate` shows an error dialog on invalid password.
    @MainActor
    func test_perform_importClientCertificate_invalidPassword() async throws {
        clientCertificateService.importCertificateThrowableError = ClientCertificateError.invalidPassword

        await subject.perform(.importClientCertificate(data: Data(), alias: "My Cert", password: "wrong"))

        XCTAssertEqual(
            subject.state.dialog,
            .error(message: Localizations.theCertificatePasswordIsIncorrect),
        )
    }
}

class MockSelfHostedProcessorDelegate: SelfHostedProcessorDelegate {
    var savedUrls: EnvironmentURLData?

    func didSaveEnvironment(urls: EnvironmentURLData) {
        savedUrls = urls
    }
}
