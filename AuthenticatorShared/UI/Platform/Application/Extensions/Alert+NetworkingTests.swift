// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Foundation
import Networking
import TestHelpers
import XCTest

@testable import AuthenticatorShared

// MARK: - Alert+NetworkingTests

class AlertNetworkingTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests the `networkConnectionLostError` alert contains the correct properties.
    func test_networkConnectionLost() {
        let urlError = URLError(.networkConnectionLost)
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

    /// `.networkResponseError` builds an alert to display a server error message.
    func test_networkResponseError_serverError() throws {
        let response = HTTPResponse.failure(statusCode: 400, body: APITestData.bitwardenErrorMessage.data)
        let error = try ServerError.error(errorResponse: ErrorResponseModel(response: response))
        let subject = Alert.networkResponseError(error)

        XCTAssertEqual(subject.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(subject.message, "You do not have permissions to edit this.")
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.ok)
        XCTAssertEqual(action.style, .cancel)
        XCTAssertNil(action.handler)
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

    /// `ResponseValidationError` builds an alert to display a server error message.
    func test_responseValidationError() throws {
        let response = HTTPResponse.failure(statusCode: 400, body: APITestData.responseValidationError.data)
        let error = try ServerError.validationError(
            validationErrorResponse: ResponseValidationErrorModel(
                response: response
            )
        )
        let subject = Alert.networkResponseError(error)

        XCTAssertEqual(subject.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(subject.message, "Username or password is incorrect. Try again.")
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.ok)
        XCTAssertEqual(action.style, .cancel)
        XCTAssertNil(action.handler)
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
