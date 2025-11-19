import BitwardenKit
import BitwardenResources
import Foundation

/// An object that defines the current state of a `SettingsView`.
///
struct SettingsState: Equatable {
    // MARK: Properties

    /// The selected app theme.
    var appTheme: AppTheme = .default

    /// The biometric auth status for the user.
    var biometricUnlockStatus: BiometricsUnlockStatus = .notAvailable

    /// The copyright text.
    var copyrightText = "© Bitwarden Inc. 2015-\(Calendar.current.component(.year, from: Date.now))"

    /// The current language selection.
    var currentLanguage: LanguageOption = .default

    /// The current default save option.
    var defaultSaveOption: DefaultSaveOption = .none

    /// The state for the Flight Recorder feature.
    var flightRecorderState = FlightRecorderSettingsSectionState()

    /// The current default save option.
    var sessionTimeoutValue: SessionTimeoutValue = .never

    /// A flag to indicate if we should show the default save option menu.
    var shouldShowDefaultSaveOption = false

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The version of the app.
    var version: String = "\(Localizations.version): \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))"
}
