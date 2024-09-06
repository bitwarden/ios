import XCTest

@testable import AuthenticatorShared

// MARK: - ItemListProcessorTests

class ItemListProcessorTests: AuthenticatorTestCase {
    // MARK: Properties

    var application: MockApplication!
    var authItemRepository: MockAuthenticatorItemRepository!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<ItemListRoute, ItemListEvent>!
    var totpService: MockTOTPService!
    var subject: ItemListProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        application = MockApplication()
        authItemRepository = MockAuthenticatorItemRepository()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        totpService = MockTOTPService()

        let services = ServiceContainer.withMocks(
            application: application,
            authenticatorItemRepository: authItemRepository,
            configService: configService,
            totpService: totpService
        )

        subject = ItemListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: ItemListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    /// `didCompleteAutomaticCapture` failure
    func test_didCompleteAutomaticCapture_failure() {
        totpService.getTOTPConfigResult = .failure(TOTPServiceError.invalidKeyFormat)
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: "1234")
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        waitFor(!coordinator.alertShown.isEmpty)
        XCTAssertEqual(
            coordinator.alertShown.last,
            Alert(
                title: Localizations.keyReadError,
                message: nil,
                alertActions: [
                    AlertAction(title: Localizations.ok, style: .default),
                ]
            )
        )
        XCTAssertEqual(authItemRepository.addAuthItemAuthItems, [])
        XCTAssertNil(subject.state.toast)
    }

    /// `didCompleteAutomaticCapture` success
    func test_didCompleteAutomaticCapture_success() throws {
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPKeyModel(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        authItemRepository.itemListSubject.value = [ItemListSection.fixture()]
        let captureCoordinator = MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>()
        subject.didCompleteAutomaticCapture(captureCoordinator.asAnyCoordinator(), key: key)
        var dismissAction: DismissAction?
        if case let .dismiss(onDismiss) = captureCoordinator.routes.last {
            dismissAction = onDismiss
        }
        XCTAssertNotNil(dismissAction)
        dismissAction?.action()
        waitFor(!authItemRepository.addAuthItemAuthItems.isEmpty)
        waitFor(subject.state.loadingState != .loading(nil))
        guard let item = authItemRepository.addAuthItemAuthItems.first
        else {
            XCTFail("Unable to get authenticator item")
            return
        }
        XCTAssertEqual(item.name, "")
        XCTAssertEqual(item.totpKey, String.base32Key)
    }

    /// Tests that the `showPasswordManagerSyncCard` and `showPasswordManagerDownloadCard` are set
    /// to false if the feature flag is turned off.
    func test_determineItemListCardState_FeatureFlag_off() {
        subject.state.itemListCardState = .passwordManagerSync
        configService.featureFlagsBool = [.passwordManagerSyncEnabled: false]
        let task = Task {
            await self.subject.perform(.appeared)
        }

        waitFor(subject.state.itemListCardState == .none)
        task.cancel()
    }

    /// Tests that the `itemListCardState` is set to `passwordManagerDownload` if the feature flag is turned on.
    func test_determineItemListCardState_FeatureFlag_on_download() {
        configService.featureFlagsBool = [.passwordManagerSyncEnabled: true]
        application.canOpenUrlResponse = false
        let task = Task {
            await self.subject.perform(.appeared)
        }

        waitFor(subject.state.itemListCardState == .passwordManagerDownload)
        task.cancel()
    }

    /// Tests that the `itemListCardState` is set to `passwordManagerSync` if the feature flag is turned on.
    func test_determineItemListCardState_FeatureFlag_on_sync() {
        configService.featureFlagsBool = [.passwordManagerSyncEnabled: true]
        application.canOpenUrlResponse = true
        let task = Task {
            await self.subject.perform(.appeared)
        }

        waitFor(subject.state.itemListCardState == .passwordManagerSync)
        task.cancel()
    }
}
