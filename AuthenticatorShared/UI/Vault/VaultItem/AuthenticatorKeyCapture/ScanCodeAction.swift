// MARK: - ScanCodeAction

/// Actions that can be processed by a `ScanCodeProcessor`.
enum ScanCodeAction: Equatable {
    /// The dismiss button was pressed.
    case dismissPressed

    /// The manual entry button was pressed.
    case manualEntryPressed
}
