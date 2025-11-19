// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
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
}
