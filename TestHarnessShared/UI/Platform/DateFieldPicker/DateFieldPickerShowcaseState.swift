import BitwardenKit
import Foundation

/// The state for the date field picker showcase screen.
///
struct DateFieldPickerShowcaseState: Equatable {
    // MARK: Properties

    /// The title of the screen.
    var title: String = Localizations.dateFieldPicker

    /// The currently selected date, or `nil` if no date has been selected.
    var selectedDate: Date?
}

extension DateFieldPickerShowcaseState {
    /// The selected date formatted as a long localized calendar date (e.g. "August 10, 2026");
    /// empty when unset. Pinned to UTC so a UTC-anchored stored date reads back as the same
    /// calendar day regardless of device time zone.
    var selectedDateDisplay: String {
        guard let selectedDate else { return "" }
        return selectedDate.longCalendarDateDisplay
    }
}
