import XCTest

@testable import BitwardenShared

class ExtensionActivationProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var subject: ExtensionActivationProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()

        subject = ExtensionActivationProcessor(
            appExtensionDelegate: appExtensionDelegate,
            state: ExtensionActivationState(extensionType: .autofillExtension)
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.cancelTapped` notifies the delegate to cancel the extension.
    func test_receive_cancelTapped() {
        subject.receive(.cancelTapped)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }
}
