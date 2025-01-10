/// Effects that can be processed by a `ExportCXFProcessor`.
enum ExportCXFEffect {
    /// The view appeared.
    case appeared

    /// User wants to cancel the import process.
    case cancel

    /// The main button was tapped.
    case mainButtonTapped
}
