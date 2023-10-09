// swiftlint:disable:this file_name

import XCTest

@testable import BitwardenShared

// MARK: - AlertExtensionTests

class AlertExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    func test_invalidEmail() {
        let subject = Alert.invalidEmail

        XCTAssertEqual(subject.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(subject.message, Localizations.invalidEmail)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.ok)
        XCTAssertEqual(action.style, .default)
        XCTAssertNil(action.handler)
    }
}
