// swiftlint:disable:this file_name

import Foundation
import XCTest

@testable import BitwardenShared

// MARK: - Alert+NetworkingTests

class AlertNetworkingTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests the `internetConnectionError` alert contains the correct properties.
    func test_noInternetConnection() {
        let urlError = URLError(.notConnectedToInternet)
        let subject = Alert.networkResponseError(urlError) {}

        XCTAssertEqual(subject.title, Localizations.internetConnectionRequiredTitle)
        XCTAssertEqual(subject.message, Localizations.internetConnectionRequiredMessage)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.tryAgain)
        XCTAssertEqual(action.style, .default)
        XCTAssertNotNil(action.handler)
    }

    /// Tests the `timeoutError` alert contains the correct properties.
    func test_timeoutError() {
        let urlError = URLError(.timedOut)
        let subject = Alert.networkResponseError(urlError) {}

        XCTAssertEqual(subject.title, urlError.localizedDescription)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.tryAgain)
        XCTAssertEqual(action.style, .default)
        XCTAssertNotNil(action.handler)
    }
}
