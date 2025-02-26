// swiftlint:disable:this file_name

import XCTest

@testable import BitwardenShared

class AlertTwoFactorNoticeTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests the `changeEmailAlert` alert contains the correct properties.
    func test_changeEmailAlert() {
        let subject = Alert.changeEmailAlert {}

        XCTAssertEqual(subject.title, Localizations.changeAccountEmail)
        XCTAssertEqual(subject.message, Localizations.changeEmailConfirmation)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)

        let action1 = subject.alertActions[0]
        XCTAssertEqual(action1.title, Localizations.cancel)
        XCTAssertEqual(action1.style, .cancel)
        XCTAssertNil(action1.handler)

        let action2 = subject.alertActions[1]
        XCTAssertEqual(action2.title, Localizations.continue)
        XCTAssertEqual(action2.style, .default)
        XCTAssertNotNil(action2.handler)
    }

    /// Tests the `turnOnTwoFactorLoginAlert` alert contains the correct properties.
    func test_turnOnTwoFactorLoginAlert() {
        let subject = Alert.turnOnTwoFactorLoginAlert {}

        XCTAssertEqual(subject.title, Localizations.turnOnTwoStepLogin)
        XCTAssertEqual(subject.message, Localizations.twoStepLoginDescriptionLong)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)

        let action1 = subject.alertActions[0]
        XCTAssertEqual(action1.title, Localizations.cancel)
        XCTAssertEqual(action1.style, .cancel)
        XCTAssertNil(action1.handler)

        let action2 = subject.alertActions[1]
        XCTAssertEqual(action2.title, Localizations.continue)
        XCTAssertEqual(action2.style, .default)
        XCTAssertNotNil(action2.handler)
    }
}
