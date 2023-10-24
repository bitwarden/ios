import Foundation

// MARK: Alert+Networking

extension Alert {
    /// An alert shown to the user when they aren't connected to the internet.
    ///
    /// - Parameter tryAgain: An action allowing the user to retry the request.
    ///
    /// - Returns: An alert notifying the user that they aren't connected to the internet.
    ///
    static func internetConnectionError(_ tryAgain: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.internetConnectionRequiredTitle,
            message: Localizations.internetConnectionRequiredMessage,
            alertActions: [
                AlertAction(title: Localizations.tryAgain, style: .default) { _ in
                    await tryAgain()
                },
            ]
        )
    }

    /// Creates an alert for the networking error that was received.
    ///
    /// - Parameters:
    ///   - error: The networking error that occured.
    ///   - tryAgain: An action allowing the user to retry the request.
    ///
    /// - Returns: An alert notifying the user that a networking error occured.
    ///
    static func networkResponseError(
        _ error: Error,
        _ tryAgain: @escaping () async -> Void
    ) -> Alert {
        switch error {
        case let error as URLError where error.code == .notConnectedToInternet:
            return internetConnectionError {
                await tryAgain()
            }
        case let error as URLError where error.code == .timedOut:
            return timeoutError(error.localizedDescription) {
                await tryAgain()
            }
        default:
            return defaultAlert(title: Localizations.anErrorHasOccurred)
        }
    }

    /// An alert for when a network request times out.
    ///
    /// - Parameters:
    ///   - errorMessage: The error message returned from the API upon a timed out request.
    ///   - tryAgain: An action allowing the user to retry the request.
    ///
    /// - Returns: An alert for when a network request times out.
    ///
    static func timeoutError(
        _ errorMessage: String,
        _ tryAgain: @escaping () async -> Void
    ) -> Alert {
        defaultAlert(
            title: errorMessage,
            alertActions: [
                AlertAction(title: Localizations.tryAgain, style: .default) { _ in
                    await tryAgain()
                },
            ]
        )
    }
}
