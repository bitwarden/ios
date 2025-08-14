import BitwardenResources
import UIKit

// MARK: Alert+Scan

extension Alert {
    /// An alert asking if the user would like to save a scanned key locally or send it to Bitwarden.
    ///
    /// - Parameters:
    ///   - saveLocallyAction: The action to perform if the user chooses to save the key locally.
    ///   - sendToBitwardenAction: The action to perform if the user chooses to send the key to Bitwarden.
    /// - Returns: An alert asking the user where they want to store the key.
    ///
    static func determineScanSaveLocation(saveLocallyAction: @escaping () async -> Void,
                                          sendToBitwardenAction: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.scanComplete,
            message: Localizations.saveThisAuthenticatorKeyHereOrAddItToALoginInYourBitwardenApp,
            alertActions: [
                AlertAction(title: Localizations.saveHere, style: .default) { _, _ in await saveLocallyAction() },
                AlertAction(title: Localizations.saveToBitwarden,
                            style: .default) { _, _ in await sendToBitwardenAction() },
            ]
        )
    }

    /// An alert asking if the user would like to set their default save option.
    ///
    /// - Parameters:
    ///   - yesAction: The action to perform if the user chooses to set the default.
    ///   - noAction: The action to perform if the user choose to not set the default.
    /// - Returns: An alert asking the user if they want to save their save location as the default.
    ///
    static func confirmDefaultSaveOption(title: String,
                                         yesAction: @escaping () async -> Void,
                                         noAction: @escaping () async -> Void) -> Alert {
        Alert(
            title: title,
            message: Localizations.youCanUpdateYourDefaultAnytimeInSettings,
            alertActions: [
                AlertAction(title: Localizations.yesSetDefault, style: .default) { _, _ in await yesAction() },
                AlertAction(title: Localizations.noAskMe,
                            style: .default) { _, _ in await noAction() },
            ]
        )
    }
}
