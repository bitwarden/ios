import BitwardenSdk
import Foundation

// MARK: Alert+Networking

extension Alert {
    /// An alert shown to the user when they aren't connected to the internet.
    ///
    /// - Parameter tryAgain: An action allowing the user to retry the request.
    ///
    /// - Returns: An alert notifying the user that they aren't connected to the internet.
    ///
    static func internetConnectionError(_ tryAgain: (() async -> Void)? = nil) -> Alert {
        Alert(
            title: Localizations.internetConnectionRequiredTitle,
            message: Localizations.internetConnectionRequiredMessage,
            alertActions: [
                AlertAction(title: Localizations.tryAgain, style: .default) { _ in
                    if let tryAgain {
                        await tryAgain()
                    }
                },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
    }

    /// Creates an alert for the networking error that was received.
    ///
    /// - Parameters:
    ///   - error: The networking error that occurred.
    ///   - tryAgain: An action allowing the user to retry the request.
    ///
    /// - Returns: An alert notifying the user that a networking error occurred.
    ///
    static func networkResponseError(
        _ error: Error,
        _ tryAgain: (() async -> Void)? = nil
    ) -> Alert {
        if let responseError = error as? ResponseValidationError {
            if let errorResponse = try? ResponseValidationErrorModel(response: responseError.response) {
                let message = errorResponse.errorModel.message
                return defaultAlert(
                    title: Localizations.anErrorHasOccurred,
                    message: message
                )
            }
        }

        switch error {
        case let ServerError.error(errorResponse):
            return defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: errorResponse.singleMessage()
            )
        case let BitwardenSdk.BitwardenError.E(message):
            return defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: message
            )
        case let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost:
            return internetConnectionError(tryAgain)
        case let error as URLError where error.code == .timedOut:
            return defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: error.localizedDescription,
                alertActions: [
                    AlertAction(title: Localizations.tryAgain, style: .default) { _ in
                        if let tryAgain {
                            await tryAgain()
                        }
                    },
                    AlertAction(title: Localizations.cancel, style: .cancel),
                ]
            )
        default:
            return defaultAlert(title: Localizations.anErrorHasOccurred)
        }
    }
}
