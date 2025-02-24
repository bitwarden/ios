// MARK: - ExportItemsAction

/// Synchronous actions handled by an `ExportItemsProcessor`.
enum ExportItemsAction: Equatable {
    /// Dismiss the sheet.
    case dismiss

    /// The file format type was changed.
    case fileFormatTypeChanged(ExportFormatType)

    /// The export button was tapped.
    case exportItemsTapped
}
