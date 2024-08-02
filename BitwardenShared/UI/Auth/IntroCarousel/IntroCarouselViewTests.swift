import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class IntroCarouselViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<IntroCarouselState, IntroCarouselAction, Void>!
    var subject: IntroCarouselView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: IntroCarouselState())

        subject = IntroCarouselView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the create account button dispatches the create account action.
    func test_createAccount_tap() throws {
        let button = try subject.inspect().find(button: Localizations.createAccount)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .createAccount)
    }

    /// Tapping the log in button dispatches the login action.
    func test_login_tap() throws {
        let button = try subject.inspect().find(button: Localizations.logIn)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .logIn)
    }

    // MARK: Snapshots

    /// The intro carousel renders correctly.
    func test_snapshot_introCarousel() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape]
        )
    }
}
