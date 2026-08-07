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
