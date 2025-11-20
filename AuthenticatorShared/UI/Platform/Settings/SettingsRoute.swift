import BitwardenKit
import BitwardenSdk
import Foundation

/// A route to a specific screen in the settings tab.
///
public enum SettingsRoute: Equatable, Hashable {
    /// A route that dismisses the current view.
    case dismiss

    /// A route to the export items view.
    case exportItems

    /// A route to a Flight Recorder view.
    case flightRecorder(FlightRecorderRoute)

    /// A route to the import items view.
    case importItems

    /// A route to the import file selection
    case importItemsFileSelection(route: FileSelectionRoute)

    /// A route to view the select language view.
    ///
    /// - Parameter currentLanguage: The currently selected language option.
    ///
    case selectLanguage(currentLanguage: LanguageOption)

    /// A route to the settings screen.
    case settings

    /// A route to the share sheet for an exported items URL.
    case shareExportedItems(URL)

    /// A route to show the tutorial.
    case tutorial
}
