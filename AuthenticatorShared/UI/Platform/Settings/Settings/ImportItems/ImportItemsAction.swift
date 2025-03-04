// MARK: - ImportItemsAction

/// Synchronous actions handled by an `ImportItemsProcessor`.
enum ImportItemsAction: Equatable {
    /// The url has been opened so clear the value in the state.
    case clearURL

    /// Dismiss the sheet.
    case dismiss

    /// The file format type was changed.
    case fileFormatTypeChanged(ImportFormatType)

    /// The export button was tapped.
    case importItemsTapped

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
