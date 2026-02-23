import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - ExtensionActivationProcessorTests

class ExtensionActivationProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var autofillCredentialService: MockAutofillCredentialService!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<ExtensionSetupRoute, Void>!
    var subject: ExtensionActivationProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        autofillCredentialService = MockAutofillCredentialService()
        configService = MockConfigService()
        coordinator = MockCoordinator<ExtensionSetupRoute, Void>()
        subject = ExtensionActivationProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                autofillCredentialService: autofillCredentialService,
                configService: configService,
            ),
            state: ExtensionActivationState(extensionType: .autofillExtension),
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        autofillCredentialService = nil
        configService = nil
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` updates the credentials on the identity store.
    @MainActor
    func test_perform_appeared() async throws {
        await subject.perform(.appeared)

        XCTAssertTrue(autofillCredentialService.updateCredentialsInStoreCalled)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.settingUpAutofill)])
        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
    }

    /// `receive(_:)` with `.cancelTapped` notifies the delegate to cancel the extension.
    @MainActor
    func test_receive_cancelTapped() {
        subject.receive(.cancelTapped)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }
}
