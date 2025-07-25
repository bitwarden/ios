import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class LoginWithDeviceViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<LoginWithDeviceState, LoginWithDeviceAction, LoginWithDeviceEffect>!
    var subject: LoginWithDeviceView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(
            state: LoginWithDeviceState(
                fingerprintPhrase: "some-weird-long-text-thing-as-a-placeholder"
            )
        )
        let store = Store(processor: processor)

        subject = LoginWithDeviceView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the resend notification button performs the `.resendNotification` effect.
    @MainActor
    func test_resendNotificationButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.resendNotification)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .resendNotification)
    }

    /// Tapping the view all login options button dispatches the `.dismiss` action.
    @MainActor
    func test_viewAllLoginOptionsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.viewAllLoginOptions)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    // MARK: Snapshots

    /// The default view renders correctly.
    func test_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
