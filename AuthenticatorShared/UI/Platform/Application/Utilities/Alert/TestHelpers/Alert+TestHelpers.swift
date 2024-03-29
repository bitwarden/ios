import Foundation

@testable import AuthenticatorShared

enum AlertError: LocalizedError {
    case alertActionNotFound(title: String)

    var errorDescription: String? {
        switch self {
        case let .alertActionNotFound(title):
            "Unable to locate an alert action for the title: \(title)"
        }
    }
}

extension Alert {
    /// Simulates a user interaction with the alert action that matches the provided title.
    ///
    /// - Parameter title: The title of the alert action to trigger.
    /// - Throws: Throws an `AlertError` if the alert action cannot be found.
    ///
    func tapAction(title: String) async throws {
        guard let alertAction = alertActions.first(where: { $0.title == title }) else {
            throw AlertError.alertActionNotFound(title: title)
        }
        await alertAction.handler?(alertAction, alertTextFields)
    }
}
