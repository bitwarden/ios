import BitwardenResources
import Foundation

// MARK: Alert+Networking

public extension Alert {
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
            ],
        )
    }

    /// Creates an alert for the networking error that was received.
    ///
    /// - Parameters:
    ///   - error: The networking error that occurred.
    ///   - isOfficialBitwardenServer: Indicates whether the request was made to the official Bitwarden server
    ///   - shareErrorDetails: An optional action closure which will show a 'Share error details'
    ///     button in the alert if there's no error message details to show in the alert itself.
    ///   - tryAgain: An action allowing the user to retry the request.
    ///
    /// - Returns: An alert notifying the user that a networking error occurred.
    ///
    static func networkResponseError(
        _ error: Error,
        isOfficialBitwardenServer: Bool = true,
        shareErrorDetails: (@MainActor () async -> Void)? = nil,
        tryAgain: (() async -> Void)? = nil,
    ) -> Alert {
        switch error {
        case let serverError as ServerError:
            defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: serverError.message,
            )
        case let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost:
            internetConnectionError(tryAgain)
        case let error as URLError where error.code == .timedOut:
            defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: error.localizedDescription,
                alertActions: [
                    AlertAction(title: Localizations.tryAgain, style: .default) { _ in
                        if let tryAgain {
                            await tryAgain()
                        }
                    },
                    AlertAction(title: Localizations.cancel, style: .cancel),
                ],
            )
        default:
            Alert(
                title: Localizations.anErrorHasOccurred,
                message: isOfficialBitwardenServer ? nil : Localizations.thisIsNotARecognizedServerDescriptionLong,
                alertActions: [
                    shareErrorDetails.flatMap { shareErrorDetails in
                        AlertAction(title: Localizations.shareErrorDetails, style: .default) { _ in
                            await shareErrorDetails()
                        }
                    },
                    AlertAction(title: Localizations.ok, style: .cancel),
                ].compactMap(\.self),
            )
        }
    }
}
