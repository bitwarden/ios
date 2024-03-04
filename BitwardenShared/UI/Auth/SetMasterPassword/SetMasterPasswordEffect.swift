// MARK: - SetMasterPasswordEffect

/// Effects that can be processed by a `SetMasterPasswordProcessor`.
///
enum SetMasterPasswordEffect: Equatable {
    /// The set master password view appeared on screen.
    case appeared

    /// The cancel button was pressed.
    case cancelPressed

    /// The submit button was pressed.
    case submitPressed
}
