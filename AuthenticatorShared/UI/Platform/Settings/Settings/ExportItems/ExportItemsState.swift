// MARK: - ExportItemsState

/// The current state of an `ExportItemsView`.
struct ExportItemsState: Equatable {
    // MARK: Properties

    /// The currently selected file format type.
    var fileFormat: ExportFormatType = .json
}
