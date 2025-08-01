import BitwardenKit
import BitwardenResources
import XCTest

@testable import BitwardenShared

class SelfHostedProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var delegate: MockSelfHostedProcessorDelegate!
    var subject: SelfHostedProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        delegate = MockSelfHostedProcessorDelegate()
        subject = SelfHostedProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            state: SelfHostedState()
        )

        super.setUp()
    }

    override func tearDown() {
        coordinator = nil
        delegate = nil
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
            EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com")!)
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
                webVault: URL(string: "https://vault.bitwarden.com")!
            )
        )
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
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
                message: Localizations.environmentPageUrlsError
            )
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
}

class MockSelfHostedProcessorDelegate: SelfHostedProcessorDelegate {
    var savedUrls: EnvironmentURLData?

    func didSaveEnvironment(urls: EnvironmentURLData) {
        savedUrls = urls
    }
}
