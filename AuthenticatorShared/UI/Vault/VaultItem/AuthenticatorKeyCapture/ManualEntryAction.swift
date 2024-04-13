// MARK: - ManualEntryAction

/// Actions that can be processed by a `ScanCodeProcessor`.
///
enum ManualEntryAction: Equatable {
    /// The Add TOTP button was pressed.
    ///
    /// - Parameters:
    ///   - code: The code entered by the user.
    ///   - name: The name of the item given by the user
    ///
    case addPressed(code: String, name: String)

    /// The user updated the entered key
    /// - Parameter `String`: The code entered by the user.
    ///
    case authenticatorKeyChanged(String)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The user updated the entered name
    ///
    case nameChanged(String)
}

// MARK: - ManualEntryEffect

/// Async Effects that can be processed by a `ScanCodeProcessor`.
///
enum ManualEntryEffect {
    /// The scan code button was pressed.
    case scanCodePressed
}
