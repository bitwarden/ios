import BitwardenResources
import Foundation

// MARK: - PasswordAutoFillState

/// An object that defines the current state of the`PasswordAutoFillState`.
///
struct PasswordAutoFillState: Equatable {
    // MARK: Types

    /// The modes possible for the view.
    enum Mode: Equatable {
        /// The onboarding mode for the autofill feature.
        case onboarding

        /// The settings mode for managing autofill preferences.
        case settings
    }

    // MARK: Properties

    /// The instructions for setting up autofill.
    var autofillInstructions = [
        Localizations.fromYourDeviceSettingsToggleOnAutoFillPasswordsAndPasskeys,
        Localizations.toggleOffICloudToMakeBitwardenYourDefaultAutoFillSource,
        Localizations.toggleOnBitwardenToUseYourSavedPasswordsToLogIntoYourAccounts,
    ]

    /// The current mode the view should display.
    var mode: Mode

    /// The title of the navigation bar.
    var navigationBarTitle: String {
        switch mode {
        case .onboarding:
            Localizations.accountSetup
        case .settings:
            Localizations.passwordAutofill
        }
    }

    /// The title to display.
    var title: String {
        if #available(iOS 18, *) {
            Localizations.autofillWithBitwarden
        } else {
            Localizations.turnOnAutoFill
        }
    }

    /// The subtitle to display.
    var subtitle: String {
        if #available(iOS 18, *) {
            Localizations.autofillWithBitwardenDescriptionLong
        } else {
            Localizations.useAutoFillToLogIntoYourAccountsWithASingleTap
        }
    }

    /// The url to open in the device's web browser.
    var url: URL?
}
