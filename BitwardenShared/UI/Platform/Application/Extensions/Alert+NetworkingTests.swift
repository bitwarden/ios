// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenResources
import Foundation
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - Alert+NetworkingTests

class AlertNetworkingTests: BitwardenTestCase {
    // MARK: Tests

    /// Tests the `networkConnectionLostError` alert contains the correct properties.
    func test_networkConnectionLost() async throws {
        let urlError = URLError(.networkConnectionLost)
        var tryAgainCalled = false
        let subject = Alert.networkResponseError(urlError, tryAgain: { tryAgainCalled = true })

        XCTAssertEqual(subject.title, Localizations.internetConnectionRequiredTitle)
        XCTAssertEqual(subject.message, Localizations.internetConnectionRequiredMessage)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.tryAgain)
        XCTAssertEqual(action.style, .default)
        XCTAssertNotNil(action.handler)

        try await subject.tapAction(title: Localizations.tryAgain)
        XCTAssertTrue(tryAgainCalled)
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

    /// `networkResponseError()` builds an alert for an unknown error and includes an option to
    /// share the error details if a closure is provided.
    func test_networkResponseError_unknownError_shareErrorDetails() async throws {
        var shareErrorDetailsCalled = false
        let subject = Alert.networkResponseError(
            BitwardenTestError.example,
            shareErrorDetails: { shareErrorDetailsCalled = true }
        )

        XCTAssertEqual(subject.title, Localizations.anErrorHasOccurred)
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.shareErrorDetails)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.ok)

        try await subject.tapAction(title: Localizations.shareErrorDetails)
        XCTAssertTrue(shareErrorDetailsCalled)
    }

    /// `networkResponseError()` builds an alert for an unknown error and doesn't show the share
    /// error details button if no closure is provided.
    func test_networkResponseError_unknownError_withoutShareErrorDetails() async throws {
        let subject = Alert.networkResponseError(BitwardenTestError.example)

        XCTAssertEqual(subject.title, Localizations.anErrorHasOccurred)
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.ok)
    }

    /// `.networkResponseError` builds an alert to display an error message for an unofficial Bitwarden server.
    func test_networkResponseError_unofficialBitwardenServerError() {
        let error = BitwardenTestError.example
        let subject = Alert.networkResponseError(error, isOfficialBitwardenServer: false)

        XCTAssertEqual(subject.message, Localizations.thisIsNotARecognizedServerDescriptionLong)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.ok)
        XCTAssertEqual(action.style, .cancel)
        XCTAssertNil(action.handler)
    }

    /// Tests the `internetConnectionError` alert contains the correct properties.
    func test_noInternetConnection() async throws {
        let urlError = URLError(.notConnectedToInternet)
        var tryAgainCalled = false
        let subject = Alert.networkResponseError(urlError, tryAgain: { tryAgainCalled = true })

        XCTAssertEqual(subject.title, Localizations.internetConnectionRequiredTitle)
        XCTAssertEqual(subject.message, Localizations.internetConnectionRequiredMessage)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.tryAgain)
        XCTAssertEqual(action.style, .default)
        XCTAssertNotNil(action.handler)

        try await subject.tapAction(title: Localizations.tryAgain)
        XCTAssertTrue(tryAgainCalled)
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
    func test_timeoutError() async throws {
        let urlError = URLError(.timedOut)
        var tryAgainCalled = false
        let subject = Alert.networkResponseError(urlError, tryAgain: { tryAgainCalled = true })

        XCTAssertEqual(subject.message, urlError.localizedDescription)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.tryAgain)
        XCTAssertEqual(action.style, .default)
        XCTAssertNotNil(action.handler)

        try await subject.tapAction(title: Localizations.tryAgain)
        XCTAssertTrue(tryAgainCalled)
    }
}
