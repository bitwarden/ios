// MARK: - ImportItemsState

/// The current state of an `ImportItemsView`.
struct ImportItemsState: Equatable {
    // MARK: Properties

    /// The currently selected file format type.
    var fileFormat: ImportFormatType = .bitwardenJson

    /// A toast for views
    var toast: Toast?
}
