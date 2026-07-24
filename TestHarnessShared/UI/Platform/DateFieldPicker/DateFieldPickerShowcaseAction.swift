import Foundation

/// Actions that can be processed by a `DateFieldPickerShowcaseProcessor`.
///
enum DateFieldPickerShowcaseAction: Equatable {
    /// The selected date was updated.
    case dateChanged(Date?)
}
