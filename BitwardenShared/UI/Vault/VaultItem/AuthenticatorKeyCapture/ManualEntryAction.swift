// MARK: - ManualEntryAction

/// Actions that can be processed by a `ScanCodeProcessor`.
///
enum ManualEntryAction: Equatable {
    /// The Add Key CTA was pressed with a value.
    /// - Parameter code: The code entered by the user.
    ///
    case addPressed(code: String)

    /// The user updated the entered key
    /// - Parameter `String`: The code entered by the user.
    ///
    case authenticatorKeyChanged(String)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The scan code button was pressed.
    case scanCodePressed
}
