import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - ViewItemViewTests

class LoginRequestViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<LoginRequestState, LoginRequestAction, LoginRequestEffect>!
    var subject: LoginRequestView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: LoginRequestState(request: .fixture(
            fingerprintPhrase: "i-asked-chat-gpt-but-it-said-no"
        )))
        let store = Store(processor: processor)

        subject = LoginRequestView(store: store)
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

    /// Tapping the confirm button performs the `.answerRequest(approve:)` effect.
    @MainActor
    func test_confirmButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.confirmLogIn)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .answerRequest(approve: true))
    }

    /// Tapping the deny button performs the `.answerRequest(approve:)` effect.
    @MainActor
    func test_denyButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.denyLogIn)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .answerRequest(approve: false))
    }

    // MARK: Snapshots

    /// The default view renders correctly.
    func test_snapshots() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 2),
            ]
        )
    }
}
