import BitwardenSdk
import XCTest

@testable import BitwardenShared

class VaultAutofillListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var coordinator: MockCoordinator<VaultRoute>!
    var errorReporter: MockErrorReporter!
    var subject: VaultAutofillListProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()

        subject = VaultAutofillListProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository
            ),
            state: VaultAutofillListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.cancelTapped` notifies the delegate to cancel the extension.
    func test_receive_dismissPressed() {
        subject.receive(.cancelTapped)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }
}
