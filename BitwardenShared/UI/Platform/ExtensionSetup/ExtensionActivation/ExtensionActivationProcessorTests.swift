import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - ExtensionActivationProcessorTests

class ExtensionActivationProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var configService: MockConfigService!
    var subject: ExtensionActivationProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        configService = MockConfigService()
        subject = ExtensionActivationProcessor(
            appExtensionDelegate: appExtensionDelegate,
            services: ServiceContainer.withMocks(configService: configService),
            state: ExtensionActivationState(extensionType: .autofillExtension),
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        configService = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.cancelTapped` notifies the delegate to cancel the extension.
    @MainActor
    func test_receive_cancelTapped() {
        subject.receive(.cancelTapped)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }
}
