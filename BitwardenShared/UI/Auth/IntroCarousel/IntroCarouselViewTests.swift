import BitwardenResources
import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class IntroCarouselViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<IntroCarouselState, IntroCarouselAction, IntroCarouselEffect>!
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

    /// Tapping the create account button performs the create account effect.
    @MainActor
    func test_createAccount_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.createAccount)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .createAccount)
    }

    /// Tapping the log in button dispatches the login action.
    @MainActor
    func test_login_tap() throws {
        let button = try subject.inspect().find(button: Localizations.logIn)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .logIn)
    }

    // MARK: Snapshots

    /// The intro carousel page 1 renders correctly.
    func test_snapshot_introCarousel_page1() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape]
        )
    }

    /// The intro carousel page 2 renders correctly.
    @MainActor
    func test_snapshot_introCarousel_page2() {
        processor.state.currentPageIndex = 1
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape]
        )
    }

    /// The intro carousel page 3 renders correctly.
    @MainActor
    func test_snapshot_introCarousel_page3() {
        processor.state.currentPageIndex = 2
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape]
        )
    }

    /// The intro carousel page 4 renders correctly.
    @MainActor
    func test_snapshot_introCarousel_page4() {
        processor.state.currentPageIndex = 3
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape]
        )
    }
}
