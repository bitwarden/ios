// swiftlint:disable:this file_name

import Foundation
import XCTest

@testable import BitwardenShared

// MARK: - Alert+NetworkingTests

class AlertNetworkingTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests the `genericRequestError` alert contains the correct properties.
    func test_genericAlert() {
        let subject = Alert.genericRequestError()

        XCTAssertEqual(subject.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(subject.message, Localizations.genericErrorMessage)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.ok)
        XCTAssertEqual(action.style, .default)
    }

    /// Tests the `internetConnectionError` alert contains the correct properties.
    func test_noInternetConnection() {
        let urlError = URLError(.notConnectedToInternet)
        let subject = Alert.networkResponseError(urlError) {}

        XCTAssertEqual(subject.title, Localizations.internetConnectionRequiredTitle)
        XCTAssertEqual(subject.message, Localizations.internetConnectionRequiredMessage)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.tryAgain)
        XCTAssertEqual(action.style, .default)
        XCTAssertNotNil(action.handler)
    }

    /// Tests the `timeoutError` alert contains the correct properties.
    func test_timeoutError() {
        let urlError = URLError(.timedOut)
        let subject = Alert.networkResponseError(urlError) {}

        XCTAssertEqual(subject.message, urlError.localizedDescription)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.tryAgain)
        XCTAssertEqual(action.style, .default)
        XCTAssertNotNil(action.handler)
    }
}
