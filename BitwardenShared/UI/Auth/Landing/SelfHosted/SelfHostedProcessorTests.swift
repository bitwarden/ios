import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// swiftlint:disable file_length

class SelfHostedProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var clientCertificateService: MockClientCertificateService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var customHeadersService: MockCustomHeadersService!
    var delegate: MockSelfHostedProcessorDelegate!
    var errorReporter: MockErrorReporter!
    var services: ServiceContainer!
    var subject: SelfHostedProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        clientCertificateService = MockClientCertificateService()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        customHeadersService = MockCustomHeadersService()
        delegate = MockSelfHostedProcessorDelegate()
        errorReporter = MockErrorReporter()
        services = ServiceContainer.withMocks(
            clientCertificateService: clientCertificateService,
            customHeadersService: customHeadersService,
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
        customHeadersService = nil
        delegate = nil
        errorReporter = nil
        services = nil
        subject = nil

        super.tearDown()
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` loads the stored custom headers into the state.
    @MainActor
    func test_perform_appeared_loadsCustomHeaders() async throws {
        subject.state.customHeadersId = "headers-id"
        customHeadersService.getCustomHeadersIdReturnValue = ["Header-B": "2", "Header-A": "1"]

        await subject.perform(.appeared)

        XCTAssertEqual(customHeadersService.getCustomHeadersIdReceivedId, "headers-id")
        XCTAssertEqual(subject.state.customHeaders.map(\.name), ["Header-A", "Header-B"])
        XCTAssertEqual(subject.state.customHeaders.map(\.value), ["1", "2"])
    }

    /// `perform(_:)` with `.appeared` logs an error if loading the stored custom headers fails.
    @MainActor
    func test_perform_appeared_loadCustomHeadersError() async throws {
        subject.state.customHeadersId = "headers-id"
        customHeadersService.getCustomHeadersIdThrowableError = BitwardenTestError.example

        await subject.perform(.appeared)

        XCTAssertTrue(subject.state.customHeaders.isEmpty)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `.appeared` doesn't read the keychain when no custom headers are stored.
    @MainActor
    func test_perform_appeared_noCustomHeaders() async throws {
        await subject.perform(.appeared)

        XCTAssertFalse(customHeadersService.getCustomHeadersIdCalled)
        XCTAssertTrue(subject.state.customHeaders.isEmpty)
    }

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

    /// `perform(_:)` with `.saveEnvironment` saves new custom headers and includes the returned
    /// identifier in the saved URLs.
    @MainActor
    func test_perform_saveEnvironment_withCustomHeaders() async throws {
        subject.state.serverUrl = "vault.bitwarden.com"
        subject.state.customHeaders = [
            SelfHostedState.CustomHeaderField(name: " CF-Access-Client-Id ", value: " client-id "),
            SelfHostedState.CustomHeaderField(name: "", value: "ignored"),
        ]
        customHeadersService.saveCustomHeadersReturnValue = "new-headers-id"

        await subject.perform(.saveEnvironment)

        XCTAssertEqual(customHeadersService.saveCustomHeadersReceivedHeaders, ["CF-Access-Client-Id": "client-id"])
        XCTAssertEqual(
            delegate.savedUrls,
            EnvironmentURLData(
                base: URL(string: "https://vault.bitwarden.com")!,
                customHeadersId: "new-headers-id",
            ),
        )
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// `perform(_:)` with `.saveEnvironment` reuses the existing identifier when the custom
    /// headers are unchanged.
    @MainActor
    func test_perform_saveEnvironment_customHeadersUnchanged_reusesId() async throws {
        subject.state.serverUrl = "vault.bitwarden.com"
        subject.state.customHeadersId = "existing-headers-id"
        subject.state.customHeaders = [
            SelfHostedState.CustomHeaderField(name: "Header-A", value: "1"),
        ]
        customHeadersService.getCustomHeadersIdReturnValue = ["Header-A": "1"]

        await subject.perform(.saveEnvironment)

        XCTAssertFalse(customHeadersService.saveCustomHeadersCalled)
        XCTAssertFalse(customHeadersService.removeCustomHeadersIdCalled)
        XCTAssertEqual(delegate.savedUrls?.customHeadersId, "existing-headers-id")
    }

    /// `perform(_:)` with `.saveEnvironment` saves changed custom headers under a new identifier
    /// and removes the previously stored headers after the environment is saved.
    @MainActor
    func test_perform_saveEnvironment_customHeadersChanged_removesPreviousHeaders() async throws {
        subject.state.serverUrl = "vault.bitwarden.com"
        subject.state.customHeadersId = "old-headers-id"
        subject.state.customHeaders = [
            SelfHostedState.CustomHeaderField(name: "Header-A", value: "updated"),
        ]
        customHeadersService.getCustomHeadersIdReturnValue = ["Header-A": "1"]
        customHeadersService.saveCustomHeadersReturnValue = "new-headers-id"

        await subject.perform(.saveEnvironment)

        XCTAssertEqual(customHeadersService.saveCustomHeadersReceivedHeaders, ["Header-A": "updated"])
        XCTAssertEqual(customHeadersService.removeCustomHeadersIdReceivedId, "old-headers-id")
        XCTAssertEqual(delegate.savedUrls?.customHeadersId, "new-headers-id")
    }

    /// `perform(_:)` with `.saveEnvironment` removes the stored headers and clears the identifier
    /// when all custom header fields were removed.
    @MainActor
    func test_perform_saveEnvironment_customHeadersRemoved() async throws {
        subject.state.serverUrl = "vault.bitwarden.com"
        subject.state.customHeadersId = "old-headers-id"
        subject.state.customHeaders = []

        await subject.perform(.saveEnvironment)

        XCTAssertFalse(customHeadersService.saveCustomHeadersCalled)
        XCTAssertEqual(customHeadersService.removeCustomHeadersIdReceivedId, "old-headers-id")
        XCTAssertEqual(delegate.savedUrls?.customHeadersId, nil)
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// `perform(_:)` with `.saveEnvironment` shows an alert and doesn't notify the delegate when
    /// saving the custom headers fails.
    @MainActor
    func test_perform_saveEnvironment_saveCustomHeadersError() async throws {
        subject.state.serverUrl = "vault.bitwarden.com"
        subject.state.customHeaders = [
            SelfHostedState.CustomHeaderField(name: "Header-A", value: "1"),
        ]
        customHeadersService.saveCustomHeadersThrowableError = BitwardenTestError.example

        await subject.perform(.saveEnvironment)

        XCTAssertNil(delegate.savedUrls)
        XCTAssertNotNil(coordinator.alertShown.first)
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

    /// Receiving `.addHeaderTapped` appends an empty custom header field.
    @MainActor
    func test_receive_addHeaderTapped() {
        subject.receive(.addHeaderTapped)

        XCTAssertEqual(subject.state.customHeaders.count, 1)
        XCTAssertEqual(subject.state.customHeaders.first?.name, "")
        XCTAssertEqual(subject.state.customHeaders.first?.value, "")
    }

    /// Receiving `.headerNameChanged` updates the name of the matching custom header field.
    @MainActor
    func test_receive_headerNameChanged() {
        let field = SelfHostedState.CustomHeaderField(name: "Old-Name", value: "1")
        subject.state.customHeaders = [field]

        subject.receive(.headerNameChanged(id: field.id, name: "New-Name"))

        XCTAssertEqual(subject.state.customHeaders.first?.name, "New-Name")
        XCTAssertEqual(subject.state.customHeaders.first?.value, "1")
    }

    /// Receiving `.headerValueChanged` updates the value of the matching custom header field.
    @MainActor
    func test_receive_headerValueChanged() {
        let field = SelfHostedState.CustomHeaderField(name: "Header-A", value: "old")
        subject.state.customHeaders = [field]

        subject.receive(.headerValueChanged(id: field.id, value: "new"))

        XCTAssertEqual(subject.state.customHeaders.first?.name, "Header-A")
        XCTAssertEqual(subject.state.customHeaders.first?.value, "new")
    }

    /// Receiving `.headerValueVisibilityChanged` updates the visibility of the matching custom
    /// header field's value.
    @MainActor
    func test_receive_headerValueVisibilityChanged() {
        let field = SelfHostedState.CustomHeaderField(name: "Header-A", value: "secret")
        subject.state.customHeaders = [field]

        subject.receive(.headerValueVisibilityChanged(id: field.id, isVisible: true))

        XCTAssertTrue(subject.state.customHeaders[0].isValueVisible)

        subject.receive(.headerValueVisibilityChanged(id: field.id, isVisible: false))

        XCTAssertFalse(subject.state.customHeaders[0].isValueVisible)
    }

    /// Receiving `.removeHeaderTapped` removes the matching custom header field.
    @MainActor
    func test_receive_removeHeaderTapped() {
        let field1 = SelfHostedState.CustomHeaderField(name: "Header-A", value: "1")
        let field2 = SelfHostedState.CustomHeaderField(name: "Header-B", value: "2")
        subject.state.customHeaders = [field1, field2]

        subject.receive(.removeHeaderTapped(id: field1.id))

        XCTAssertEqual(subject.state.customHeaders, [field2])
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

    /// `perform(_:)` with `.importClientCertificate` shows an error dialog on invalid certificate.
    @MainActor
    func test_perform_importClientCertificate_invalidCertificate() async {
        clientCertificateService.importCertificateThrowableError = ClientCertificateError.invalidCertificate

        await subject.perform(.importClientCertificate(data: Data(), alias: "My Cert", password: "pass"))

        XCTAssertEqual(
            subject.state.dialog,
            .error(message: Localizations.theCertificateFileIsInvalidOrCorrupted),
        )
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

    /// `perform(_:)` with `.importClientCertificate` shows the generic fallback dialog for unknown errors.
    @MainActor
    func test_perform_importClientCertificate_unknownError() async {
        clientCertificateService.importCertificateThrowableError = BitwardenTestError.example

        await subject.perform(.importClientCertificate(data: Data(), alias: "My Cert", password: "pass"))

        XCTAssertEqual(
            subject.state.dialog,
            .error(message: Localizations.theCertificateCouldNotBeInstalled),
        )
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

    /// Receiving `.certificateInfoSubmitted` with empty alias shows an alert via coordinator.
    @MainActor
    func test_receive_certificateInfoSubmitted_emptyAlias() throws {
        subject.state.pendingCertificateData = Data([0x01])

        subject.receive(.certificateInfoSubmitted(alias: "", password: "pass123"))

        XCTAssertNil(subject.state.dialog)
        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            .inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.alias),
            )),
        )
    }

    /// Receiving `.certificateInfoSubmitted` with empty password shows an alert via coordinator.
    @MainActor
    func test_receive_certificateInfoSubmitted_emptyPassword() throws {
        subject.state.pendingCertificateData = Data([0x01])

        subject.receive(.certificateInfoSubmitted(alias: "test", password: ""))

        XCTAssertNil(subject.state.dialog)
        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            .inputValidationAlert(error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.password),
            )),
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

    /// Receiving `.certificateFileSelected` with a success result sets `pendingCertificateData` and
    /// transitions the dialog to `.setCertificateData`.
    @MainActor
    func test_receive_certificateFileSelected_success() throws {
        let data = Data([0x01, 0x02, 0x03])
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.p12")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        subject.receive(.certificateFileSelected(.success(url)))

        XCTAssertEqual(subject.state.pendingCertificateData, data)
        XCTAssertFalse(subject.state.showingCertificateImporter)
        XCTAssertEqual(subject.state.dialog, .setCertificateData(certificateData: data))
    }

    /// Receiving `.certificateFileSelected` when the file cannot be read shows an error dialog.
    @MainActor
    func test_receive_certificateFileSelected_unreadableFile() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent.p12")

        subject.receive(.certificateFileSelected(.success(url)))

        XCTAssertEqual(
            subject.state.dialog,
            .error(message: Localizations.unableToReadCertificateFile),
        )
        XCTAssertNil(subject.state.pendingCertificateData)
    }

    /// Receiving `.confirmOverwriteCertificate` clears the dialog and imports the certificate from
    /// the pending overwrite confirmation state.
    @MainActor
    func test_receive_confirmOverwriteCertificate() async throws {
        let data = Data([0x01])
        subject.state.dialog = .confirmOverwriteAlias(alias: "My Cert", certificateData: data, password: "pass123")
        clientCertificateService.importCertificateReturnValue = "fp-new"

        subject.receive(.confirmOverwriteCertificate)

        // Dialog clears synchronously.
        XCTAssertNil(subject.state.dialog)

        try await waitForAsync {
            !self.subject.state.keyAlias.isEmpty && !self.subject.state.keyFingerprint.isEmpty
        }

        XCTAssertEqual(subject.state.keyAlias, "My Cert")
        XCTAssertEqual(subject.state.keyFingerprint, "fp-new")
    }
}

class MockSelfHostedProcessorDelegate: SelfHostedProcessorDelegate {
    var savedUrls: EnvironmentURLData?

    func didSaveEnvironment(urls: EnvironmentURLData) {
        savedUrls = urls
    }
}
