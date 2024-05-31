import Foundation

@testable import BitwardenShared

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
    /// - Parameters:
    ///   - title: The title of the alert action to trigger.
    ///   - alertTextFields: `AlertTextField` list to execute the action.
    /// - Throws: Throws an `AlertError` if the alert action cannot be found.
    func tapAction(title: String, alertTextFields: [AlertTextField]? = nil) async throws {
        guard let alertAction = alertActions.first(where: { $0.title == title }) else {
            throw AlertError.alertActionNotFound(title: title)
        }
        await alertAction.handler?(alertAction, alertTextFields ?? self.alertTextFields)
    }
}
