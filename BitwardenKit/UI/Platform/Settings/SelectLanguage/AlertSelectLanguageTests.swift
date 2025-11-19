import BitwardenKit
import BitwardenResources
import XCTest

class AlertSelectLanguageTests: BitwardenTestCase {
    // MARK: Tests

    /// `languageChanged(to:)` constructs an `Alert` with the title and ok buttons.
    @MainActor
    func test_languageChanged() {
        let subject = Alert.languageChanged(to: "Thai") {}

        XCTAssertEqual(subject.title, Localizations.languageChangeXDescription("Thai"))
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.ok)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
    }
}
