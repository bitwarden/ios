// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - PremiumUpgradeCompleteViewTests

class PremiumUpgradeCompleteViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<Void, PremiumUpgradeCompleteAction, Void>!
    var subject: PremiumUpgradeCompleteView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: ())
        let store = Store(processor: processor)
        subject = PremiumUpgradeCompleteView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the close button dispatches the `.closeTapped` action.
    @MainActor
    func test_closeButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.close)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .closeTapped)
    }

    /// The title is displayed correctly.
    @MainActor
    func test_title_displayed() throws {
        let text = try subject.inspect().find(text: Localizations.upgradedToPremium)
        XCTAssertNotNil(text)
    }

    /// The description is displayed correctly.
    @MainActor
    func test_description_displayed() throws {
        let text = try subject.inspect().find(text: Localizations.youNowHaveAccessToAdvancedSecurityDescriptionLong)
        XCTAssertNotNil(text)
    }

    /// The learn more button is displayed.
    @MainActor
    func test_learnMoreButton_displayed() throws {
        let button = try subject.inspect().find(button: Localizations.learnMore)
        XCTAssertNotNil(button)
    }
}
